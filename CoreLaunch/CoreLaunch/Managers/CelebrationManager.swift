//
//  CelebrationManager.swift
//  CoreLaunch
//
//  Created for Positive Reinforcement System
//

import UIKit

class CelebrationManager {
    static let shared = CelebrationManager()
    
    // MARK: - Properties
    
    private var windowScene: UIWindowScene? {
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first as? UIWindowScene
    }
    
    private let celebrationQueue = DispatchQueue(label: "com.corelaunch.celebration")
    private var pendingCelebrations: [Achievement] = []
    private var isShowingCelebration = false
    
    private var congratulatoryMessages: [String] = [
        "Great job on improving your digital habits!",
        "Your efforts to reduce screen time are paying off!",
        "Keep up the good work on your digital wellbeing journey!",
        "Fantastic progress on developing healthier tech habits!",
        "You're taking great steps toward digital balance!",
        "Your commitment to mindful tech use is impressive!",
        "You're making real progress on your screen time goals!",
        "Congratulations on prioritizing your digital health!",
        "Your consistency is building better digital habits!",
        "You're mastering the art of tech-life balance!"
    ]
    
    // MARK: - Initialization
    
    private init() {
        // Listen for new achievement notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(newAchievementEarned(_:)),
            name: NSNotification.Name("NewAchievementEarned"),
            object: nil
        )
        
        // Listen for celebration dismissed notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(celebrationDismissed),
            name: NSNotification.Name("AchievementCelebrationDismissed"),
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /// Show a celebration for a milestone achievement
    func celebrateAchievement(_ achievement: Achievement) {
        celebrationQueue.async {
            // Add to queue
            self.pendingCelebrations.append(achievement)
            
            // Show if not already showing one
            if !self.isShowingCelebration {
                self.showNextCelebration()
            }
        }
    }
    
    /// Show congratulatory message for reduced screen time
    func showReductionCongratulations(reduction: Double, context: UIViewController?) {
        guard let context = context else { return }
        
        let message = getRandomCongratulations()
        let detailMessage = getReductionMessage(for: reduction)
        
        let alert = UIAlertController(
            title: "Great Progress!",
            message: "\(message)\n\n\(detailMessage)",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "Thanks!", style: .default)
        let shareAction = UIAlertAction(title: "Share", style: .default) { _ in
            self.shareProgress(reduction: reduction, context: context)
        }
        
        alert.addAction(okAction)
        alert.addAction(shareAction)
        
        DispatchQueue.main.async {
            context.present(alert, animated: true)
        }
    }
    
    /// Show weekly summary celebration
    func celebrateWeeklySummary(reduction: Double, context: UIViewController?) {
        guard let context = context, reduction > 0 else { return }
        
        // Create a visual celebration for weekly achievements
        let message = "You reduced your screen time by \(String(format: "%.1f", reduction))% this week! 🎉"
        
        let alert = UIAlertController(
            title: "Weekly Win!",
            message: message,
            preferredStyle: .alert
        )
        
        let viewStatsAction = UIAlertAction(title: "View Stats", style: .default) { _ in
            // Navigate to stats view
            let statsVC = UsageStatsViewController()
            let navController = UINavigationController(rootViewController: statsVC)
            context.present(navController, animated: true)
        }
        
        let closeAction = UIAlertAction(title: "Great!", style: .cancel)
        
        alert.addAction(viewStatsAction)
        alert.addAction(closeAction)
        
        DispatchQueue.main.async {
            context.present(alert, animated: true)
        }
    }
    
    // MARK: - Private Methods
    
    private func showNextCelebration() {
        celebrationQueue.async {
            guard !self.pendingCelebrations.isEmpty else {
                self.isShowingCelebration = false
                return
            }
            
            self.isShowingCelebration = true
            let achievement = self.pendingCelebrations.removeFirst()
            
            DispatchQueue.main.async {
                self.displayCelebrationView(for: achievement)
            }
        }
    }
    
    private func displayCelebrationView(for achievement: Achievement) {
        guard let windowScene = self.windowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        let celebrationView = AchievementCelebrationView(achievement: achievement, frame: window.bounds)
        celebrationView.alpha = 0
        
        // Add to window
        window.addSubview(celebrationView)
        
        // Animate in
        UIView.animate(withDuration: 0.3) {
            celebrationView.alpha = 1
        }
        
        // Play sound
        playCelebrationSound()
    }
    
    private func playCelebrationSound() {
        // Use AudioServicesPlaySystemSound or AVAudioPlayer to play a celebration sound
        // This would be implemented in a real app but is omitted here for brevity
    }
    
    private func getRandomCongratulations() -> String {
        return congratulatoryMessages.randomElement() ?? "Great job!"
    }
    
    private func getReductionMessage(for reduction: Double) -> String {
        if reduction >= 30 {
            return "You've reduced your screen time by an impressive \(String(format: "%.1f", reduction))%!"
        } else if reduction >= 15 {
            return "You've reduced your screen time by a solid \(String(format: "%.1f", reduction))%!"
        } else {
            return "You've reduced your screen time by \(String(format: "%.1f", reduction))%!"
        }
    }
    
    private func shareProgress(reduction: Double, context: UIViewController) {
        let message = "I reduced my screen time by \(String(format: "%.1f", reduction))% using CoreLaunch!"
        
        let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        
        DispatchQueue.main.async {
            context.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func newAchievementEarned(_ notification: Notification) {
        if let achievement = notification.userInfo?["achievement"] as? Achievement {
            celebrateAchievement(achievement)
        }
    }
    
    @objc private func celebrationDismissed() {
        // Show the next celebration if there are more
        celebrationQueue.async {
            self.showNextCelebration()
        }
    }
}
