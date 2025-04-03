//
//  UsageTracker.swift
//  CoreLaunch
//
//  Created on 4/2/25.
//

import Foundation

class UsageTracker {
    // MARK: - Properties
    static let shared = UsageTracker()
    
    private let userDefaults = UserDefaults.standard
    private let usageHistoryKey = "usageHistory"
    private let weeklyUsageKey = "weeklyUsage"
    private let usageGoalKey = "usageGoal"
    
    private var appLaunchTimes: [String: Date] = [:]
    private var pendingAppSession: (appName: String, startTime: Date)?
    private let pendingSessionKey = "pendingAppSession"
    private var currentDayUsage: DailyUsage?
    private var weeklyUsageSummaries: [WeeklyUsageSummary] = []
    private var usageGoal: UsageGoal
    
    // MARK: - Initialization
    private init() {
        // Initialize usageGoal with default value first
        self.usageGoal = UsageGoal()
        
        // Now we can safely use self
        if let savedGoal = loadUsageGoal() {
            self.usageGoal = savedGoal
        } else {
            // Already have default value, just save it
            saveUsageGoal()
        }
        
        // Load today's usage data
        loadCurrentDayUsage()
        
        // Load weekly summaries
        loadWeeklySummaries()
        
        // Load any pending app session
        loadPendingAppSession()
    }
    
    // MARK: - App Usage Tracking Methods
    
    /// Record when an app is launched
    func recordAppLaunch(appName: String) -> Bool {
        // Check if we already have a pending session
        if let pending = pendingAppSession {
            // We have a pending session, don't start a new one yet
            return false
        }
        
        // Store app launch time
        let startTime = Date()
        appLaunchTimes[appName] = startTime
        
        // Store as pending session
        pendingAppSession = (appName: appName, startTime: startTime)
        savePendingAppSession()
        
        // Ensure current day usage exists
        if currentDayUsage == nil {
            currentDayUsage = DailyUsage(date: Date().startOfDay)
        }
        
        // Update app launch count
        if var appStat = currentDayUsage?.appStats[appName] {
            appStat.launchCount += 1
            currentDayUsage?.appStats[appName] = appStat
        } else {
            // First launch of this app today
            let newStat = UsageStats(appName: appName, launchCount: 1)
            currentDayUsage?.appStats[appName] = newStat
        }
        
        // Save updated usage data
        saveCurrentDayUsage()
        return true
    }
    
    /// Record when an app is closed/put in background
    func recordAppClosed(appName: String) -> Bool {
        guard let pending = pendingAppSession, pending.appName == appName else {
            return false // No matching pending session
        }
        
        let launchTime = pending.startTime
        
        // Calculate usage duration
        let now = Date()
        let sessionDuration = now.timeIntervalSince(launchTime)
        
        // Remove from active apps
        appLaunchTimes.removeValue(forKey: appName)
        
        // Clear pending session
        pendingAppSession = nil
        clearPendingAppSession()
        
        // Update app usage time
        if var appStat = currentDayUsage?.appStats[appName] {
            appStat.totalUsageTime += sessionDuration
            currentDayUsage?.appStats[appName] = appStat
            
            // Update total usage time for today
            if let currentTotal = currentDayUsage?.totalUsageTime {
                currentDayUsage?.totalUsageTime = currentTotal + sessionDuration
            }
            
            // Save updated usage data
            saveCurrentDayUsage()
            return true
        }
        
        return false
    }
    
    // MARK: - Storage Methods
    
    private func loadCurrentDayUsage() {
        let today = Date().startOfDay
        
        if let savedUsageData = userDefaults.data(forKey: usageHistoryKey),
           let usageHistory = try? JSONDecoder().decode([DailyUsage].self, from: savedUsageData) {
            
            // Find today's usage if it exists
            if let todayUsage = usageHistory.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
                currentDayUsage = todayUsage
            } else {
                // Create new daily usage for today
                currentDayUsage = DailyUsage(date: today)
            }
        } else {
            // Initialize with empty usage for today
            currentDayUsage = DailyUsage(date: today)
        }
    }
    
    private func saveCurrentDayUsage() {
        guard let currentUsage = currentDayUsage else { return }
        
        if var usageHistory = getUsageHistory() {
            // Remove old entry for today if it exists
            usageHistory.removeAll { Calendar.current.isDate($0.date, inSameDayAs: currentUsage.date) }
            
            // Add updated entry
            usageHistory.append(currentUsage)
            
            // Save updated history
            if let encodedData = try? JSONEncoder().encode(usageHistory) {
                userDefaults.set(encodedData, forKey: usageHistoryKey)
            }
        } else {
            // Create new history with just today's usage
            if let encodedData = try? JSONEncoder().encode([currentUsage]) {
                userDefaults.set(encodedData, forKey: usageHistoryKey)
            }
        }
    }
    
    private func getUsageHistory() -> [DailyUsage]? {
        if let savedData = userDefaults.data(forKey: usageHistoryKey),
           let usageHistory = try? JSONDecoder().decode([DailyUsage].self, from: savedData) {
            return usageHistory
        }
        return nil
    }
    
    private func loadWeeklySummaries() {
        if let savedData = userDefaults.data(forKey: weeklyUsageKey),
           let summaries = try? JSONDecoder().decode([WeeklyUsageSummary].self, from: savedData) {
            weeklyUsageSummaries = summaries
        }
    }
    
    private func saveWeeklySummaries() {
        if let encodedData = try? JSONEncoder().encode(weeklyUsageSummaries) {
            userDefaults.set(encodedData, forKey: weeklyUsageKey)
        }
    }
    
    private func loadUsageGoal() -> UsageGoal? {
        if let savedData = userDefaults.data(forKey: usageGoalKey),
           let goal = try? JSONDecoder().decode(UsageGoal.self, from: savedData) {
            return goal
        }
        return nil
    }
    
    private func saveUsageGoal() {
        if let encodedData = try? JSONEncoder().encode(usageGoal) {
            userDefaults.set(encodedData, forKey: usageGoalKey)
        }
    }
    
    // MARK: - Analysis and Reporting Methods
    
    /// Generate weekly usage summary and compute reduction
    func generateWeeklySummary() {
        guard let usageHistory = getUsageHistory(), !usageHistory.isEmpty else { return }
        
        // Get dates for current week
        let calendar = Calendar.current
        let today = Date()
        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else { return }
        
        // Filter usage data for current week
        let currentWeekUsage = usageHistory.filter { 
            let dayDate = $0.date
            return dayDate >= currentWeekStart && dayDate <= today
        }
        
        guard !currentWeekUsage.isEmpty else { return }
        
        // Calculate total usage time for the week
        let totalUsageTime = currentWeekUsage.reduce(0) { $0 + $1.totalUsageTime }
        
        // Calculate daily average
        let daysCount = Double(currentWeekUsage.count)
        let dailyAverage = totalUsageTime / daysCount
        
        // Find most used app
        var appTotals: [String: TimeInterval] = [:]
        
        for dayUsage in currentWeekUsage {
            for (appName, stats) in dayUsage.appStats {
                appTotals[appName, default: 0] += stats.totalUsageTime
            }
        }
        
        let mostUsedApp = appTotals.max(by: { $0.value < $1.value })?.key ?? "None"
        
        // Calculate reduction percentage compared to previous week
        var reductionPercentage = 0.0
        
        if let lastWeekSummary = weeklyUsageSummaries.last, 
           let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart),
           lastWeekSummary.weekStartDate == lastWeekStart {
            
            let previousTotalUsage = lastWeekSummary.totalUsageTime
            if previousTotalUsage > 0 {
                let reduction = previousTotalUsage - totalUsageTime
                reductionPercentage = (reduction / previousTotalUsage) * 100
            }
        }
        
        // Create and save weekly summary
        let newSummary = WeeklyUsageSummary(
            weekStartDate: currentWeekStart,
            totalUsageTime: totalUsageTime,
            dailyAverageTime: dailyAverage,
            mostUsedApp: mostUsedApp,
            usageReductionPercentage: reductionPercentage
        )
        
        // Add to summaries and save
        weeklyUsageSummaries.append(newSummary)
        saveWeeklySummaries()
    }
    
    /// Get progress towards usage goals
    func getGoalProgress() -> (currentUsage: TimeInterval, limit: TimeInterval, percentOfLimit: Double) {
        // Default to today's total usage
        let currentUsage = currentDayUsage?.totalUsageTime ?? 0
        let limit = usageGoal.dailyUsageLimit
        
        // Calculate percentage of limit used
        let percentOfLimit = limit > 0 ? (currentUsage / limit) * 100 : 0
        
        return (currentUsage, limit, percentOfLimit)
    }
    
    /// Get weekly reduction progress
    func getWeeklyReductionProgress() -> (currentReduction: Double, target: Double, percentOfTarget: Double) {
        let currentReduction = weeklyUsageSummaries.last?.usageReductionPercentage ?? 0
        let target = usageGoal.weeklyReductionTarget * 100 // Convert to percentage
        
        // Calculate progress toward target
        let percentOfTarget = target > 0 ? (currentReduction / target) * 100 : 0
        
        return (currentReduction, target, percentOfTarget)
    }
    
    // MARK: - Goal Management
    
    func updateUsageGoal(dailyLimit: TimeInterval? = nil, 
                          weeklyReduction: Double? = nil,
                          focusApps: [String]? = nil) {
        if let dailyLimit = dailyLimit {
            usageGoal.dailyUsageLimit = dailyLimit
        }
        
        if let weeklyReduction = weeklyReduction {
            usageGoal.weeklyReductionTarget = weeklyReduction
        }
        
        if let focusApps = focusApps {
            usageGoal.focusApps = focusApps
        }
        
        saveUsageGoal()
    }
    
    func getUsageGoal() -> UsageGoal {
        return usageGoal
    }
    
    // MARK: - Pending Session Management
    
    func hasPendingAppSession() -> (hasSession: Bool, appName: String?, startTime: Date?) {
        if let pending = pendingAppSession {
            return (true, pending.appName, pending.startTime)
        }
        return (false, nil, nil)
    }
    
    func cancelPendingAppSession() {
        pendingAppSession = nil
        clearPendingAppSession()
    }
    
    private func savePendingAppSession() {
        guard let pending = pendingAppSession else { return }
        
        let pendingDict: [String: Any] = [
            "appName": pending.appName,
            "startTimeInterval": pending.startTime.timeIntervalSince1970
        ]
        
        userDefaults.set(pendingDict, forKey: pendingSessionKey)
    }
    
    private func loadPendingAppSession() {
        guard let pendingDict = userDefaults.dictionary(forKey: pendingSessionKey) else { return }
        
        if let appName = pendingDict["appName"] as? String,
           let startTimeInterval = pendingDict["startTimeInterval"] as? TimeInterval {
            let startTime = Date(timeIntervalSince1970: startTimeInterval)
            pendingAppSession = (appName: appName, startTime: startTime)
        }
    }
    
    private func clearPendingAppSession() {
        userDefaults.removeObject(forKey: pendingSessionKey)
    }
    
    // MARK: - Historical Data Methods
    
    func getUsageHistoryForDate(_ date: Date) -> DailyUsage? {
        if let history = getUsageHistory() {
            let calendar = Calendar.current
            return history.first { calendar.isDate($0.date, inSameDayAs: date) }
        }
        return nil
    }
    
    func getUsageHistoryForDateRange(start: Date, end: Date) -> [DailyUsage] {
        guard let history = getUsageHistory() else { return [] }
        
        let calendar = Calendar.current
        return history.filter {
            let date = $0.date
            return (date >= start && date <= end) || calendar.isDate(date, inSameDayAs: start) || calendar.isDate(date, inSameDayAs: end)
        }
    }
    
    func getDatesWithUsageData() -> [Date] {
        guard let history = getUsageHistory() else { return [] }
        return history.map { $0.date }
    }
    
    func getUsageTrends(for period: Int) -> [(date: Date, usage: TimeInterval)] {
        let now = Date()
        let calendar = Calendar.current
        
        guard let startDate = calendar.date(byAdding: .day, value: -period, to: now) else {
            return []
        }
        
        let usageData = getUsageHistoryForDateRange(start: startDate, end: now)
        
        // Create a full range of dates
        var result: [(date: Date, usage: TimeInterval)] = []
        for dayOffset in 0...period {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) {
                let dateUsage = usageData.first { calendar.isDate($0.date, inSameDayAs: date) }
                let usage = dateUsage?.totalUsageTime ?? 0
                result.append((date: date, usage: usage))
            }
        }
        
        // Sort by date (oldest to newest)
        return result.sorted { $0.date < $1.date }
    }
    
    // MARK: - Data Access Methods
    
    /// Get today's usage statistics
    func getTodayUsage() -> DailyUsage? {
        return currentDayUsage
    }
    
    /// Get all stored weekly summaries
    func getWeeklySummaries() -> [WeeklyUsageSummary] {
        return weeklyUsageSummaries
    }
    
    /// Get usage history for the past N days
    func getUsageHistory(days: Int) -> [DailyUsage] {
        guard let history = getUsageHistory() else { return [] }
        
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: today) ?? today
        
        return history.filter { $0.date >= startDate }
    }
    
    /// Check if user has exceeded daily limit
    func hasExceededDailyLimit() -> Bool {
        let currentUsage = currentDayUsage?.totalUsageTime ?? 0
        return currentUsage > usageGoal.dailyUsageLimit
    }
}

// MARK: - Date Extension
extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
}
