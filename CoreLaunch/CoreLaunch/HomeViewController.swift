//
//  HomeViewController.swift
//  CoreLaunch
//
//  Created by x on 4/2/25.
//

import UIKit

// No need to import CoreLaunch as we're already in the module

class HomeViewController: UIViewController, SettingsDelegate {
    static var appCache: [String: AppItem] = [:]
    
    // MARK: - Properties
    private let tableView = UITableView()
    private var allApps: [AppItem] = []
    private var displayedApps: [AppItem] = []
    private let dateLabel = UILabel()
    private let timeLabel = UILabel()
    private let settingsButton = UIButton(type: .system)
    private let usageStatsButton = UIButton(type: .system)
    private let focusModeButton = UIButton(type: .system)
    
    // Focus mode
    private let focusManager = FocusModeManager.shared
    
    // Settings
    private var use24HourTime = false
    private var showDate = true
    private var useMinimalistStyle = true
    private var useMonochromeIcons = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSettings()
        setupUI()
        configureTableView()
        loadApps()
        startTimeUpdates()
        checkForPendingAppSessions()
        
        // Register for application activation notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSNotification.Name("ApplicationDidBecomeActiveNotification"),
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("HomeViewController viewWillAppear - checking for sessions")
        // Update UI if needed
        updateAppearance()
        // Always check for pending sessions when returning to the app
        checkForPendingAppSessions()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateAppearance()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Time display
        timeLabel.font = useMinimalistStyle ? 
            UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .light) :
            UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .regular)
        timeLabel.textAlignment = .center
        timeLabel.textColor = .label
        view.addSubview(timeLabel)
        
        // Date display
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        dateLabel.textAlignment = .center
        dateLabel.textColor = .secondaryLabel
        dateLabel.isHidden = !showDate
        view.addSubview(dateLabel)
        
        // Settings button
        settingsButton.setImage(UIImage(systemName: "gear"), for: .normal)
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(settingsButton)
        
        // Usage stats button
        usageStatsButton.setImage(UIImage(systemName: "chart.line.downtrend.xyaxis"), for: .normal)
        usageStatsButton.addTarget(self, action: #selector(usageStatsButtonTapped), for: .touchUpInside)
        usageStatsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(usageStatsButton)
        
        // Focus mode button
        focusModeButton.setImage(UIImage(systemName: "timer"), for: .normal)
        focusModeButton.addTarget(self, action: #selector(focusModeButtonTapped), for: .touchUpInside)
        focusModeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(focusModeButton)
        
        // Table view for apps
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        setupConstraints()
        updateAppearance()
    }
    
    private func setupConstraints() {
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            dateLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
            dateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),
            
            usageStatsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            usageStatsButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -12),
            usageStatsButton.widthAnchor.constraint(equalToConstant: 44),
            usageStatsButton.heightAnchor.constraint(equalToConstant: 44),
            
            focusModeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            focusModeButton.trailingAnchor.constraint(equalTo: usageStatsButton.leadingAnchor, constant: -12),
            focusModeButton.widthAnchor.constraint(equalToConstant: 44),
            focusModeButton.heightAnchor.constraint(equalToConstant: 44),
            
            tableView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 40),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AppCell.self, forCellReuseIdentifier: AppCell.identifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
    }
    
    private func updateAppearance() {
        // Update UI based on dark/light mode and minimalist settings
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        if useMinimalistStyle {
            view.backgroundColor = isDarkMode ? .black : .white
            tableView.separatorStyle = .none
            
            // More minimal style
            timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .light)
            dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        } else {
            view.backgroundColor = isDarkMode ? .systemBackground : .systemBackground
            tableView.separatorStyle = .singleLine
            
            // Less minimal style
            timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .regular)
            dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        }
        
        // Update visibility based on settings
        dateLabel.isHidden = !showDate
    }
    
    // MARK: - Data
    private func loadApps() {
        // Define all available apps
        let defaultApps = [
            AppItem(name: "Messages", color: .systemBlue),
            AppItem(name: "Phone", color: .systemGreen),
            AppItem(name: "Mail", color: .systemIndigo),
            AppItem(name: "Internet", color: .systemOrange),
            AppItem(name: "Notes", color: .systemYellow),
            AppItem(name: "Calendar", color: .systemRed),
            AppItem(name: "Photos", color: .systemPurple),
            AppItem(name: "Settings", color: .systemGray)
        ]
        
        // Check if we have saved apps data
        if let savedApps = loadAppsFromUserDefaults() {
            allApps = savedApps
        } else {
            allApps = defaultApps
            saveAppsToUserDefaults()
        }
        
        // Filter for display
        updateDisplayedApps()
        
        // Populate the static app cache for use in dark/light mode transitions
        for app in allApps {
            HomeViewController.appCache[app.name] = app
        }
        
        tableView.reloadData()
    }
    
    private func updateDisplayedApps() {
        // Only show selected apps
        displayedApps = allApps.filter { $0.isSelected }
    }
    
    private func saveAppsToUserDefaults() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(allApps)
            UserDefaults.standard.set(data, forKey: "savedApps")
        } catch {
            print("Failed to save apps: \(error)")
        }
    }
    
    private func loadAppsFromUserDefaults() -> [AppItem]? {
        guard let data = UserDefaults.standard.data(forKey: "savedApps") else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([AppItem].self, from: data)
        } catch {
            print("Failed to load apps: \(error)")
            return nil
        }
    }
    
    // MARK: - Time Management
    private func startTimeUpdates() {
        updateTimeAndDate()
        
        // Update time every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTimeAndDate()
        }
    }
    
    private func updateTimeAndDate() {
        let dateFormatter = DateFormatter()
        let now = Date()
        
        // Time format (24-hour or 12-hour based on settings)
        dateFormatter.dateFormat = use24HourTime ? "HH:mm" : "h:mm a"
        timeLabel.text = dateFormatter.string(from: now)
        
        // Date format (Day, Month Day)
        dateFormatter.dateFormat = "EEEE, MMMM d"
        dateLabel.text = dateFormatter.string(from: now)
    }
    
    // MARK: - Settings
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Check if defaults exist, if not, set initial values
        if !defaults.bool(forKey: "defaultsInitialized") {
            defaults.set(false, forKey: "use24HourTime")
            defaults.set(true, forKey: "showDate")
            defaults.set(true, forKey: "useMinimalistStyle")
            defaults.set(false, forKey: "useMonochromeIcons")
            defaults.set(true, forKey: "defaultsInitialized")
        }
        
        // Load saved settings
        use24HourTime = defaults.bool(forKey: "use24HourTime")
        showDate = defaults.bool(forKey: "showDate")
        useMinimalistStyle = defaults.bool(forKey: "useMinimalistStyle")
        useMonochromeIcons = defaults.bool(forKey: "useMonochromeIcons")
    }
    
    @objc private func settingsButtonTapped() {
        let settingsVC = SettingsViewController()
        settingsVC.delegate = self
        let navController = UINavigationController(rootViewController: settingsVC)
        present(navController, animated: true)
    }
    
    @objc private func usageStatsButtonTapped() {
        let usageStatsVC = UsageStatsViewController()
        let navController = UINavigationController(rootViewController: usageStatsVC)
        present(navController, animated: true)
    }
    
    @objc private func focusModeButtonTapped() {
        let focusModeVC = FocusModeViewController()
        let navController = UINavigationController(rootViewController: focusModeVC)
        present(navController, animated: true)
    }
    
    // MARK: - App Lifecycle
    
    @objc private func applicationDidBecomeActive() {
        print("Application did become active notification received")
        checkForPendingAppSessions()
    }
    
    // MARK: - App Launch Tracking
    
    private func showAppLaunchConfirmation(for app: AppItem) {
        // Check if this app is blocked by focus mode
        if focusManager.isAppBlocked(app.name) {
            showFocusModeBlockAlert(for: app)
            return
        }
        
        let alert = UIAlertController(
            title: "Launch \(app.name)",
            message: "Would you like to open \(app.name)? CoreLaunch will track your usage time.",
            preferredStyle: .alert
        )
        
        let launchAction = UIAlertAction(title: "Open", style: .default) { [weak self] _ in
            // Record app launch in usage statistics
            _ = UsageTracker.shared.recordAppLaunch(appName: app.name)
            
            // Log the launch
            print("Would launch: \(app.name)")
            
            // Show a reminder to return to CoreLaunch
            self?.showReturnReminder(for: app)
            
            // In a real app, you would use URL schemes to launch apps
            // For example: UIApplication.shared.open(URL(string: "messages://")!)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(launchAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func showReturnReminder(for app: AppItem) {
        let reminder = UIAlertController(
            title: "Remember to Return",
            message: "Please return to CoreLaunch when you're done using \(app.name) to complete your usage tracking.",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default)
        reminder.addAction(okAction)
        
        present(reminder, animated: true)
    }
    
    private func checkForPendingAppSessions() {
        print("Checking for pending app sessions...")
        let (hasSession, appName, startTime) = UsageTracker.shared.hasPendingAppSession()
        
        print("Has pending session: \(hasSession), App: \(appName ?? "none"), Time: \(startTime?.description ?? "none")")
        
        guard hasSession, let appName = appName, let startTime = startTime else { return }
        
        // Calculate how long the app has been open
        let timeInterval = Date().timeIntervalSince(startTime)
        let minutes = Int(timeInterval / 60)
        let timeString = minutes > 0 ? "\(minutes) minutes" : "just now"
        
        // Show session completion alert
        let alert = UIAlertController(
            title: "Finish Using \(appName)?",
            message: "You started using \(appName) \(timeString) ago. Are you finished with it now?",
            preferredStyle: .alert
        )
        
        let finishedAction = UIAlertAction(title: "Yes, I'm Done", style: .default) { _ in
            // Record app closing in usage statistics
            if UsageTracker.shared.recordAppClosed(appName: appName) {
                // Generate weekly summary periodically
                UsageTracker.shared.generateWeeklySummary()
            }
        }
        
        let stillUsingAction = UIAlertAction(title: "No, Still Using It", style: .cancel)
        
        alert.addAction(finishedAction)
        alert.addAction(stillUsingAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - SettingsDelegate
    func didUpdateSettings() {
        loadSettings()
        updateAppearance()
        updateTimeAndDate()
        loadApps() // Reload apps to reflect any changes in selection
    }
    
    func didUpdateAppSelections(_ updatedApps: [AppItem]) {
        allApps = updatedApps
        saveAppsToUserDefaults()
        updateDisplayedApps()
        
        // Animate table view updates for a better user experience
        UIView.transition(with: tableView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.tableView.reloadData()
        }, completion: nil)
    }
    
    // MARK: - Focus Mode
    
    private func showFocusModeBlockAlert(for app: AppItem) {
        guard let activeSession = focusManager.activeFocusSession else { return }
        
        let alert = UIAlertController(
            title: "App Blocked by Focus Mode",
            message: "\(app.name) is currently blocked by Focus Mode. Your focus session will end in \(activeSession.formattedRemainingTime).",
            preferredStyle: .alert
        )
        
        let endFocusAction = UIAlertAction(title: "End Focus Session", style: .destructive) { [weak self] _ in
            // End the focus session
            self?.focusManager.endFocusSession(completed: false)
            
            // Now show the regular app launch confirmation
            self?.showAppLaunchConfirmation(for: app)
        }
        
        let cancelAction = UIAlertAction(title: "Stay Focused", style: .cancel)
        
        alert.addAction(endFocusAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}

// MARK: - TableView DataSource & Delegate
extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedApps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AppCell.identifier, for: indexPath) as? AppCell else {
            return UITableViewCell()
        }
        
        let app = displayedApps[indexPath.row]
        cell.configure(with: app)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Get the selected app
        let app = displayedApps[indexPath.row]
        
        // Show app launch confirmation alert
        showAppLaunchConfirmation(for: app)
    }
}

// Refer to AppItem struct now defined in SettingsViewController.swift

// MARK: - TableView Cell
class AppCell: UITableViewCell {
    static let identifier = "AppCell"
    
    private let nameLabel = UILabel()
    private let colorIndicator = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .default
        
        // Color indicator
        colorIndicator.translatesAutoresizingMaskIntoConstraints = false
        colorIndicator.layer.cornerRadius = 6
        contentView.addSubview(colorIndicator)
        
        // App name label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        nameLabel.textColor = .label
        contentView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            colorIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            colorIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorIndicator.widthAnchor.constraint(equalToConstant: 12),
            colorIndicator.heightAnchor.constraint(equalToConstant: 12),
            
            nameLabel.leadingAnchor.constraint(equalTo: colorIndicator.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with app: AppItem) {
        nameLabel.text = app.name
        
        // Check UserDefaults for settings
        let useMinimalistStyle = UserDefaults.standard.bool(forKey: "useMinimalistStyle")
        let useMonochromeIcons = UserDefaults.standard.bool(forKey: "useMonochromeIcons")
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Apply icon color based on settings
        colorIndicator.backgroundColor = app.getIconColor(useMonochrome: useMonochromeIcons, isDarkMode: isDarkMode)
        
        // Apply style based on settings
        if useMinimalistStyle {
            nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .light)
            selectionStyle = .none
        } else {
            nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            selectionStyle = .default
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Get the app from the nameLabel text if possible
        if let name = nameLabel.text, let app = HomeViewController.appCache[name] {
            configure(with: app)
        }
        
        // Always update text color based on dark/light mode
        nameLabel.textColor = .label
    }
}
