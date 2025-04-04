//
//  Achievement.swift
//  CoreLaunch
//
//  Created for Positive Reinforcement System
//

import Foundation
import UIKit

// Achievement categories
enum AchievementCategory: String, Codable {
    case dailyGoal = "Daily Goal"
    case weeklyReduction = "Weekly Reduction"
    case streaks = "Streaks"
    case specialMilestone = "Special Milestone"
    case focusSession = "Focus Session"
}

// Achievement model
struct Achievement: Codable, Identifiable {
    var id: String
    var title: String
    var description: String
    var category: AchievementCategory
    var dateEarned: Date
    var iconName: String
    var level: Int // 1-3 for bronze, silver, gold or different tiers
    var isNew: Bool = true
    
    // Additional properties to support display
    var progress: Double? // Optional progress toward achievement (0.0-1.0)
    
    init(id: String = UUID().uuidString, 
         title: String, 
         description: String, 
         category: AchievementCategory,
         dateEarned: Date = Date(),
         iconName: String, 
         level: Int = 1, 
         isNew: Bool = true,
         progress: Double? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.dateEarned = dateEarned
        self.iconName = iconName
        self.level = level
        self.isNew = isNew
        self.progress = progress
    }
}

// Streak tracking model
struct StreakRecord: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastRecordedDate: Date?
    var streakType: StreakType
    
    enum StreakType: String, Codable {
        case belowDailyLimit = "Below Daily Limit"
        case weeklyReduction = "Weekly Reduction"
        case focusSession = "Focus Session Completed"
    }
    
    init(currentStreak: Int = 0, longestStreak: Int = 0, lastRecordedDate: Date? = nil, streakType: StreakType) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastRecordedDate = lastRecordedDate
        self.streakType = streakType
    }
    
    mutating func incrementStreak(date: Date = Date()) {
        currentStreak += 1
        lastRecordedDate = date
        
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }
    
    mutating func breakStreak() {
        currentStreak = 0
        lastRecordedDate = nil
    }
    
    func isConsecutiveWith(date: Date) -> Bool {
        guard let lastDate = lastRecordedDate else { return true }
        
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        
        return calendar.isDate(lastDate, inSameDayAs: yesterday)
    }
}

// Achievement manager
class AchievementManager {
    static let shared = AchievementManager()
    
    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "userAchievements"
    private let streaksKey = "userStreaks"
    
    private(set) var achievements: [Achievement] = []
    private(set) var streaks: [StreakRecord.StreakType: StreakRecord] = [:]
    
    private init() {
        loadAchievements()
        loadStreaks()
    }
    
    // MARK: - Achievement Management
    
    func awardAchievement(achievement: Achievement) {
        // Check if this achievement already exists
        if let index = achievements.firstIndex(where: { $0.id == achievement.id }) {
            achievements[index] = achievement
        } else {
            achievements.append(achievement)
        }
        
        saveAchievements()
        
        // Post notification for the UI to update
        NotificationCenter.default.post(
            name: NSNotification.Name("NewAchievementEarned"),
            object: nil,
            userInfo: ["achievement": achievement]
        )
    }
    
    func markAchievementAsViewed(_ achievementId: String) {
        if let index = achievements.firstIndex(where: { $0.id == achievementId }) {
            achievements[index].isNew = false
            saveAchievements()
        }
    }
    
    func hasNewAchievements() -> Bool {
        return achievements.contains(where: { $0.isNew })
    }
    
    func getNewAchievements() -> [Achievement] {
        return achievements.filter { $0.isNew }
    }
    
    func getAchievementsByCategory(_ category: AchievementCategory) -> [Achievement] {
        return achievements.filter { $0.category == category }
            .sorted(by: { $0.dateEarned > $1.dateEarned })
    }
    
    // MARK: - Streak Management
    
    func getStreak(type: StreakRecord.StreakType) -> StreakRecord {
        return streaks[type] ?? StreakRecord(streakType: type)
    }
    
    func updateStreak(type: StreakRecord.StreakType, date: Date = Date()) {
        var streak = getStreak(type: type)
        
        if streak.isConsecutiveWith(date: date) {
            streak.incrementStreak(date: date)
            
            // Check for streak-based achievements
            checkStreakAchievements(type: type, value: streak.currentStreak)
        } else if !Calendar.current.isDateInToday(streak.lastRecordedDate ?? Date()) {
            // Only break the streak if it's not already been updated today
            streak.breakStreak()
        }
        
        streaks[type] = streak
        saveStreaks()
    }
    
    func breakStreak(type: StreakRecord.StreakType) {
        var streak = getStreak(type: type)
        streak.breakStreak()
        streaks[type] = streak
        saveStreaks()
    }
    
    // MARK: - Achievement Checks
    
    func checkDailyGoalAchievements(usageTime: TimeInterval, limit: TimeInterval) {
        let percentUsed = (usageTime / limit) * 100
        
        if usageTime <= limit {
            // Under limit achievement
            let achievement = Achievement(
                title: "Daily Goal Met",
                description: "You stayed under your daily screen time goal",
                category: .dailyGoal,
                iconName: "checkmark.circle.fill",
                level: 1
            )
            awardAchievement(achievement: achievement)
            
            // Check for specific thresholds
            if percentUsed <= 50 {
                let achievement = Achievement(
                    title: "Half and Half",
                    description: "Used only 50% of your daily screen time allowance",
                    category: .dailyGoal,
                    iconName: "hourglass.bottomhalf.filled",
                    level: 2
                )
                awardAchievement(achievement: achievement)
            }
            
            // Update streak
            updateStreak(type: .belowDailyLimit)
        } else {
            // Break the streak if exceeded
            breakStreak(type: .belowDailyLimit)
        }
    }
    
    func checkWeeklyReductionAchievements(currentReduction: Double, target: Double) {
        if currentReduction >= target {
            // Met target
            let achievement = Achievement(
                title: "Weekly Goal Achieved",
                description: "You reduced your screen time by \(String(format: "%.1f", currentReduction))% this week",
                category: .weeklyReduction,
                iconName: "chart.line.downtrend.xyaxis",
                level: 1
            )
            awardAchievement(achievement: achievement)
            
            // Exceeded target
            if currentReduction >= (target * 2) {
                let achievement = Achievement(
                    title: "Double Reducer",
                    description: "You exceeded your weekly reduction goal by 2X or more",
                    category: .weeklyReduction,
                    iconName: "arrow.down.right.circle.fill",
                    level: 2
                )
                awardAchievement(achievement: achievement)
            }
            
            // Update streak
            updateStreak(type: .weeklyReduction)
        } else {
            // Break the streak if not met
            breakStreak(type: .weeklyReduction)
        }
    }
    
    func checkFocusSessionAchievements(sessionCompleted: Bool, sessionDuration: TimeInterval) {
        if sessionCompleted {
            let achievement = Achievement(
                title: "Focus Master",
                description: "You completed a focus session",
                category: .focusSession,
                iconName: "timer",
                level: 1
            )
            awardAchievement(achievement: achievement)
            
            if sessionDuration >= 3600 { // 1 hour
                let achievement = Achievement(
                    title: "Extended Focus",
                    description: "You completed a focus session lasting 1 hour or more",
                    category: .focusSession,
                    iconName: "timer.circle.fill",
                    level: 2
                )
                awardAchievement(achievement: achievement)
            }
            
            // Update streak
            updateStreak(type: .focusSession)
        } else {
            // Break the streak if session not completed
            breakStreak(type: .focusSession)
        }
    }
    
    private func checkStreakAchievements(type: StreakRecord.StreakType, value: Int) {
        var title = ""
        var description = ""
        var iconName = ""
        
        switch type {
        case .belowDailyLimit:
            title = "Daily Goal Streak"
            description = "\(value) days in a row below your daily limit"
            iconName = "flame.fill"
        case .weeklyReduction:
            title = "Weekly Reduction Streak"
            description = "\(value) weeks in a row meeting your reduction goal"
            iconName = "calendar.badge.minus"
        case .focusSession:
            title = "Focus Session Streak"
            description = "\(value) days in a row completing focus sessions"
            iconName = "timer.square"
        }
        
        // Award achievements at certain streak milestones
        if value == 3 {
            let achievement = Achievement(
                title: title,
                description: description,
                category: .streaks,
                iconName: iconName,
                level: 1
            )
            awardAchievement(achievement: achievement)
        } else if value == 7 {
            let achievement = Achievement(
                title: title + " - One Week",
                description: description,
                category: .streaks,
                iconName: iconName,
                level: 2
            )
            awardAchievement(achievement: achievement)
        } else if value == 30 {
            let achievement = Achievement(
                title: title + " - One Month",
                description: description,
                category: .streaks,
                iconName: iconName,
                level: 3
            )
            awardAchievement(achievement: achievement)
        }
    }
    
    // MARK: - Storage
    
    private func loadAchievements() {
        if let data = userDefaults.data(forKey: achievementsKey),
           let loadedAchievements = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = loadedAchievements
        }
    }
    
    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            userDefaults.set(data, forKey: achievementsKey)
        }
    }
    
    private func loadStreaks() {
        if let data = userDefaults.data(forKey: streaksKey),
           let loadedStreaks = try? JSONDecoder().decode([String: StreakRecord].self, from: data) {
            // Convert string keys back to enum type
            for (key, value) in loadedStreaks {
                if let enumKey = StreakRecord.StreakType(rawValue: key) {
                    streaks[enumKey] = value
                }
            }
        }
    }
    
    private func saveStreaks() {
        // Convert enum keys to strings for storage
        var storedStreaks: [String: StreakRecord] = [:]
        for (key, value) in streaks {
            storedStreaks[key.rawValue] = value
        }
        
        if let data = try? JSONEncoder().encode(storedStreaks) {
            userDefaults.set(data, forKey: streaksKey)
        }
    }
}
