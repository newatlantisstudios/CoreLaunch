//
//  UsageTracker+Reinforcement.swift
//  CoreLaunch
//
//  Created for Positive Reinforcement System
//

import Foundation
import UIKit

// Extension to the UsageTracker to add positive reinforcement functionality
extension UsageTracker {
    
    // MARK: - Goal Achievement Methods
    
    /// Check milestones for daily usage goal achievements
    func checkDailyGoalAchievements() {
        let (currentUsage, limit, _) = getGoalProgress()
        
        // Check if under daily limit
        AchievementManager.shared.checkDailyGoalAchievements(
            usageTime: currentUsage,
            limit: limit
        )
        
        // Log if decreased from yesterday
        checkDailyImprovementFromYesterday()
    }
    
    /// Check if today's usage is better than yesterday's
    private func checkDailyImprovementFromYesterday() {
        // Get today's usage
        let todayUsage = getTodayUsage()?.totalUsageTime ?? 0
        
        // Get yesterday's date
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return }
        
        // Get yesterday's usage
        if let yesterdayStats = getUsageHistoryForDate(yesterday) {
            let yesterdayUsage = yesterdayStats.totalUsageTime
            
            // Calculate percentage improvement
            if yesterdayUsage > 0 && todayUsage < yesterdayUsage {
                let reduction = yesterdayUsage - todayUsage
                let percentReduction = (reduction / yesterdayUsage) * 100
                
                // Only celebrate significant improvements (>5%)
                if percentReduction >= 5 {
                    // Find current view controller to show celebration
                    if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let viewController = windowScene.windows.first?.rootViewController {
                        CelebrationManager.shared.showReductionCongratulations(
                            reduction: percentReduction,
                            context: viewController
                        )
                    }
                }
            }
        }
    }
    
    /// Check milestones for weekly reduction achievements
    func checkWeeklyReductionAchievements() {
        let (currentReduction, target, _) = getWeeklyReductionProgress()
        
        // Check if target met
        AchievementManager.shared.checkWeeklyReductionAchievements(
            currentReduction: currentReduction,
            target: target
        )
        
        // Show celebration for positive reduction
        if currentReduction > 0 {
            // Find current view controller to show celebration
            if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let viewController = windowScene.windows.first?.rootViewController {
                CelebrationManager.shared.celebrateWeeklySummary(
                    reduction: currentReduction,
                    context: viewController
                )
            }
        }
    }
    
    /// Check achievements for focus session completion
    func checkFocusSessionAchievements(completed: Bool, duration: TimeInterval) {
        AchievementManager.shared.checkFocusSessionAchievements(
            sessionCompleted: completed,
            sessionDuration: duration
        )
    }
    
    // MARK: - Enhanced Generation Methods
    
    /// Enhanced weekly summary with celebration
    func generateWeeklySummaryWithCelebration() {
        // Generate regular summary first
        generateWeeklySummary()
        
        // Check for achievements
        checkWeeklyReductionAchievements()
    }
    
    // MARK: - Streaks and Special Achievements
    
    /// Reset streaks when exceeding limits
    func updateStreaksBasedOnDailyUsage() {
        let hasExceeded = hasExceededDailyLimit()
        
        if !hasExceeded {
            // Update streak for staying under limit
            AchievementManager.shared.updateStreak(type: .belowDailyLimit)
        } else {
            // Break streak for exceeding limit
            AchievementManager.shared.breakStreak(type: .belowDailyLimit)
        }
    }
    
    /// Check for special milestone achievements
    func checkForSpecialMilestones() {
        // Check for consecutive days under limit
        let underLimitStreak = AchievementManager.shared.getStreak(type: .belowDailyLimit)
        
        if underLimitStreak.currentStreak >= 30 {
            // Special milestone for one month of meeting daily goal
            let achievement = Achievement(
                title: "Digital Balance Master",
                description: "You've maintained healthy screen time habits for a full month!",
                category: .specialMilestone,
                iconName: "crown.fill",
                level: 3
            )
            AchievementManager.shared.awardAchievement(achievement: achievement)
        }
        
        // Check for consecutive weeks of reduction
        let weeklyReductionStreak = AchievementManager.shared.getStreak(type: .weeklyReduction)
        
        if weeklyReductionStreak.currentStreak >= 4 {
            // Special milestone for one month of weekly reductions
            let achievement = Achievement(
                title: "Consistent Reducer",
                description: "You've reduced your screen time every week for a month!",
                category: .specialMilestone,
                iconName: "chart.bar.fill",
                level: 3
            )
            AchievementManager.shared.awardAchievement(achievement: achievement)
        }
    }
    
    // MARK: - Integration with Existing Methods
    
    /// Enhanced record app closed with reinforcement
    @discardableResult
    func recordAppClosedWithReinforcement(appName: String) -> Bool {
        let success = recordAppClosed(appName: appName)
        
        if success {
            // Check daily achievements after usage update
            checkDailyGoalAchievements()
            updateStreaksBasedOnDailyUsage()
            
            // Generate weekly summary periodically
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: Date())
            
            // On Sunday (weekday = 1), generate weekly summary with celebration
            if weekday == 1 {
                generateWeeklySummaryWithCelebration()
                checkForSpecialMilestones()
            }
        }
        
        return success
    }
    
    // MARK: - Helpers for Celebration Triggers
    
    /// Get achievements dashboard view controller
    func getAchievementsDashboard() -> UIViewController {
        return AchievementsViewController()
    }
    
    /// Check for and show new achievements notification
    func checkForNewAchievements() -> Bool {
        return AchievementManager.shared.hasNewAchievements()
    }
    
    /// Update UI to show achievement notification indicator
    func showAchievementNotificationIfNeeded(button: UIButton) {
        if checkForNewAchievements() {
            // Add notification badge to button
            let badgeTag = 999
            
            // Remove any existing badge
            if let existingBadge = button.viewWithTag(badgeTag) {
                existingBadge.removeFromSuperview()
            }
            
            // Create badge
            let badge = UIView()
            badge.tag = badgeTag
            badge.backgroundColor = .systemRed
            badge.layer.cornerRadius = 5
            badge.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(badge)
            
            NSLayoutConstraint.activate([
                badge.widthAnchor.constraint(equalToConstant: 10),
                badge.heightAnchor.constraint(equalToConstant: 10),
                badge.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                badge.topAnchor.constraint(equalTo: button.topAnchor)
            ])
        } else {
            // Remove badge if no new achievements
            if let existingBadge = button.viewWithTag(999) {
                existingBadge.removeFromSuperview()
            }
        }
    }
}
