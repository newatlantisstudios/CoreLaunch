//
//  HomeViewController+Achievements.swift
//  CoreLaunch
//
//  Created for Positive Reinforcement System
//

import UIKit

// MARK: - Achievement Integration
extension HomeViewController {
    
    func setupAchievementsButton() {
        // Achievements button
        achievementsButton.setImage(UIImage(systemName: "trophy"), for: .normal)
        achievementsButton.addTarget(self, action: #selector(achievementsButtonTapped), for: .touchUpInside)
        achievementsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(achievementsButton)
        
        NSLayoutConstraint.activate([
            achievementsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            achievementsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            achievementsButton.widthAnchor.constraint(equalToConstant: 44),
            achievementsButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Set color based on theme
        let theme = ThemeManager.shared.currentTheme
        if theme.name == "Dark" || theme.name == "Midnight" || 
           (theme.name == "Auto Light and Dark" && traitCollection.userInterfaceStyle == .dark) {
            achievementsButton.tintColor = .white
        } else if theme.name == "Monochrome" {
            achievementsButton.tintColor = .black
        } else {
            achievementsButton.tintColor = theme.accentColor
        }
        
        // Check for new achievements and update UI if needed
        UsageTracker.shared.showAchievementNotificationIfNeeded(button: achievementsButton)
    }
    
    func updateAchievementNotification() {
        UsageTracker.shared.showAchievementNotificationIfNeeded(button: achievementsButton)
    }
    
    @objc func achievementsButtonTapped() {
        let achievementsVC = UsageTracker.shared.getAchievementsDashboard()
        let navController = UINavigationController(rootViewController: achievementsVC)
        present(navController, animated: true)
    }
    
    
    func checkAchievementsAfterAppUsage() {
        UsageTracker.shared.checkDailyGoalAchievements()
        UsageTracker.shared.updateStreaksBasedOnDailyUsage()
    }
}
