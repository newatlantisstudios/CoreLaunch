//
//  TrendsView.swift
//  CoreLaunch
//
//  Created on 4/2/25.
//

import UIKit

class TrendsView: UIView {
    // MARK: - Properties
    private let titleLabel = UILabel()
    private let chartView = UIView()
    private let segmentedControl = UISegmentedControl(items: ["Week", "Month", "3 Months"])
    
    private var usageData: [Date: TimeInterval] = [:]
    private var graphBars: [UIView] = []
    private var graphLabels: [UILabel] = []
    private var timeRangeLabels: [UILabel] = []
    private var currentPeriod: Period = .week
    
    enum Period {
        case week
        case month
        case threeMonths
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Usage Trends"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        addSubview(titleLabel)
        
        // Segmented control for time period
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0 // Default to week
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedControl.backgroundColor = .systemBackground
        segmentedControl.selectedSegmentTintColor = .systemBlue
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentedControl.layer.cornerRadius = 8
        segmentedControl.clipsToBounds = true
        segmentedControl.apportionsSegmentWidthsByContent = true
        addSubview(segmentedControl)
        
        // Chart view container
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.backgroundColor = .clear
        addSubview(chartView)
        
        // Create height constraint with priority
        let chartViewHeightConstraint = chartView.heightAnchor.constraint(equalToConstant: 200)
        chartViewHeightConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            segmentedControl.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            segmentedControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            segmentedControl.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.7),
            segmentedControl.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 20),
            
            chartView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            chartView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chartView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        
        // Activate height constraint separately
        chartViewHeightConstraint.isActive = true
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            currentPeriod = .week
        case 1:
            currentPeriod = .month
        case 2:
            currentPeriod = .threeMonths
        default:
            currentPeriod = .week
        }
        
        updateChart()
    }
    
    // MARK: - Public Methods
    func setUsageData(_ data: [Date: TimeInterval]) {
        usageData = data
        updateChart()
    }
    
    // MARK: - Private Methods
    private func updateChart() {
        // Clear existing chart elements
        graphBars.forEach { $0.removeFromSuperview() }
        graphLabels.forEach { $0.removeFromSuperview() }
        timeRangeLabels.forEach { $0.removeFromSuperview() }
        
        graphBars = []
        graphLabels = []
        timeRangeLabels = []
        
        // Get date range based on selected period
        let (dates, labels) = getDatesForPeriod(currentPeriod)
        guard !dates.isEmpty else { return }
        
        // Get usage data for the dates
        var dataPoints: [(date: Date, usage: TimeInterval)] = []
        
        for date in dates {
            // Find the matching date in the usage data
            let calendar = Calendar.current
            let usageForDate = usageData.filter { (key, _) in
                calendar.isDate(key, inSameDayAs: date)
            }.map { $0.value }.first ?? 0
            
            dataPoints.append((date: date, usage: usageForDate))
        }
        
        // Find the maximum usage to scale the bars
        let maxUsage = dataPoints.map { $0.usage }.max() ?? 3600 // Default to 1 hour if no data
        
        // Create bars
        // Ensure positive values for width calculations
        let chartAvailableWidth = max(chartView.frame.width - 50, 1) // Ensure positive width
        let barWidth = chartAvailableWidth / max(CGFloat(dataPoints.count), 1) // Avoid division by zero
        let barSpacing: CGFloat = 5
        let maxBarHeight: CGFloat = max(chartView.frame.height - 40, 1) // Leave space for labels, ensure positive height
        
        // Create time range labels on the left side within chart boundaries
        let gridLines = 4
        let gridSpacing = maxBarHeight / CGFloat(gridLines)
        let labelWidth: CGFloat = 35 // Width for the time labels
        
        for i in 0...gridLines {
            let yPosition = chartView.frame.height - 30 - (CGFloat(i) * gridSpacing)
            
            // Add time label first
            let timeValue = Int(Double(i) * maxUsage / Double(gridLines) / 60) // In minutes
            
            let timeLabel = UILabel()
            timeLabel.translatesAutoresizingMaskIntoConstraints = false
            timeLabel.text = "\(timeValue)m"
            timeLabel.font = UIFont.systemFont(ofSize: 10)
            timeLabel.textColor = .secondaryLabel
            timeLabel.textAlignment = .right
            chartView.addSubview(timeLabel)
            
            NSLayoutConstraint.activate([
                timeLabel.leadingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: 0),
                timeLabel.widthAnchor.constraint(equalToConstant: max(labelWidth, 10)), // Ensure positive width
                timeLabel.centerYAnchor.constraint(equalTo: chartView.topAnchor, constant: yPosition)
            ])
            
            timeRangeLabels.append(timeLabel)
            
            // Then add the grid line starting after the label
            let line = UIView()
            line.translatesAutoresizingMaskIntoConstraints = false
            line.backgroundColor = .systemGray6
            chartView.addSubview(line)
            
            NSLayoutConstraint.activate([
                line.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 5),
                line.trailingAnchor.constraint(equalTo: chartView.trailingAnchor, constant: 0),
                line.centerYAnchor.constraint(equalTo: chartView.topAnchor, constant: yPosition),
                line.heightAnchor.constraint(equalToConstant: 1)
            ])
            
            // Set a minimum width to avoid negative width constraints
            let minWidthConstraint = line.widthAnchor.constraint(greaterThanOrEqualToConstant: 1)
            minWidthConstraint.priority = .required
            minWidthConstraint.isActive = true
        }
        
        // Create data point bars
        // Calculate space needed for all bars
        let totalBarsWidth = CGFloat(dataPoints.count) * (barWidth - barSpacing) // Width of all bars
        let totalSpacingWidth = CGFloat(dataPoints.count + 1) * barSpacing // Include spacing before first and after last bar
        let totalWidthNeeded = totalBarsWidth + totalSpacingWidth
        
        // Calculate true available width (accounting for time labels)
        let labelAreaWidth: CGFloat = 40 // Width reserved for time labels on the left
        let trueAvailableWidth = chartView.frame.width - labelAreaWidth
        
        // Calculate left margin to center the bars in the available space
        let leftMargin = labelAreaWidth + (trueAvailableWidth - totalWidthNeeded) / 2
        
        for (index, dataPoint) in dataPoints.enumerated() {
            // Scale bar height based on the maximum usage
            let barHeight = maxUsage > 0 ? (dataPoint.usage / maxUsage) * maxBarHeight : 0
            
            // Create bar
            let bar = UIView()
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.backgroundColor = getBarColor(for: dataPoint.usage)
            bar.layer.cornerRadius = 4
            chartView.addSubview(bar)
            
            // Calculate position for this bar
            let xPosition = leftMargin + barSpacing + CGFloat(index) * (barWidth)
            
            NSLayoutConstraint.activate([
                bar.leadingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: xPosition),
                bar.widthAnchor.constraint(equalToConstant: max(barWidth - barSpacing, 1)), // Ensure positive width
                bar.heightAnchor.constraint(equalToConstant: max(barHeight, 1)), // At least 1 point high for visibility
                bar.bottomAnchor.constraint(equalTo: chartView.bottomAnchor, constant: -30)
            ])
            
            graphBars.append(bar)
            
            // Create date label
            let dateLabel = UILabel()
            dateLabel.translatesAutoresizingMaskIntoConstraints = false
            dateLabel.text = labels[index]
            dateLabel.font = UIFont.systemFont(ofSize: 10)
            dateLabel.textColor = .secondaryLabel
            dateLabel.textAlignment = .center
            chartView.addSubview(dateLabel)
            
            NSLayoutConstraint.activate([
                dateLabel.centerXAnchor.constraint(equalTo: bar.centerXAnchor),
                dateLabel.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 4),
                dateLabel.widthAnchor.constraint(equalToConstant: max(barWidth, 10)) // Ensure positive width
            ])
            
            graphLabels.append(dateLabel)
        }
    }
    
    private func getDatesForPeriod(_ period: Period) -> ([Date], [String]) {
        var calendar = Calendar.current
        // Set first day of week to Sunday
        calendar.firstWeekday = 1
        let today = Date()
        var dates: [Date] = []
        var labels: [String] = []
        
        switch period {
        case .week:
            // Get the most recent Sunday
            var daysSinceSunday = calendar.component(.weekday, from: today) - 1
            if daysSinceSunday == 0 { daysSinceSunday = 7 } // If today is Sunday, go back a week
            
            // Create dates from Sunday to Saturday
            for i in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: i - daysSinceSunday, to: today) {
                    dates.append(date)
                    
                    // Format label - use day of week
                    let formatter = DateFormatter()
                    formatter.dateFormat = "E"
                    labels.append(formatter.string(from: date))
                }
            }
            
        case .month:
            // Last 30 days, show every 3rd day
            for i in stride(from: 0, to: 30, by: 3).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    dates.append(date)
                    
                    // Format label - use day of month
                    let formatter = DateFormatter()
                    formatter.dateFormat = "d"
                    labels.append(formatter.string(from: date))
                }
            }
            
        case .threeMonths:
            // Last 90 days, show every week
            for i in stride(from: 0, to: 90, by: 7).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    dates.append(date)
                    
                    // Format label - use month/day format
                    let formatter = DateFormatter()
                    formatter.dateFormat = "M/d"
                    labels.append(formatter.string(from: date))
                }
            }
        }
        
        return (dates, labels)
    }
    
    private func getBarColor(for usage: TimeInterval) -> UIColor {
        // Color based on usage amount - green for low, yellow for medium, red for high
        let thresholds: [TimeInterval: UIColor] = [
            3600: .systemRed,           // More than 1 hour
            1800: .systemOrange,        // 30 min to 1 hour
            0: .systemGreen             // Less than 30 min
        ]
        
        for (threshold, color) in thresholds.sorted(by: { $0.key > $1.key }) {
            if usage >= threshold {
                return color
            }
        }
        
        return .systemGreen
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !graphBars.isEmpty {
            updateChart() // Redraw when size changes
        }
    }
}
