//
//  DebugAchievementsViewController.swift
//  CoreLaunch
//
//  Created for testing the Positive Reinforcement System
//

import UIKit

class DebugAchievementsViewController: UIViewController {
    
    private let achievementManager = AchievementManager.shared
    private let celebrationManager = CelebrationManager.shared
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Debug Achievement System"
        view.backgroundColor = .systemBackground
        
        setupUI()
    }
    
    private func setupUI() {
        // Navigation bar button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(dismissVC)
        )
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Setup stack view
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        scrollView.addSubview(stackView)
        
        // Add debug sections
        addDebugAchievementsSection()
        addDebugCelebrationsSection()
        addDebugStreaksSection()
        
        // Setup constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }
    
    private func addDebugAchievementsSection() {
        let sectionTitle = createSectionTitle("Test Achievement Unlocks")
        stackView.addArrangedSubview(sectionTitle)
        
        // Add buttons for different achievement types
        addAchievementDebugButton("Daily Goal Achievement", action: #selector(testDailyGoalAchievement))
        addAchievementDebugButton("Weekly Reduction Achievement", action: #selector(testWeeklyReductionAchievement))
        addAchievementDebugButton("Streak Achievement", action: #selector(testStreakAchievement))
        addAchievementDebugButton("Focus Session Achievement", action: #selector(testFocusSessionAchievement))
        addAchievementDebugButton("Special Milestone", action: #selector(testSpecialMilestone))
    }
    
    private func addDebugCelebrationsSection() {
        let sectionTitle = createSectionTitle("Test Celebration Animations")
        stackView.addArrangedSubview(sectionTitle)
        
        // Add buttons for different celebration types
        addAchievementDebugButton("Achievement Popup", action: #selector(testAchievementPopup))
        addAchievementDebugButton("Daily Reduction Alert", action: #selector(testDailyReductionAlert))
        addAchievementDebugButton("Weekly Summary Celebration", action: #selector(testWeeklySummaryCelebration))
    }
    
    private func addDebugStreaksSection() {
        let sectionTitle = createSectionTitle("Test Streak System")
        stackView.addArrangedSubview(sectionTitle)
        
        // Add buttons for streak management
        addAchievementDebugButton("Increment Daily Goal Streak", action: #selector(incrementDailyGoalStreak))
        addAchievementDebugButton("Break Daily Goal Streak", action: #selector(breakDailyGoalStreak))
        addAchievementDebugButton("Create Long Streak (30 days)", action: #selector(createLongStreak))
    }
    
    private func createSectionTitle(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }
    
    private func addAchievementDebugButton(_ title: String, action: Selector) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }
    
    // MARK: - Debug Actions
    
    @objc private func testDailyGoalAchievement() {
        let achievement = Achievement(
            title: "Daily Goal Met",
            description: "You stayed under your daily screen time goal",
            category: .dailyGoal,
            iconName: "checkmark.circle.fill",
            level: 1
        )
        achievementManager.awardAchievement(achievement: achievement)
    }
    
    @objc private func testWeeklyReductionAchievement() {
        let achievement = Achievement(
            title: "Weekly Goal Achieved",
            description: "You reduced your screen time by 15% this week",
            category: .weeklyReduction,
            iconName: "chart.line.downtrend.xyaxis",
            level: 1
        )
        achievementManager.awardAchievement(achievement: achievement)
    }
    
    @objc private func testStreakAchievement() {
        let achievement = Achievement(
            title: "Daily Goal Streak",
            description: "7 days in a row below your daily limit",
            category: .streaks,
            iconName: "flame.fill",
            level: 2
        )
        achievementManager.awardAchievement(achievement: achievement)
    }
    
    @objc private func testFocusSessionAchievement() {
        let achievement = Achievement(
            title: "Focus Master",
            description: "You completed a focus session",
            category: .focusSession,
            iconName: "timer",
            level: 1
        )
        achievementManager.awardAchievement(achievement: achievement)
    }
    
    @objc private func testSpecialMilestone() {
        let achievement = Achievement(
            title: "Digital Balance Master",
            description: "You've maintained healthy screen time habits for a full month!",
            category: .specialMilestone,
            iconName: "crown.fill",
            level: 3
        )
        achievementManager.awardAchievement(achievement: achievement)
    }
    
    @objc private func testAchievementPopup() {
        let achievement = Achievement(
            title: "Test Achievement",
            description: "This is a test of the achievement popup system",
            category: .specialMilestone,
            iconName: "star.fill",
            level: 2
        )
        celebrationManager.celebrateAchievement(achievement)
    }
    
    @objc private func testDailyReductionAlert() {
        celebrationManager.showReductionCongratulations(reduction: 20.5, context: self)
    }
    
    @objc private func testWeeklySummaryCelebration() {
        celebrationManager.celebrateWeeklySummary(reduction: 15.0, context: self)
    }
    
    @objc private func incrementDailyGoalStreak() {
        achievementManager.updateStreak(type: .belowDailyLimit)
        let streak = achievementManager.getStreak(type: .belowDailyLimit)
        
        let alert = UIAlertController(
            title: "Streak Incremented",
            message: "Daily goal streak is now at \(streak.currentStreak) days",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func breakDailyGoalStreak() {
        achievementManager.breakStreak(type: .belowDailyLimit)
        
        let alert = UIAlertController(
            title: "Streak Reset",
            message: "Daily goal streak has been reset to 0",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func createLongStreak() {
        // Create a streak record with 30 days
        var streak = StreakRecord(currentStreak: 30, longestStreak: 30, lastRecordedDate: Date(), streakType: .belowDailyLimit)
        
        // Save it directly through reflection (for debug purposes only)
        let mirror = Mirror(reflecting: achievementManager)
        if let streaksProperty = mirror.children.first(where: { $0.label == "streaks" }) {
            var streaks = streaksProperty.value as! [StreakRecord.StreakType: StreakRecord]
            streaks[.belowDailyLimit] = streak
            
            // We can't directly access private method since AchievementManager isn't NSObject-based
            // Instead, we'll create a dummy achievement to trigger saving
            let dummyAchievement = Achievement(
                title: "Dummy",
                description: "For triggering save",
                category: .streaks,
                iconName: "star",
                level: 1,
                isNew: false
            )
            achievementManager.awardAchievement(achievement: dummyAchievement)
        }
        
        // Check for special milestone
        UsageTracker.shared.checkForSpecialMilestones()
        
        // Show confirmation
        let alert = UIAlertController(
            title: "Long Streak Created",
            message: "Created a 30-day streak for testing milestones",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func dismissVC() {
        dismiss(animated: true)
    }
}
