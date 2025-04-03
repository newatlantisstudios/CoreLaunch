//
//  CalendarView.swift
//  CoreLaunch
//
//  Created on 4/2/25.
//

import UIKit

protocol CalendarViewDelegate: AnyObject {
    func didSelectDate(_ date: Date)
}

class CalendarView: UIView {
    // MARK: - Properties
    private let collectionView: UICollectionView
    private let monthLabel = UILabel()
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    
    private let calendar = Calendar.current
    private var baseDate: Date
    private var days: [Day] = []
    private var selectedDate: Date?
    private var usageDays: Set<String> = [] // Stores dates with usage data
    
    weak var delegate: CalendarViewDelegate?
    
    // MARK: - Initialization
    init(frame: CGRect, baseDate: Date) {
        self.baseDate = baseDate
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(frame: frame)
        
        setupView()
        setDate(baseDate)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView() {
        // Configure header view
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerView)
        
        // Month label
        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        monthLabel.textAlignment = .center
        monthLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        headerView.addSubview(monthLabel)
        
        // Previous month button
        prevButton.translatesAutoresizingMaskIntoConstraints = false
        prevButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        prevButton.addTarget(self, action: #selector(didTapPrevious), for: .touchUpInside)
        headerView.addSubview(prevButton)
        
        // Next month button
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
        headerView.addSubview(nextButton)
        
        // Weekday header
        let weekdayStackView = createWeekdayHeader()
        weekdayStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(weekdayStackView)
        
        // Collection view for days
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(DayCell.self, forCellWithReuseIdentifier: DayCell.reuseIdentifier)
        addSubview(collectionView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            prevButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            prevButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            prevButton.widthAnchor.constraint(equalToConstant: 44),
            prevButton.heightAnchor.constraint(equalToConstant: 44),
            
            nextButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            nextButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 44),
            nextButton.heightAnchor.constraint(equalToConstant: 44),
            
            monthLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            monthLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            monthLabel.leadingAnchor.constraint(equalTo: prevButton.trailingAnchor, constant: 8),
            monthLabel.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -8),
            
            weekdayStackView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            weekdayStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            weekdayStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            weekdayStackView.heightAnchor.constraint(equalToConstant: 30),
            
            collectionView.topAnchor.constraint(equalTo: weekdayStackView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func createWeekdayHeader() -> UIStackView {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        
        var weekdaySymbols = formatter.shortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        
        // Adjust the array to start from Sunday (or the first day of the week based on locale)
        let firstWeekday = calendar.firstWeekday
        if firstWeekday > 1 {
            let first = Array(weekdaySymbols.prefix(firstWeekday - 1))
            weekdaySymbols.removeFirst(firstWeekday - 1)
            weekdaySymbols.append(contentsOf: first)
        }
        
        for symbol in weekdaySymbols {
            let label = UILabel()
            label.text = symbol
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            stackView.addArrangedSubview(label)
        }
        
        return stackView
    }
    
    // MARK: - Actions
    @objc private func didTapPrevious() {
        guard let newDate = calendar.date(byAdding: .month, value: -1, to: baseDate) else { return }
        setDate(newDate)
    }
    
    @objc private func didTapNext() {
        guard let newDate = calendar.date(byAdding: .month, value: 1, to: baseDate) else { return }
        setDate(newDate)
    }
    
    // MARK: - Public Methods
    func setDate(_ date: Date) {
        baseDate = date
        selectedDate = date
        days = generateDaysInMonth(for: baseDate)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        monthLabel.text = formatter.string(from: baseDate)
        
        collectionView.reloadData()
        
        // Inform delegate of date selection
        delegate?.didSelectDate(date)
    }
    
    func markDatesWithUsageData(_ dates: [Date]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        usageDays = Set(dates.map { formatter.string(from: $0) })
        collectionView.reloadData()
    }
    
    // MARK: - Private Methods
    private func generateDaysInMonth(for date: Date) -> [Day] {
        var days = [Day]()
        
        let range = calendar.range(of: .day, in: .month, for: date)!
        let numDays = range.count
        
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // Add placeholder days for previous month
        let offsetInInitialRow = firstWeekday - calendar.firstWeekday
        if offsetInInitialRow > 0 {
            for _ in 1..<offsetInInitialRow + 1 {
                days.append(.empty)
            }
        }
        
        // Add days of current month
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for day in 1...numDays {
            let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)!
            let dateString = formatter.string(from: dayDate)
            let isToday = calendar.isDateInToday(dayDate)
            let hasUsage = usageDays.contains(dateString)
            
            days.append(.day(
                day: day,
                date: dayDate,
                isToday: isToday,
                isSelected: calendar.isDate(dayDate, inSameDayAs: selectedDate ?? Date()),
                hasUsage: hasUsage
            ))
        }
        
        return days
    }
}

// MARK: - UICollectionView Delegate & DataSource
extension CalendarView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DayCell.reuseIdentifier,
                for: indexPath) as? DayCell else {
            return UICollectionViewCell()
        }
        
        cell.day = days[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < days.count else { return }
        
        let day = days[indexPath.item]
        guard case .day(_, let date, _, _, _) = day else { return }
        
        // Update selection
        selectedDate = date
        days = generateDaysInMonth(for: baseDate)
        collectionView.reloadData()
        
        // Inform delegate of date selection
        delegate?.didSelectDate(date)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 7
        let height = collectionView.frame.height / 6
        return CGSize(width: width, height: height)
    }
}

// MARK: - Day Enum
enum Day {
    case day(day: Int, date: Date, isToday: Bool, isSelected: Bool, hasUsage: Bool)
    case empty
}

// MARK: - Day Cell
class DayCell: UICollectionViewCell {
    static let reuseIdentifier = "DayCell"
    
    private let dateLabel = UILabel()
    private let usageIndicator = UIView()
    
    var day: Day? {
        didSet {
            updateView()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // Date label setup
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.textAlignment = .center
        dateLabel.font = UIFont.systemFont(ofSize: 16)
        contentView.addSubview(dateLabel)
        
        // Usage indicator setup
        usageIndicator.translatesAutoresizingMaskIntoConstraints = false
        usageIndicator.layer.cornerRadius = 3
        usageIndicator.backgroundColor = .systemBlue
        usageIndicator.isHidden = true
        contentView.addSubview(usageIndicator)
        
        NSLayoutConstraint.activate([
            dateLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            usageIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            usageIndicator.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 2),
            usageIndicator.widthAnchor.constraint(equalToConstant: 6),
            usageIndicator.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    private func updateView() {
        guard let day = day else { return }
        
        switch day {
        case .day(let day, _, let isToday, let isSelected, let hasUsage):
            dateLabel.text = "\(day)"
            
            // Style for today
            if isToday {
                dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
                dateLabel.textColor = .systemBlue
            } else {
                dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
                dateLabel.textColor = .label
            }
            
            // Style for selected day
            if isSelected {
                contentView.backgroundColor = .systemGray5
                contentView.layer.cornerRadius = 20
            } else {
                contentView.backgroundColor = .clear
            }
            
            // Show usage indicator
            usageIndicator.isHidden = !hasUsage
            
        case .empty:
            dateLabel.text = ""
            usageIndicator.isHidden = true
            contentView.backgroundColor = .clear
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dateLabel.text = ""
        usageIndicator.isHidden = true
        contentView.backgroundColor = .clear
    }
}
