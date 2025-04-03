//
//  FocusStatsViewController.swift
//  CoreLaunch
//
//  Created on 4/2/25.
//

import UIKit
import Charts

class FocusStatsViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let todaySummaryView = UIView()
    private let weekBarChartView = UIView()
    private let focusHistoryTableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // MARK: - Properties
    private let focusManager = FocusModeManager.shared
    private var focusSessions: [FocusSession] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Focus Stats"
        view.backgroundColor = .systemBackground
        
        setupUI()
        loadData()
        
        // Configure scroll view to show full content initially
        scrollView.contentInsetAdjustmentBehavior = .automatic
        scrollView.showsVerticalScrollIndicator = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadData()
        updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set initial scroll position to top to ensure weekly chart is visible
        scrollView.contentOffset = .zero
        
        // Force layout to ensure all subviews are properly sized
        view.layoutIfNeeded()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Today's summary view
        todaySummaryView.translatesAutoresizingMaskIntoConstraints = false
        todaySummaryView.backgroundColor = .secondarySystemBackground
        todaySummaryView.layer.cornerRadius = 12
        contentView.addSubview(todaySummaryView)
        
        // Week bar chart view
        weekBarChartView.translatesAutoresizingMaskIntoConstraints = false
        weekBarChartView.backgroundColor = .secondarySystemBackground
        weekBarChartView.layer.cornerRadius = 12
        contentView.addSubview(weekBarChartView)
        
        // Focus history table view
        focusHistoryTableView.translatesAutoresizingMaskIntoConstraints = false
        focusHistoryTableView.dataSource = self
        focusHistoryTableView.delegate = self
        focusHistoryTableView.register(UITableViewCell.self, forCellReuseIdentifier: "FocusSessionCell")
        focusHistoryTableView.isScrollEnabled = false // We're using the scroll view
        contentView.addSubview(focusHistoryTableView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Today's summary view
            todaySummaryView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            todaySummaryView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            todaySummaryView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            todaySummaryView.heightAnchor.constraint(equalToConstant: 80),
            
            // Week bar chart view - drastically reduced height
            weekBarChartView.topAnchor.constraint(equalTo: todaySummaryView.bottomAnchor, constant: 4),
            weekBarChartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            weekBarChartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            weekBarChartView.heightAnchor.constraint(equalToConstant: 100), // Absolute minimum for grid layout
            
            // Focus history table view
            focusHistoryTableView.topAnchor.constraint(equalTo: weekBarChartView.bottomAnchor, constant: 8),
            focusHistoryTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            focusHistoryTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            focusHistoryTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            // Use a smaller fixed height for the table view
            focusHistoryTableView.heightAnchor.constraint(equalToConstant: 240) // Smaller fixed height
        ])
        
        setupTodaySummary()
        setupWeekBarChart()
    }
    
    private func setupTodaySummary() {
        // Create a container view for the title to prevent clipping
        let titleContainer = UIView()
        titleContainer.translatesAutoresizingMaskIntoConstraints = false
        titleContainer.clipsToBounds = false
        todaySummaryView.addSubview(titleContainer)
        
        // Title with adjusted bounds to fit descenders
        let titleLabel = UILabel()
        titleLabel.text = "Today's Focus"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textAlignment = .left
        titleLabel.clipsToBounds = false  // Prevent text clipping
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleContainer.addSubview(titleLabel)
        
        // Statistics stack
        let statsStack = UIStackView()
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = 12
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        todaySummaryView.addSubview(statsStack)
        
        // Session count stat
        let sessionCountView = createStatView(title: "Sessions", value: "0")
        sessionCountView.tag = 100 // For easy update
        statsStack.addArrangedSubview(sessionCountView)
        
        // Total time stat
        let totalTimeView = createStatView(title: "Total Time", value: "0m")
        totalTimeView.tag = 101 // For easy update
        statsStack.addArrangedSubview(totalTimeView)
        
        // Completion rate stat
        let completionRateView = createStatView(title: "Completed", value: "0%")
        completionRateView.tag = 102 // For easy update
        statsStack.addArrangedSubview(completionRateView)
        
        // Layout with proper spacing for title visibility
        NSLayoutConstraint.activate([
            // Title container with extra height
            titleContainer.topAnchor.constraint(equalTo: todaySummaryView.topAnchor, constant: 8),
            titleContainer.leadingAnchor.constraint(equalTo: todaySummaryView.leadingAnchor, constant: 16),
            titleContainer.trailingAnchor.constraint(equalTo: todaySummaryView.trailingAnchor, constant: -16),
            titleContainer.heightAnchor.constraint(equalToConstant: 24), // Extra height for descenders
            
            // Title label positioned within container
            titleLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor),
            
            statsStack.topAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: 4),
            statsStack.leadingAnchor.constraint(equalTo: todaySummaryView.leadingAnchor, constant: 16),
            statsStack.trailingAnchor.constraint(equalTo: todaySummaryView.trailingAnchor, constant: -16),
            statsStack.bottomAnchor.constraint(equalTo: todaySummaryView.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupWeekBarChart() {
        // Title - minimal styling
        let titleLabel = UILabel()
        titleLabel.text = "This Week's Focus"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold) // Smallest font size that's still readable
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        weekBarChartView.addSubview(titleLabel)
        
        // Chart view (placeholder)
        let chartPlaceholder = UIView()
        chartPlaceholder.backgroundColor = .clear // No background
        chartPlaceholder.tag = 200 // For easy replacement with actual chart
        chartPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        weekBarChartView.addSubview(chartPlaceholder)
        
        // Layout with absolute minimum spacing
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: weekBarChartView.topAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: weekBarChartView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: weekBarChartView.trailingAnchor, constant: -10),
            
            chartPlaceholder.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0), // No gap
            chartPlaceholder.leadingAnchor.constraint(equalTo: weekBarChartView.leadingAnchor, constant: 10),
            chartPlaceholder.trailingAnchor.constraint(equalTo: weekBarChartView.trailingAnchor, constant: -10),
            chartPlaceholder.bottomAnchor.constraint(equalTo: weekBarChartView.bottomAnchor, constant: -2)
        ])
    }
    
    private func createStatView(title: String, value: String) -> UIView {
        let statView = UIView()
        
        // Create a vertically spaced stack for the content
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 4  // Add explicit spacing
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        statView.addSubview(contentStack)
        
        // Value label
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        valueLabel.textAlignment = .center
        valueLabel.clipsToBounds = false
        
        // Title label with extra bottom padding to prevent clipping
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.clipsToBounds = false
        
        // Add labels to stack
        contentStack.addArrangedSubview(valueLabel)
        contentStack.addArrangedSubview(titleLabel)
        
        // Center the stack in the view
        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: statView.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: statView.centerYAnchor),
            contentStack.widthAnchor.constraint(equalTo: statView.widthAnchor)
        ])
        
        return statView
    }
    
    // MARK: - Lifecycle Overrides
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Force update the chart immediately after layout
        updateWeekChart()
        
        // Force layout to ensure chart is visible
        view.layoutIfNeeded()
    }
    
    // MARK: - Data
    private func loadData() {
        // Get all focus sessions
        focusSessions = focusManager.getFocusSessionHistory()
        
        // Update table height
        // Set table height to show just enough rows to fit in available space
        let tableHeight = CGFloat(min(focusSessions.count, 3) * 60 + 60) // 3 visible rows + header
        for constraint in focusHistoryTableView.constraints where constraint.firstAttribute == .height {
            constraint.constant = tableHeight
        }
        
        // Reload table
        focusHistoryTableView.reloadData()
    }
    
    private func updateUI() {
        updateTodayStats()
        updateWeekChart()
    }
    
    private func updateTodayStats() {
        // Get today's sessions
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let todaySessions = focusSessions.filter { 
            calendar.startOfDay(for: $0.startTime) == today
        }
        
        // Calculate stats
        let sessionCount = todaySessions.count
        let totalMinutes = Int(todaySessions.reduce(0) { $0 + $1.duration } / 60)
        
        let completedSessions = todaySessions.filter { $0.isCompleted }
        let completionRate = sessionCount > 0 ? (completedSessions.count * 100 / sessionCount) : 0
        
        // Update UI
        if let sessionCountView = todaySummaryView.viewWithTag(100),
           let sessionValueLabel = sessionCountView.subviews.first as? UILabel {
            sessionValueLabel.text = "\(sessionCount)"
        }
        
        if let totalTimeView = todaySummaryView.viewWithTag(101),
           let totalValueLabel = totalTimeView.subviews.first as? UILabel {
            totalValueLabel.text = "\(totalMinutes)m"
        }
        
        if let completionRateView = todaySummaryView.viewWithTag(102),
           let completionValueLabel = completionRateView.subviews.first as? UILabel {
            completionValueLabel.text = "\(completionRate)%"
        }
    }
    
    private func updateWeekChart() {
        // Get last 7 days sessions
        let calendar = Calendar.current
        let weekData = (0..<7).map { daysAgo -> (String, Int) in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let daySessions = focusSessions.filter { 
                $0.startTime >= dayStart && $0.startTime < dayEnd 
            }
            
            let totalMinutes = Int(daySessions.reduce(0) { $0 + $1.duration } / 60)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE"
            let dayLabel = dateFormatter.string(from: date)
            
            return (dayLabel, totalMinutes)
        }.reversed()
        
        // Find the chart placeholder
        guard let chartPlaceholder = weekBarChartView.viewWithTag(200) else { return }
        
        // Ensure the placeholder has a valid frame size before proceeding
        if chartPlaceholder.bounds.isEmpty {
            // Force layout to ensure we have actual dimensions
            weekBarChartView.layoutIfNeeded()
            
            // If still no valid dimensions, try again in the next run loop
            if chartPlaceholder.bounds.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    self?.updateWeekChart()
                }
                return
            }
        }
        
        // Remove any existing elements
        chartPlaceholder.subviews.forEach { $0.removeFromSuperview() }
        
        // Create ultra-compact visualization
        // Use a 7-box horizontal mini-chart for maximum space efficiency
        let boxWidth = (chartPlaceholder.bounds.width - 14) / 7 // 2px gap between boxes
        let maxValue = CGFloat(weekData.map { $0.1 }.max() ?? 1)
        
        // Create a horizontal row of boxes with color intensity based on value
        for (index, dayData) in weekData.enumerated() {
            // Get normalized value (0-1 range)
            let normalizedValue = maxValue > 0 ? CGFloat(dayData.1) / maxValue : 0
            
            // Create the day container with label and box
            let dayContainer = UIView()
            dayContainer.frame = CGRect(
                x: CGFloat(index) * (boxWidth + 2),
                y: 0,
                width: boxWidth,
                height: chartPlaceholder.bounds.height
            )
            chartPlaceholder.addSubview(dayContainer)
            
            // Day box showing focus amount - colored by intensity
            let dayBox = UIView()
            dayBox.frame = CGRect(
                x: 0,
                y: 0,
                width: boxWidth,
                height: boxWidth
            )
            
            // Color based on value - from light to dark blue
            if dayData.1 > 0 {
                let alpha = max(0.2, min(1.0, normalizedValue)) // Ensure at least light color
                dayBox.backgroundColor = UIColor.systemBlue.withAlphaComponent(alpha)
            } else {
                dayBox.backgroundColor = UIColor.systemGray5 // Empty state
            }
            dayBox.layer.cornerRadius = 4
            dayContainer.addSubview(dayBox)
            
            // Day label
            let dayLabel = UILabel()
            dayLabel.text = dayData.0
            dayLabel.font = UIFont.systemFont(ofSize: 9)
            dayLabel.textAlignment = .center
            dayLabel.frame = CGRect(
                x: 0,
                y: boxWidth + 2,
                width: boxWidth,
                height: 12
            )
            dayContainer.addSubview(dayLabel)
            
            // Minutes label (only if value > 0)
            if dayData.1 > 0 {
                let minutesLabel = UILabel()
                minutesLabel.text = "\(dayData.1)m"
                minutesLabel.font = UIFont.systemFont(ofSize: 8)
                minutesLabel.textColor = .secondaryLabel
                minutesLabel.textAlignment = .center
                minutesLabel.frame = CGRect(
                    x: 0,
                    y: boxWidth + 14,
                    width: boxWidth,
                    height: 10
                )
                dayContainer.addSubview(minutesLabel)
            }
        }
    }
}

// MARK: - TableView Delegate & DataSource

extension FocusStatsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(focusSessions.count, 5) // Limit to 5 sessions for the fixed-height table
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Recent Focus Sessions"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FocusSessionCell", for: indexPath)
        
        if indexPath.row < focusSessions.count {
            let session = focusSessions.sorted(by: { $0.startTime > $1.startTime })[indexPath.row]
            
            // Format date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            let dateString = dateFormatter.string(from: session.startTime)
            
            // Format duration
            let minutes = Int(session.duration / 60)
            
            // Format status
            let statusString: String
            if session.isCompleted {
                statusString = "Completed"
            } else if session.isActive {
                statusString = "Active"
            } else {
                statusString = "Incomplete"
            }
            
            // Configure cell
            var content = cell.defaultContentConfiguration()
            content.text = "\(dateString) - \(minutes) minutes"
            
            // Show which apps are blocked
            let blockedAppsList = session.blockedApps.isEmpty ? "No apps blocked" : session.blockedApps.joined(separator: ", ")
            content.secondaryText = "\(statusString) • " + blockedAppsList
            
            // Add status color
            if session.isCompleted {
                content.secondaryTextProperties.color = .systemGreen
            } else if session.isActive {
                content.secondaryTextProperties.color = .systemBlue
            } else {
                content.secondaryTextProperties.color = .systemRed
            }
            
            cell.contentConfiguration = content
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if focusSessions.count > 5 {
            let footerView = UIView()
            
            let seeAllButton = UIButton(type: .system)
            seeAllButton.setTitle("See All Focus Sessions", for: .normal)
            seeAllButton.addTarget(self, action: #selector(seeAllSessionsTapped), for: .touchUpInside)
            seeAllButton.translatesAutoresizingMaskIntoConstraints = false
            footerView.addSubview(seeAllButton)
            
            NSLayoutConstraint.activate([
                seeAllButton.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
                seeAllButton.centerYAnchor.constraint(equalTo: footerView.centerYAnchor)
            ])
            
            return footerView
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return focusSessions.count > 5 ? 44 : 0
    }
    
    @objc private func seeAllSessionsTapped() {
        // Show a full-screen modal with all sessions
        let allSessionsVC = UITableViewController(style: .insetGrouped)
        allSessionsVC.title = "All Focus Sessions"
        
        // Configure table view
        allSessionsVC.tableView.dataSource = self
        allSessionsVC.tableView.delegate = self
        allSessionsVC.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FocusSessionCell")
        
        // Present modally
        let navController = UINavigationController(rootViewController: allSessionsVC)
        navController.modalPresentationStyle = .formSheet
        
        // Add done button
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal))
        allSessionsVC.navigationItem.rightBarButtonItem = doneButton
        
        present(navController, animated: true)
    }
    
    @objc private func dismissModal() {
        dismiss(animated: true)
    }
}
