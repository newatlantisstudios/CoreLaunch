//
//  AchievementViews.swift
//  CoreLaunch
//
//  Created for Positive Reinforcement System
//

import UIKit

// MARK: - Achievement Card UI
class AchievementCardView: UIView {
    
    // MARK: - Properties
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let dateLabel = UILabel()
    private let levelBadge = UIView()
    private let newBadge = UIView()
    private let badgeLabel = UILabel()
    
    private var achievement: Achievement!
    
    // MARK: - Initialization
    
    init(achievement: Achievement, frame: CGRect = .zero) {
        super.init(frame: frame)
        self.achievement = achievement
        setupView()
        configure(with: achievement)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        
        // Icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue
        addSubview(iconImageView)
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        addSubview(titleLabel)
        
        // Description
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2
        addSubview(descriptionLabel)
        
        // Date
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        dateLabel.textColor = .secondaryLabel
        dateLabel.textAlignment = .left
        addSubview(dateLabel)
        
        // Level badge
        levelBadge.translatesAutoresizingMaskIntoConstraints = false
        levelBadge.layer.cornerRadius = 10
        addSubview(levelBadge)
        
        // New badge
        newBadge.translatesAutoresizingMaskIntoConstraints = false
        newBadge.backgroundColor = .systemGreen
        newBadge.layer.cornerRadius = 8
        newBadge.isHidden = true
        addSubview(newBadge)
        
        // Badge label
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.text = "NEW"
        badgeLabel.textAlignment = .center
        newBadge.addSubview(badgeLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: levelBadge.leadingAnchor, constant: -8),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: 4),
            dateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            dateLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            dateLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            levelBadge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            levelBadge.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            levelBadge.widthAnchor.constraint(equalToConstant: 20),
            levelBadge.heightAnchor.constraint(equalToConstant: 20),
            
            newBadge.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            newBadge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            newBadge.widthAnchor.constraint(equalToConstant: 40),
            newBadge.heightAnchor.constraint(equalToConstant: 16),
            
            badgeLabel.centerXAnchor.constraint(equalTo: newBadge.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: newBadge.centerYAnchor)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with achievement: Achievement) {
        // Set icon
        iconImageView.image = UIImage(systemName: achievement.iconName)
        
        // Set texts
        titleLabel.text = achievement.title
        descriptionLabel.text = achievement.description
        
        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateLabel.text = dateFormatter.string(from: achievement.dateEarned)
        dateLabel.numberOfLines = 1
        dateLabel.adjustsFontSizeToFitWidth = true
        dateLabel.minimumScaleFactor = 0.75
        
        // Configure level badge
        switch achievement.level {
        case 1:
            levelBadge.backgroundColor = UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0) // Bronze
        case 2:
            levelBadge.backgroundColor = UIColor(red: 0.75, green: 0.75, blue: 0.8, alpha: 1.0) // Silver
        case 3:
            levelBadge.backgroundColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold
        default:
            levelBadge.backgroundColor = .systemBlue
        }
        
        // Show/hide new badge
        newBadge.isHidden = !achievement.isNew
    }
}

// MARK: - Achievement Collection View Cell
class AchievementCell: UICollectionViewCell {
    static let identifier = "AchievementCell"
    
    private var achievementCardView: AchievementCardView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with achievement: Achievement) {
        // Remove any existing card view
        achievementCardView?.removeFromSuperview()
        
        // Create and add new card view
        achievementCardView = AchievementCardView(achievement: achievement)
        achievementCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(achievementCardView)
        
        NSLayoutConstraint.activate([
            achievementCardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            achievementCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            achievementCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            achievementCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

// MARK: - Achievement Celebration View
class AchievementCelebrationView: UIView {
    
    // MARK: - Properties
    
    private let containerView = UIView()
    private let achievementCardView: AchievementCardView
    private let confettiView = UIView()
    private let dismissButton = UIButton(type: .system)
    
    private let achievement: Achievement
    
    // MARK: - Initialization
    
    init(achievement: Achievement, frame: CGRect = .zero) {
        self.achievement = achievement
        self.achievementCardView = AchievementCardView(achievement: achievement)
        
        super.init(frame: frame)
        
        setupView()
        setupAnimations()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        // Container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.3
        addSubview(containerView)
        
        // Header label
        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = "Achievement Unlocked!"
        headerLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerLabel.textColor = .label
        headerLabel.textAlignment = .center
        containerView.addSubview(headerLabel)
        
        // Achievement card
        achievementCardView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(achievementCardView)
        
        // Confetti view
        confettiView.translatesAutoresizingMaskIntoConstraints = false
        confettiView.backgroundColor = .clear
        confettiView.isUserInteractionEnabled = false  // Allow touches to pass through to buttons
        addSubview(confettiView)
        
        // Dismiss button
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.setTitle("Great!", for: .normal)
        dismissButton.backgroundColor = .systemBlue
        dismissButton.setTitleColor(.white, for: .normal)
        dismissButton.layer.cornerRadius = 8
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        containerView.addSubview(dismissButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.85),
            
            headerLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            headerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            achievementCardView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            achievementCardView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            achievementCardView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            achievementCardView.heightAnchor.constraint(equalToConstant: 100),
            
            dismissButton.topAnchor.constraint(equalTo: achievementCardView.bottomAnchor, constant: 24),
            dismissButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            dismissButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.7),
            dismissButton.heightAnchor.constraint(equalToConstant: 44),
            dismissButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            
            confettiView.topAnchor.constraint(equalTo: topAnchor),
            confettiView.leadingAnchor.constraint(equalTo: leadingAnchor),
            confettiView.trailingAnchor.constraint(equalTo: trailingAnchor),
            confettiView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupAnimations() {
        // Start with container invisible
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        // Animate container in
        UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        })
        
        // Create and animate confetti particles
        createConfetti()
    }
    
    private func createConfetti() {
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemPink, .systemYellow, .systemOrange, .systemPurple]
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterPosition = CGPoint(x: frame.width / 2, y: -10)
        emitterLayer.emitterShape = .line
        emitterLayer.emitterSize = CGSize(width: frame.width, height: 1)
        
        var cells: [CAEmitterCell] = []
        
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 5
            cell.lifetime = 7
            cell.velocity = 150
            cell.velocityRange = 50
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 3
            cell.spinRange = 2
            cell.scale = 0.5
            cell.scaleRange = 0.25
            cell.color = color.cgColor
            
            // Create confetti shape
            let size = CGSize(width: 10, height: 5)
            UIGraphicsBeginImageContext(size)
            let context = UIGraphicsGetCurrentContext()!
            context.setFillColor(color.cgColor)
            context.addRect(CGRect(origin: .zero, size: size))
            context.fillPath()
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            cell.contents = image?.cgImage
            cells.append(cell)
        }
        
        emitterLayer.emitterCells = cells
        confettiView.layer.addSublayer(emitterLayer)
        
        // Stop emitting after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            cells.forEach { $0.birthRate = 0 }
        }
    }
    
    // MARK: - Actions
    
    @objc private func dismissTapped() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
            
            // Mark achievement as viewed
            AchievementManager.shared.markAchievementAsViewed(self.achievement.id)
            
            // Post notification that celebration was dismissed
            NotificationCenter.default.post(
                name: NSNotification.Name("AchievementCelebrationDismissed"), 
                object: nil
            )
        })
    }
}

// MARK: - Streak Label
class StreakLabel: UIView {
    
    // MARK: - Properties
    
    private let streakIconView = UIImageView()
    private let streakCountLabel = UILabel()
    private let streakTypeLabel = UILabel()
    
    // MARK: - Initialization
    
    init(streakType: StreakRecord.StreakType, streakCount: Int, frame: CGRect = .zero) {
        super.init(frame: frame)
        setupView()
        configure(streakType: streakType, count: streakCount)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 8
        
        // Streak icon
        streakIconView.translatesAutoresizingMaskIntoConstraints = false
        streakIconView.contentMode = .scaleAspectFit
        streakIconView.tintColor = .systemOrange
        addSubview(streakIconView)
        
        // Streak count
        streakCountLabel.translatesAutoresizingMaskIntoConstraints = false
        streakCountLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .bold)
        streakCountLabel.textColor = .label
        streakCountLabel.textAlignment = .center
        addSubview(streakCountLabel)
        
        // Streak type
        streakTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        streakTypeLabel.font = UIFont.systemFont(ofSize: 12)
        streakTypeLabel.textColor = .secondaryLabel
        streakTypeLabel.textAlignment = .center
        addSubview(streakTypeLabel)
        
        NSLayoutConstraint.activate([
            streakIconView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            streakIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            streakIconView.widthAnchor.constraint(equalToConstant: 24),
            streakIconView.heightAnchor.constraint(equalToConstant: 24),
            
            streakCountLabel.topAnchor.constraint(equalTo: streakIconView.bottomAnchor, constant: 4),
            streakCountLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            streakTypeLabel.topAnchor.constraint(equalTo: streakCountLabel.bottomAnchor, constant: 4),
            streakTypeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            streakTypeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            streakTypeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(streakType: StreakRecord.StreakType, count: Int) {
        streakCountLabel.text = "\(count)"
        
        var iconName = "flame.fill"
        
        switch streakType {
        case .belowDailyLimit:
            iconName = "flame.fill"
            streakTypeLabel.text = "Daily Goal"
            streakIconView.tintColor = .systemOrange
        case .weeklyReduction:
            iconName = "calendar.badge.minus"
            streakTypeLabel.text = "Weekly"
            streakIconView.tintColor = .systemGreen
        case .focusSession:
            iconName = "timer.square"
            streakTypeLabel.text = "Focus"
            streakIconView.tintColor = .systemBlue
        }
        
        streakIconView.image = UIImage(systemName: iconName)
    }
}
