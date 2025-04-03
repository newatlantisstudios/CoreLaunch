//
//  UsageStats.swift
//  CoreLaunch
//
//  Created on 4/2/25.
//

import Foundation

struct UsageStats: Codable {
    var appName: String
    var launchCount: Int
    var totalUsageTime: TimeInterval
    var date: Date
    
    init(appName: String, launchCount: Int = 0, totalUsageTime: TimeInterval = 0, date: Date = Date()) {
        self.appName = appName
        self.launchCount = launchCount
        self.totalUsageTime = totalUsageTime
        self.date = date
    }
}

struct DailyUsage: Codable {
    var date: Date
    var totalUsageTime: TimeInterval
    var appStats: [String: UsageStats]
    
    init(date: Date = Date(), totalUsageTime: TimeInterval = 0, appStats: [String: UsageStats] = [:]) {
        self.date = date
        self.totalUsageTime = totalUsageTime
        self.appStats = appStats
    }
}

struct WeeklyUsageSummary: Codable {
    var weekStartDate: Date
    var totalUsageTime: TimeInterval
    var dailyAverageTime: TimeInterval
    var mostUsedApp: String
    var usageReductionPercentage: Double // Compared to previous week
    
    init(weekStartDate: Date, totalUsageTime: TimeInterval, dailyAverageTime: TimeInterval, 
         mostUsedApp: String, usageReductionPercentage: Double = 0.0) {
        self.weekStartDate = weekStartDate
        self.totalUsageTime = totalUsageTime
        self.dailyAverageTime = dailyAverageTime
        self.mostUsedApp = mostUsedApp
        self.usageReductionPercentage = usageReductionPercentage
    }
}

struct UsageGoal: Codable {
    var dailyUsageLimit: TimeInterval
    var weeklyReductionTarget: Double // Percentage reduction goal
    var focusApps: [String] // Apps to limit usage of
    
    init(dailyUsageLimit: TimeInterval = 3600, weeklyReductionTarget: Double = 0.05, focusApps: [String] = []) {
        self.dailyUsageLimit = dailyUsageLimit
        self.weeklyReductionTarget = weeklyReductionTarget
        self.focusApps = focusApps
    }
}
