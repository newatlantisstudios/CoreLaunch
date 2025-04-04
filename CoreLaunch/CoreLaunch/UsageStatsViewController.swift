//
//  UsageStatsViewController.swift
//  CoreLaunch
//
//  Created on 4/2/25.
//

import UIKit

class UsageStatsViewController: UIViewController, CalendarViewDelegate, GoalSettingDelegate {
    
    // MARK: - UI Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerLabel = UILabel()
    private let dailyUsageView = UIView()
    private let weeklyProgressView = UIView()
    private let trendsView = TrendsView()
    private let calendarContainer = UIView()
    private var calendarView: CalendarView?
    private let appBreakdownView = UIView()
    private let usageGoalsView = UIView()
    
    private let dailyUsageProgressView = UIProgressView(progressViewStyle: .bar)
    private let dailyUsageLabel = UILabel()
    private let dailyLimitLabel = UILabel()
    
    private let weeklyReductionProgressView = UIProgressView(progressViewStyle: .bar)
    private let weeklyReductionLabel = UILabel()
    private let weeklyTargetLabel = UILabel()
    
    private let appsTableView = UITableView()
    private var appUsageData: [(name: String, time: TimeInterval)] = []
    
    private let setGoalButton = UIButton(type: .system)
    
    // MARK: - Properties
    private let usageTracker = UsageTracker.shared
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Setup calendar view once we have a frame
        if calendarView == nil {
            setupCalendarView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStats()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Usage Statistics"
        view.backgroundColor = .systemBackground
        
        // Add back/close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        // Add achievements button to navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trophy"),
            style: .plain,
            target: self,
            action: #selector(achievementsButtonTapped)
        )
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Setup header
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = "Screen Time Overview"
        headerLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerLabel.textColor = .label
        contentView.addSubview(headerLabel)
        
        // Setup daily usage card
        setupDailyUsageView()
        
        // Setup weekly progress card
        setupWeeklyProgressView()
        
        // Setup trends view
        trendsView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(trendsView)
        
        // Setup calendar container
        calendarContainer.translatesAutoresizingMaskIntoConstraints = false
        calendarContainer.backgroundColor = .secondarySystemBackground
        calendarContainer.layer.cornerRadius = 12
        contentView.addSubview(calendarContainer)
        
        // Calendar header
        let calendarHeader = UILabel()
        calendarHeader.translatesAutoresizingMaskIntoConstraints = false
        calendarHeader.text = "Calendar View"
        calendarHeader.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        calendarHeader.textColor = .label
        calendarContainer.addSubview(calendarHeader)
        
        NSLayoutConstraint.activate([
            calendarHeader.topAnchor.constraint(equalTo: calendarContainer.topAnchor, constant: 16),
            calendarHeader.leadingAnchor.constraint(equalTo: calendarContainer.leadingAnchor, constant: 16),
            calendarHeader.trailingAnchor.constraint(equalTo: calendarContainer.trailingAnchor, constant: -16)
        ])
        
        // Setup app breakdown
        setupAppBreakdownView()
        
        // Setup usage goals
        setupUsageGoalsView()
        
        setupConstraints()
    }
    
    private func setupCalendarView() {
        // Calendar view needs a frame to be properly laid out
        guard calendarContainer.frame.width > 0 else { return }
        
        // Create calendar view with today's date
        let calendarFrame = CGRect(x: 0, y: 0, width: calendarContainer.frame.width, height: 300)
        calendarView = CalendarView(frame: calendarFrame, baseDate: Date())
        
        guard let calendarView = calendarView else { return }
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.delegate = self
        calendarContainer.addSubview(calendarView)
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: calendarContainer.topAnchor, constant: 50),
            calendarView.leadingAnchor.constraint(equalTo: calendarContainer.leadingAnchor, constant: 8),
            calendarView.trailingAnchor.constraint(equalTo: calendarContainer.trailingAnchor, constant: -8),
            calendarView.bottomAnchor.constraint(equalTo: calendarContainer.bottomAnchor, constant: -16)
            // Removed fixed height constraint to resolve conflict
        ])
        
        // Mark dates with usage data
        let datesWithData = UsageTracker.shared.getDatesWithUsageData()
        calendarView.markDatesWithUsageData(datesWithData)
    }
    
    private func setupDailyUsageView() {
        dailyUsageView.translatesAutoresizingMaskIntoConstraints = false
        dailyUsageView.backgroundColor = .secondarySystemBackground
        dailyUsageView.layer.cornerRadius = 12
        contentView.addSubview(dailyUsageView)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Today's Usage"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        dailyUsageView.addSubview(titleLabel)
        
        dailyUsageProgressView.translatesAutoresizingMaskIntoConstraints = false
        dailyUsageProgressView.progressTintColor = .systemBlue
        dailyUsageProgressView.trackTintColor = .systemGray5
        dailyUsageProgressView.progress = 0.0
        dailyUsageProgressView.layer.cornerRadius = 4
        dailyUsageProgressView.clipsToBounds = true
        dailyUsageView.addSubview(dailyUsageProgressView)
        
        dailyUsageLabel.translatesAutoresizingMaskIntoConstraints = false
        dailyUsageLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .medium)
        dailyUsageLabel.textColor = .label
        dailyUsageLabel.text = "0h 0m"
        dailyUsageView.addSubview(dailyUsageLabel)
        
        dailyLimitLabel.translatesAutoresizingMaskIntoConstraints = false
        dailyLimitLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        dailyLimitLabel.textColor = .secondaryLabel
        dailyLimitLabel.text = "of 1h 0m limit"
        dailyUsageView.addSubview(dailyLimitLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: dailyUsageView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: dailyUsageView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: dailyUsageView.trailingAnchor, constant: -16),
            
            dailyUsageProgressView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            dailyUsageProgressView.leadingAnchor.constraint(equalTo: dailyUsageView.leadingAnchor, constant: 16),
            dailyUsageProgressView.trailingAnchor.constraint(equalTo: dailyUsageView.trailingAnchor, constant: -16),
            dailyUsageProgressView.heightAnchor.constraint(equalToConstant: 8),
            
            dailyUsageLabel.topAnchor.constraint(equalTo: dailyUsageProgressView.bottomAnchor, constant: 12),
            dailyUsageLabel.leadingAnchor.constraint(equalTo: dailyUsageView.leadingAnchor, constant: 16),
            
            dailyLimitLabel.centerYAnchor.constraint(equalTo: dailyUsageLabel.centerYAnchor),
            dailyLimitLabel.leadingAnchor.constraint(equalTo: dailyUsageLabel.trailingAnchor, constant: 8),
            dailyLimitLabel.trailingAnchor.constraint(lessThanOrEqualTo: dailyUsageView.trailingAnchor, constant: -16),
            dailyLimitLabel.bottomAnchor.constraint(equalTo: dailyUsageView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupWeeklyProgressView() {
        weeklyProgressView.translatesAutoresizingMaskIntoConstraints = false
        weeklyProgressView.backgroundColor = .secondarySystemBackground
        weeklyProgressView.layer.cornerRadius = 12
        contentView.addSubview(weeklyProgressView)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Weekly Reduction"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        weeklyProgressView.addSubview(titleLabel)
        
        weeklyReductionProgressView.translatesAutoresizingMaskIntoConstraints = false
        weeklyReductionProgressView.progressTintColor = .systemGreen
        weeklyReductionProgressView.trackTintColor = .systemGray5
        weeklyReductionProgressView.progress = 0.0
        weeklyReductionProgressView.layer.cornerRadius = 4
        weeklyReductionProgressView.clipsToBounds = true
        weeklyProgressView.addSubview(weeklyReductionProgressView)
        
        weeklyReductionLabel.translatesAutoresizingMaskIntoConstraints = false
        weeklyReductionLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .medium)
        weeklyReductionLabel.textColor = .label
        weeklyReductionLabel.text = "0%"
        weeklyProgressView.addSubview(weeklyReductionLabel)
        
        weeklyTargetLabel.translatesAutoresizingMaskIntoConstraints = false
        weeklyTargetLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        weeklyTargetLabel.textColor = .secondaryLabel
        weeklyTargetLabel.text = "of 5% target"
        weeklyProgressView.addSubview(weeklyTargetLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: weeklyProgressView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: weeklyProgressView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: weeklyProgressView.trailingAnchor, constant: -16),
            
            weeklyReductionProgressView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            weeklyReductionProgressView.leadingAnchor.constraint(equalTo: weeklyProgressView.leadingAnchor, constant: 16),
            weeklyReductionProgressView.trailingAnchor.constraint(equalTo: weeklyProgressView.trailingAnchor, constant: -16),
            weeklyReductionProgressView.heightAnchor.constraint(equalToConstant: 8),
            
            weeklyReductionLabel.topAnchor.constraint(equalTo: weeklyReductionProgressView.bottomAnchor, constant: 12),
            weeklyReductionLabel.leadingAnchor.constraint(equalTo: weeklyProgressView.leadingAnchor, constant: 16),
            
            weeklyTargetLabel.centerYAnchor.constraint(equalTo: weeklyReductionLabel.centerYAnchor),
            weeklyTargetLabel.leadingAnchor.constraint(equalTo: weeklyReductionLabel.trailingAnchor, constant: 8),
            weeklyTargetLabel.trailingAnchor.constraint(lessThanOrEqualTo: weeklyProgressView.trailingAnchor, constant: -16),
            weeklyTargetLabel.bottomAnchor.constraint(equalTo: weeklyProgressView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupAppBreakdownView() {
        appBreakdownView.translatesAutoresizingMaskIntoConstraints = false
        appBreakdownView.backgroundColor = .secondarySystemBackground
        appBreakdownView.layer.cornerRadius = 12
        contentView.addSubview(appBreakdownView)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "App Breakdown"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        appBreakdownView.addSubview(titleLabel)
        
        appsTableView.translatesAutoresizingMaskIntoConstraints = false
        appsTableView.backgroundColor = .clear
        appsTableView.delegate = self
        appsTableView.dataSource = self
        appsTableView.register(AppUsageCell.self, forCellReuseIdentifier: "AppUsageCell")
        appsTableView.isScrollEnabled = false
        appsTableView.separatorStyle = .none
        appsTableView.rowHeight = 50
        appBreakdownView.addSubview(appsTableView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: appBreakdownView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: appBreakdownView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: appBreakdownView.trailingAnchor, constant: -16),
            
            appsTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            appsTableView.leadingAnchor.constraint(equalTo: appBreakdownView.leadingAnchor),
            appsTableView.trailingAnchor.constraint(equalTo: appBreakdownView.trailingAnchor),
            appsTableView.bottomAnchor.constraint(equalTo: appBreakdownView.bottomAnchor, constant: -8),
            appsTableView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func setupUsageGoalsView() {
        usageGoalsView.translatesAutoresizingMaskIntoConstraints = false
        usageGoalsView.backgroundColor = .secondarySystemBackground
        usageGoalsView.layer.cornerRadius = 12
        contentView.addSubview(usageGoalsView)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Screen Time Goals"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        usageGoalsView.addSubview(titleLabel)
        
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = "Set daily limits and weekly reduction targets to help reduce your screen time."
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        usageGoalsView.addSubview(descriptionLabel)
        
        setGoalButton.translatesAutoresizingMaskIntoConstraints = false
        setGoalButton.setTitle("Set Goals", for: .normal)
        setGoalButton.backgroundColor = .systemBlue
        setGoalButton.setTitleColor(.white, for: .normal)
        setGoalButton.layer.cornerRadius = 8
        setGoalButton.addTarget(self, action: #selector(setGoalButtonTapped), for: .touchUpInside)
        usageGoalsView.addSubview(setGoalButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: usageGoalsView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: usageGoalsView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: usageGoalsView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: usageGoalsView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: usageGoalsView.trailingAnchor, constant: -16),
            
            setGoalButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            setGoalButton.centerXAnchor.constraint(equalTo: usageGoalsView.centerXAnchor),
            setGoalButton.widthAnchor.constraint(equalTo: usageGoalsView.widthAnchor, multiplier: 0.7),
            setGoalButton.heightAnchor.constraint(equalToConstant: 44),
            setGoalButton.bottomAnchor.constraint(equalTo: usageGoalsView.bottomAnchor, constant: -16)
        ])
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
            
            dailyUsageView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            dailyUsageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dailyUsageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            weeklyProgressView.topAnchor.constraint(equalTo: dailyUsageView.bottomAnchor, constant: 16),
            weeklyProgressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            weeklyProgressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            trendsView.topAnchor.constraint(equalTo: weeklyProgressView.bottomAnchor, constant: 16),
            trendsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            trendsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            trendsView.heightAnchor.constraint(equalToConstant: 250),
            
            calendarContainer.topAnchor.constraint(equalTo: trendsView.bottomAnchor, constant: 16),
            calendarContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            calendarContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            calendarContainer.heightAnchor.constraint(equalToConstant: 370),
            
            appBreakdownView.topAnchor.constraint(equalTo: calendarContainer.bottomAnchor, constant: 16),
            appBreakdownView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            appBreakdownView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            usageGoalsView.topAnchor.constraint(equalTo: appBreakdownView.bottomAnchor, constant: 16),
            usageGoalsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            usageGoalsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            usageGoalsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    // MARK: - Data
    private func updateStats(forDate date: Date = Date()) {
        // Update daily usage stats
        updateDailyStats(forDate: date)
        
        // Update weekly reduction stats
        updateWeeklyStats()
        
        // Update trends view
        let usageTrends = UsageTracker.shared.getUsageTrends(for: 30)
        let usageData = Dictionary(uniqueKeysWithValues: usageTrends.map { ($0.date, $0.usage) })
        trendsView.setUsageData(usageData)
        
        // Update app breakdown data
        updateAppUsageData(forDate: date)
    }
    
    private func updateDailyStats(forDate date: Date) {
        // If looking at today, use the live data
        let calendar = Calendar.current
        let dailyUsage: DailyUsage?
        
        if calendar.isDateInToday(date) {
            let (currentUsage, limit, percentOfLimit) = UsageTracker.shared.getGoalProgress()
            dailyUsageProgressView.progress = Float(min(percentOfLimit / 100, 1.0))
            dailyUsageLabel.text = formatTimeInterval(currentUsage)
            dailyLimitLabel.text = "of \(formatTimeInterval(limit)) limit"
            
            // Update color based on usage
            if percentOfLimit >= 100 {
                dailyUsageProgressView.progressTintColor = .systemRed
            } else if percentOfLimit >= 75 {
                dailyUsageProgressView.progressTintColor = .systemOrange
            } else {
                dailyUsageProgressView.progressTintColor = .systemBlue
            }
            
            // Use today's usage data
            dailyUsage = UsageTracker.shared.getTodayUsage()
        } else {
            // Use historical data for the selected date
            dailyUsage = UsageTracker.shared.getUsageHistoryForDate(date)
            
            // Get goal data
            let limit = UsageTracker.shared.getUsageGoal().dailyUsageLimit
            let usage = dailyUsage?.totalUsageTime ?? 0
            let percentOfLimit = limit > 0 ? (usage / limit) * 100 : 0
            
            dailyUsageProgressView.progress = Float(min(percentOfLimit / 100, 1.0))
            dailyUsageLabel.text = formatTimeInterval(usage)
            dailyLimitLabel.text = "of \(formatTimeInterval(limit)) limit"
            
            // Update color based on usage
            if percentOfLimit >= 100 {
                dailyUsageProgressView.progressTintColor = .systemRed
            } else if percentOfLimit >= 75 {
                dailyUsageProgressView.progressTintColor = .systemOrange
            } else {
                dailyUsageProgressView.progressTintColor = .systemBlue
            }
        }
    }
    
    private func updateWeeklyStats() {
        let (currentReduction, target, percentOfTarget) = usageTracker.getWeeklyReductionProgress()
        weeklyReductionProgressView.progress = Float(min(percentOfTarget / 100, 1.0))
        
        // Format reduction with sign
        let reductionText = currentReduction >= 0 ? 
            String(format: "%.1f%%", currentReduction) : 
            String(format: "%.1f%%", currentReduction)
        weeklyReductionLabel.text = reductionText
        weeklyTargetLabel.text = "of \(String(format: "%.1f%%", target)) target"
        
        // Update color based on progress
        if currentReduction < 0 {
            weeklyReductionProgressView.progressTintColor = .systemRed
        } else if currentReduction >= target {
            weeklyReductionProgressView.progressTintColor = .systemGreen
        } else {
            weeklyReductionProgressView.progressTintColor = .systemOrange
        }
    }
    
    private func updateAppUsageData(forDate date: Date) {
        // Get usage data for the selected date
        var usageData: [String: UsageStats] = [:]
        
        if Calendar.current.isDateInToday(date) {
            // For today, use the live data
            if let todayUsage = UsageTracker.shared.getTodayUsage() {
                usageData = todayUsage.appStats
            }
        } else {
            // For other days, get historical data
            if let historicalUsage = UsageTracker.shared.getUsageHistoryForDate(date) {
                usageData = historicalUsage.appStats
            }
        }
        
        // Transform app stats into array for table view
        appUsageData = usageData.map { (name: $0.key, time: $0.value.totalUsageTime) }
        
        // Sort by usage time (descending)
        appUsageData.sort { $0.time > $1.time }
        
        // Limit to top 5 apps
        if appUsageData.count > 5 {
            appUsageData = Array(appUsageData.prefix(5))
        }
        
        // Reload table view
        appsTableView.reloadData()
    }
    
    // MARK: - Helper Methods
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func setGoalButtonTapped() {
        let goalVC = GoalSettingViewController()
        goalVC.delegate = self
        goalVC.modalPresentationStyle = .overFullScreen
        goalVC.modalTransitionStyle = .crossDissolve
        present(goalVC, animated: true)
    }
    
    @objc private func achievementsButtonTapped() {
        let achievementsVC = UsageTracker.shared.getAchievementsDashboard()
        navigationController?.pushViewController(achievementsVC, animated: true)
    }
    
    // MARK: - CalendarViewDelegate
    func didSelectDate(_ date: Date) {
        // Update stats for the selected date
        updateStats(forDate: date)
    }
    
    // MARK: - GoalSettingDelegate
    func didUpdateGoals(dailyLimit: TimeInterval, weeklyReduction: Double) {
        // Update usage goal
        usageTracker.updateUsageGoal(
            dailyLimit: dailyLimit,
            weeklyReduction: weeklyReduction
        )
        
        // Update UI
        updateStats()
    }
}

// MARK: - TableView DataSource & Delegate
extension UsageStatsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appUsageData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AppUsageCell", for: indexPath) as? AppUsageCell else {
            return UITableViewCell()
        }
        
        let appData = appUsageData[indexPath.row]
        cell.configure(with: appData.name, time: appData.time, rank: indexPath.row + 1)
        
        return cell
    }
}

// MARK: - App Usage Cell
class AppUsageCell: UITableViewCell {
    private let rankLabel = UILabel()
    private let appNameLabel = UILabel()
    private let usageTimeLabel = UILabel()
    private let backgroundCardView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Background card
        backgroundCardView.translatesAutoresizingMaskIntoConstraints = false
        backgroundCardView.backgroundColor = .tertiarySystemBackground
        backgroundCardView.layer.cornerRadius = 8
        contentView.addSubview(backgroundCardView)
        
        // Rank label
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        rankLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        rankLabel.textColor = .secondaryLabel
        rankLabel.textAlignment = .center
        contentView.addSubview(rankLabel)
        
        // App name label
        appNameLabel.translatesAutoresizingMaskIntoConstraints = false
        appNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        appNameLabel.textColor = .label
        contentView.addSubview(appNameLabel)
        
        // Usage time label
        usageTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        usageTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        usageTimeLabel.textColor = .secondaryLabel
        usageTimeLabel.textAlignment = .right
        contentView.addSubview(usageTimeLabel)
        
        NSLayoutConstraint.activate([
            backgroundCardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            backgroundCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            backgroundCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            backgroundCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            rankLabel.leadingAnchor.constraint(equalTo: backgroundCardView.leadingAnchor, constant: 12),
            rankLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rankLabel.widthAnchor.constraint(equalToConstant: 24),
            
            appNameLabel.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 12),
            appNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            usageTimeLabel.trailingAnchor.constraint(equalTo: backgroundCardView.trailingAnchor, constant: -12),
            usageTimeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            usageTimeLabel.leadingAnchor.constraint(equalTo: appNameLabel.trailingAnchor, constant: 8)
        ])
    }
    
    func configure(with appName: String, time: TimeInterval, rank: Int) {
        rankLabel.text = "\(rank)"
        appNameLabel.text = appName
        
        // Format time
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        if hours > 0 {
            usageTimeLabel.text = "\(hours)h \(minutes)m"
        } else {
            usageTimeLabel.text = "\(minutes)m"
        }
    }
}
