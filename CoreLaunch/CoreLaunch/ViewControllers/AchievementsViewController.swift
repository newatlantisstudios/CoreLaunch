//
//  AchievementsViewController.swift
//  CoreLaunch
//
//  Created for Positive Reinforcement System
//

import UIKit

class AchievementsViewController: UIViewController {
    
    // MARK: - Properties
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerLabel = UILabel()
    private let streaksView = UIView()
    private let achievementsCollectionView: UICollectionView
    
    private let achievementManager = AchievementManager.shared
    private var achievements: [AchievementCategory: [Achievement]] = [:]
    private var allCategories: [AchievementCategory] = []
    
    // MARK: - Initialization
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        achievementsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAchievements()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "Achievements"
        view.backgroundColor = .systemBackground
        
        // Add back/close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Setup header
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = "Your Digital Wellbeing Journey"
        headerLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerLabel.textColor = .label
        contentView.addSubview(headerLabel)
        
        // Setup streaks view
        setupStreaksView()
        
        // Setup collection view
        achievementsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        achievementsCollectionView.backgroundColor = .clear
        achievementsCollectionView.delegate = self
        achievementsCollectionView.dataSource = self
        achievementsCollectionView.register(AchievementCell.self, forCellWithReuseIdentifier: AchievementCell.identifier)
        achievementsCollectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        contentView.addSubview(achievementsCollectionView)
        
        // Setup constraints
        setupConstraints()
    }
    
    private func setupStreaksView() {
        streaksView.translatesAutoresizingMaskIntoConstraints = false
        streaksView.backgroundColor = .secondarySystemBackground
        streaksView.layer.cornerRadius = 12
        contentView.addSubview(streaksView)
        
        let streakTitleLabel = UILabel()
        streakTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        streakTitleLabel.text = "Current Streaks"
        streakTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        streakTitleLabel.textColor = .label
        streaksView.addSubview(streakTitleLabel)
        
        // Create streak labels
        let dailyStreakView = createStreakView(for: .belowDailyLimit)
        let weeklyStreakView = createStreakView(for: .weeklyReduction)
        let focusStreakView = createStreakView(for: .focusSession)
        
        // Add to horizontal stack
        let streakStack = UIStackView(arrangedSubviews: [dailyStreakView, weeklyStreakView, focusStreakView])
        streakStack.translatesAutoresizingMaskIntoConstraints = false
        streakStack.axis = .horizontal
        streakStack.distribution = .fillEqually
        streakStack.spacing = 12
        streaksView.addSubview(streakStack)
        
        NSLayoutConstraint.activate([
            streakTitleLabel.topAnchor.constraint(equalTo: streaksView.topAnchor, constant: 16),
            streakTitleLabel.leadingAnchor.constraint(equalTo: streaksView.leadingAnchor, constant: 16),
            streakTitleLabel.trailingAnchor.constraint(equalTo: streaksView.trailingAnchor, constant: -16),
            
            streakStack.topAnchor.constraint(equalTo: streakTitleLabel.bottomAnchor, constant: 16),
            streakStack.leadingAnchor.constraint(equalTo: streaksView.leadingAnchor, constant: 16),
            streakStack.trailingAnchor.constraint(equalTo: streaksView.trailingAnchor, constant: -16),
            streakStack.bottomAnchor.constraint(equalTo: streaksView.bottomAnchor, constant: -16),
            streakStack.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func createStreakView(for type: StreakRecord.StreakType) -> UIView {
        let streak = achievementManager.getStreak(type: type)
        return StreakLabel(streakType: type, streakCount: streak.currentStreak)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            streaksView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            streaksView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            streaksView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            achievementsCollectionView.topAnchor.constraint(equalTo: streaksView.bottomAnchor, constant: 16),
            achievementsCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            achievementsCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            achievementsCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            achievementsCollectionView.heightAnchor.constraint(equalToConstant: 600) // Adjust as needed
        ])
    }
    
    // MARK: - Data
    
    private func loadAchievements() {
        // Clear existing data
        achievements.removeAll()
        allCategories.removeAll()
        
        // Get all achievement categories
        let categories: [AchievementCategory] = [
            .dailyGoal, .weeklyReduction, .streaks, .specialMilestone, .focusSession
        ]
        
        // Load achievements by category
        for category in categories {
            let categoryAchievements = achievementManager.getAchievementsByCategory(category)
            if !categoryAchievements.isEmpty {
                achievements[category] = categoryAchievements
                allCategories.append(category)
            }
        }
        
        // Reload collection view
        achievementsCollectionView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - Collection View Delegate & DataSource
extension AchievementsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return allCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let category = allCategories[section]
        return achievements[category]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AchievementCell.identifier, for: indexPath) as? AchievementCell else {
            return UICollectionViewCell()
        }
        
        let category = allCategories[indexPath.section]
        if let categoryAchievements = achievements[category], indexPath.item < categoryAchievements.count {
            let achievement = categoryAchievements[indexPath.item]
            cell.configure(with: achievement)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as? SectionHeaderView else {
                return UICollectionReusableView()
            }
            
            let category = allCategories[indexPath.section]
            headerView.configure(with: category.rawValue)
            
            return headerView
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 32 // Adjust for insets
        return CGSize(width: width, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = allCategories[indexPath.section]
        if let categoryAchievements = achievements[category], indexPath.item < categoryAchievements.count {
            let achievement = categoryAchievements[indexPath.item]
            
            // Mark as viewed if new
            if achievement.isNew {
                achievementManager.markAchievementAsViewed(achievement.id)
                
                // Reload this specific cell
                collectionView.reloadItems(at: [indexPath])
            }
        }
    }
}

// MARK: - Section Header View
class SectionHeaderView: UICollectionReusableView {
    static let identifier = "SectionHeaderView"
    
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .label
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with title: String) {
        titleLabel.text = title
    }
}
