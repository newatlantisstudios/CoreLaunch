//
//  HomeViewController.swift
//  CoreLaunch
//
//  Created by x on 4/2/25.
//

import UIKit

class HomeViewController: UIViewController, SettingsDelegate, BreathingRoomDelegate {
    static var appCache: [String: AppItem] = [:]
    
    // MARK: - Properties
    private let tableView = UITableView()
    private var allApps: [AppItem] = []
    private var displayedApps: [AppItem] = []
    private let dateLabel = UILabel()
    private let timeLabel = UILabel()
    private let motivationalLabel = UILabel() // New label for motivational messages
    private let settingsButton = UIButton(type: .system)
    private let usageStatsButton = UIButton(type: .system)
    private let focusModeButton = UIButton(type: .system)
    internal let achievementsButton = UIButton(type: .system)
    
    // Focus mode
    private let focusManager = FocusModeManager.shared
    
    // Settings
    private var use24HourTime = false
    private var showDate = true
    private var useMinimalistStyle = true
    private var useMonochromeIcons = false
    private var showMotivationalMessages: Bool = true
    private var textSizeMultiplier: Float = 1.0
    private var fontName: String = "System"
    
    // Theme
    private var currentTheme: ColorTheme = ThemeManager.shared.currentTheme
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSettings()
        setupUI()
        configureTableView()
        loadApps()
        startTimeUpdates()
        checkForPendingAppSessions()
        setupAchievementsButton()
        
        // Register for application activation notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSNotification.Name("ApplicationDidBecomeActiveNotification"),
            object: nil
        )
        
        // Register for theme change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: NSNotification.Name("ThemeDidChangeNotification"),
            object: nil
        )
        
        // No need for appearance change notifications here
        // We already handle trait changes in traitCollectionDidChange method
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG: HomeViewController viewWillAppear called")
        
        // Force reload colors from UserDefaults every time
        // Use a slight delay to ensure the transition animation doesn't interfere
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("DEBUG: Delayed reload of apps data from UserDefaults")
            self.loadAppsFromUserDefaults(forceRefresh: true)
            self.tableView.reloadData()
        }
        
        // Explicitly apply theme background
        view.backgroundColor = ThemeManager.shared.currentTheme.backgroundColor
        
        // If it's Light theme, force white background
        if ThemeManager.shared.currentTheme.name == "Light" {
            view.backgroundColor = .white
        }
        
        // Update UI if needed
        updateAppearance()
        
        // Always check for pending sessions when returning to the app
        checkForPendingAppSessions()
        
        // Update achievement notification badge
        updateAchievementNotification()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Call our user interface style change handler when the trait collection changes
        userInterfaceStyleDidChange()
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
        
        // Motivational message display
        motivationalLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        motivationalLabel.textAlignment = .center
        motivationalLabel.textColor = .secondaryLabel
        motivationalLabel.numberOfLines = 0
        motivationalLabel.isHidden = !showMotivationalMessages
        motivationalLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(motivationalLabel)
        displayRandomMotivationalMessage()
        
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
            
            motivationalLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 12),
            motivationalLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            motivationalLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            motivationalLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
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
            
            tableView.topAnchor.constraint(equalTo: motivationalLabel.bottomAnchor, constant: 20),
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
        
        // Ensure table view background matches theme
        if ThemeManager.shared.currentTheme.name == "Light" {
            tableView.backgroundColor = .white
        } else {
            tableView.backgroundColor = ThemeManager.shared.currentTheme.backgroundColor
        }
    }
    
    private func updateAppearance() {
        // Update UI based on dark/light mode, minimalist settings, and theme
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        // Determine base sizes adjusted by multiplier
        let timeFontSize = CGFloat(useMinimalistStyle ? 48 : 36) * CGFloat(textSizeMultiplier)
        let dateFontSize = CGFloat(useMinimalistStyle ? 16 : 14) * CGFloat(textSizeMultiplier)
        let motivationalFontSize = CGFloat(14) * CGFloat(textSizeMultiplier)
        
        // Apply theme colors directly without any dark mode overrides
        view.backgroundColor = currentTheme.backgroundColor
        
        // Debug print
        print("HomeVC updateAppearance - Current theme: \(currentTheme.name), timeLabel color: \(timeLabel.textColor.debugDescription)")
        
        // Force time label to be visible regardless of theme
        timeLabel.isHidden = false
        
        // Special case for Light theme - force white background
        if currentTheme.name == "Light" {
            view.backgroundColor = .white
            tableView.backgroundColor = .white
            print("Light theme detected - forcing white background")
        } else if currentTheme.name == "Monochrome" {
            view.backgroundColor = .white
            tableView.backgroundColor = .white
            timeLabel.textColor = .black // Force time label to be black
            dateLabel.textColor = .darkGray
            motivationalLabel.textColor = .darkGray
            print("Monochrome theme detected - applying explicit settings")
        }
        
        // Force white text in dark themes
        if currentTheme.name == "Dark" || currentTheme.name == "Midnight" || 
           (currentTheme.name == "Auto Light and Dark" && traitCollection.userInterfaceStyle == .dark) {
            timeLabel.textColor = .white
            dateLabel.textColor = .lightGray
            motivationalLabel.textColor = .lightGray
        } else if currentTheme.name == "Monochrome" {
            // Explicitly set text colors for monochrome theme
            timeLabel.textColor = .black
            dateLabel.textColor = .darkGray
            motivationalLabel.textColor = .darkGray
        } else {
            timeLabel.textColor = currentTheme.textColor
            dateLabel.textColor = currentTheme.secondaryTextColor
            motivationalLabel.textColor = currentTheme.secondaryTextColor
        }
        
        // Apply button colors
        if currentTheme.name == "Dark" || currentTheme.name == "Midnight" || 
           (currentTheme.name == "Auto Light and Dark" && traitCollection.userInterfaceStyle == .dark) {
            settingsButton.tintColor = .white
            usageStatsButton.tintColor = .white
            focusModeButton.tintColor = .white
        } else if currentTheme.name == "Monochrome" {
            // Monochrome-specific button colors
            settingsButton.tintColor = .black
            usageStatsButton.tintColor = .darkGray
            focusModeButton.tintColor = .gray
        } else {
            settingsButton.tintColor = currentTheme.accentColor
            usageStatsButton.tintColor = currentTheme.primaryColor
            focusModeButton.tintColor = currentTheme.secondaryColor
        }
        
        // Apply font settings
        if useMinimalistStyle {
            tableView.separatorStyle = .none
            
            // Set fonts based on user preference
            if fontName == "System" {
                timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeFontSize, weight: .light)
                dateLabel.font = UIFont.systemFont(ofSize: dateFontSize, weight: .regular)
                motivationalLabel.font = UIFont.systemFont(ofSize: motivationalFontSize, weight: .light)
            } else {
                timeLabel.font = UIFont(name: fontName, size: timeFontSize) ?? UIFont.monospacedDigitSystemFont(ofSize: timeFontSize, weight: .light)
                dateLabel.font = UIFont(name: fontName, size: dateFontSize) ?? UIFont.systemFont(ofSize: dateFontSize, weight: .regular)
                motivationalLabel.font = UIFont(name: fontName, size: motivationalFontSize) ?? UIFont.systemFont(ofSize: motivationalFontSize, weight: .light)
            }
        } else {
            tableView.separatorStyle = .singleLine
            
            // Set fonts based on user preference
            if fontName == "System" {
                timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeFontSize, weight: .regular)
                dateLabel.font = UIFont.systemFont(ofSize: dateFontSize, weight: .medium)
                motivationalLabel.font = UIFont.systemFont(ofSize: motivationalFontSize, weight: .regular)
            } else {
                timeLabel.font = UIFont(name: fontName, size: timeFontSize) ?? UIFont.monospacedDigitSystemFont(ofSize: timeFontSize, weight: .regular)
                dateLabel.font = UIFont(name: fontName, size: dateFontSize) ?? UIFont.systemFont(ofSize: dateFontSize, weight: .medium)
                motivationalLabel.font = UIFont(name: fontName, size: motivationalFontSize) ?? UIFont.systemFont(ofSize: motivationalFontSize, weight: .regular)
            }
        }
        
        // Update visibility based on settings
        dateLabel.isHidden = !showDate
        motivationalLabel.isHidden = !showMotivationalMessages
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
        let hasAppData = UserDefaults.standard.data(forKey: "savedApps") != nil
        
        if hasAppData {
            // Load apps from UserDefaults
            loadAppsFromUserDefaults()
        } else {
            allApps = defaultApps
            saveAppsToUserDefaults()
        }
    }
    
    private func updateDisplayedApps() {
        // Only show selected apps
        displayedApps = allApps.filter { $0.isSelected }
    }
    
    private func saveAppsToUserDefaults() {
        // Log before saving
        print("DEBUG: Saving \(allApps.count) apps to UserDefaults")
        for app in allApps {
            print("DEBUG: Saving app \(app.name) with color \(app.color)")
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(allApps)
            UserDefaults.standard.set(data, forKey: "savedApps")
            UserDefaults.standard.synchronize() // Force immediate write
            print("DEBUG: Successfully saved apps to UserDefaults and synchronized")
        } catch {
            print("Failed to save apps: \(error)")
        }
    }
    
    private func loadAppsFromUserDefaults(forceRefresh: Bool = false) {
        print("DEBUG: Loading apps from UserDefaults with forceRefresh: \(forceRefresh)")
        
        // Clear cached data if forcing refresh
        if forceRefresh {
            HomeViewController.appCache.removeAll()
        }
        
        guard let data = UserDefaults.standard.data(forKey: "savedApps") else {
            print("DEBUG: No app data found in UserDefaults")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            allApps = try decoder.decode([AppItem].self, from: data)
            print("DEBUG: Successfully loaded \(allApps.count) apps from UserDefaults")
            
            // Update cache
            for app in allApps {
                HomeViewController.appCache[app.name] = app
                print("DEBUG: Updated cache for app \(app.name) with color \(app.color)")
            }
            
            // Filter for display
            updateDisplayedApps()
            
            // Force refresh table view
            tableView.reloadData()
        } catch {
            print("Failed to load apps: \(error)")
        }
    }
    
    // MARK: - Time Management
    private func startTimeUpdates() {
        updateTimeAndDate()
        
        // Update time every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTimeAndDate()
        }
        
        // Update motivational message periodically (every 2 hours)
        Timer.scheduledTimer(withTimeInterval: 7200, repeats: true) { [weak self] _ in
            self?.displayRandomMotivationalMessage()
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
            defaults.set(true, forKey: "showMotivationalMessages")
            defaults.set(1.0, forKey: "textSizeMultiplier")
            defaults.set("System", forKey: "fontName")
            defaults.set(true, forKey: "defaultsInitialized")
            
            // For new installs, set the theme based on system appearance
            let isDarkMode = traitCollection.userInterfaceStyle == .dark
            defaults.set(try? JSONEncoder().encode(isDarkMode ? ColorTheme.darkTheme : ColorTheme.defaultTheme), 
                        forKey: "selectedTheme")
        }
        
        // Load saved settings
        use24HourTime = defaults.bool(forKey: "use24HourTime")
        showDate = defaults.bool(forKey: "showDate")
        useMinimalistStyle = defaults.bool(forKey: "useMinimalistStyle")
        useMonochromeIcons = defaults.bool(forKey: "useMonochromeIcons")
        showMotivationalMessages = defaults.bool(forKey: "showMotivationalMessages")
        
        // Load text settings
        textSizeMultiplier = defaults.float(forKey: "textSizeMultiplier")
        if textSizeMultiplier == 0 { textSizeMultiplier = 1.0 } // Handle default case
        
        if let savedFontName = defaults.string(forKey: "fontName") {
            fontName = savedFontName
        }
        
        // Load theme
        currentTheme = ThemeManager.shared.currentTheme
    }
    
    @objc private func settingsButtonTapped() {
        // Create and present the settings view
        let settingsVC = SettingsViewController()
        settingsVC.delegate = self
        settingsVC.modalPresentationStyle = .pageSheet
        settingsVC.modalTransitionStyle = .coverVertical
        
        // On larger devices (iPad), we can use form sheet for a better experience
        if UIDevice.current.userInterfaceIdiom == .pad {
            settingsVC.modalPresentationStyle = .formSheet
        }
        
        present(settingsVC, animated: true)
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
    
    @objc private func userInterfaceStyleDidChange() {
        print("Interface style changed: \(traitCollection.userInterfaceStyle == .dark ? "dark" : "light")")
        
        // Reload theme if using Auto Light and Dark
        if currentTheme.name == "Auto Light and Dark" {
            // Re-fetch the theme to get updated colors based on new appearance
            currentTheme = ThemeManager.shared.currentTheme
        }
        
        // Update UI
        updateAppearance()
        tableView.reloadData()
    }
    
    @objc private func themeDidChange() {
        print("Theme changed notification received")
        
        // Refresh current theme
        currentTheme = ThemeManager.shared.currentTheme
        
        // Force time label to be visible with black text for Monochrome theme
        if currentTheme.name == "Monochrome" {
            timeLabel.isHidden = false
            timeLabel.textColor = .black
            dateLabel.textColor = .darkGray
            motivationalLabel.textColor = .darkGray
            print("Explicitly setting time label visibility and color for Monochrome theme")
        }
        
        // Special handling for Light theme
        if currentTheme.name == "Light" {
            view.backgroundColor = .white
            tableView.backgroundColor = .white
            print("Light theme applied - forcing white background")
            
            // Force white background on all visible cells
            for case let cell as AppCell in tableView.visibleCells {
                cell.backgroundColor = .white
                cell.contentView.backgroundColor = .white
            }
        } else {
            view.backgroundColor = currentTheme.backgroundColor
            tableView.backgroundColor = currentTheme.backgroundColor
        }
        
        // Update UI
        updateAppearance()
        tableView.reloadData()
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
            guard let self = self else { return }
            
            // Check if this app should have breathing room delay
            if BreathingRoomManager.shared.shouldDelayApp(app.name) {
                let delayDuration = BreathingRoomManager.shared.getDelayDuration(for: app.name)
                self.showBreathingRoom(for: app, duration: delayDuration)
            } else {
                // Launch app immediately without breathing room
                self.launchApp(app)
            }
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
            if UsageTracker.shared.recordAppClosedWithReinforcement(appName: appName) {
            // Check for achievements after usage
            self.checkAchievementsAfterAppUsage(appName: appName)
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
        displayRandomMotivationalMessage() // Refresh motivational message
        loadApps() // Reload apps to reflect any changes in selection
    }
    
    func didUpdateTheme() {
        currentTheme = ThemeManager.shared.currentTheme
        updateAppearance()
        tableView.reloadData()
    }
    
    func didUpdateAppSelections(_ updatedApps: [AppItem]) {
        print("DEBUG: didUpdateAppSelections called with \(updatedApps.count) apps")
        
        // Make sure each app's color is reflected in the log
        for app in updatedApps {
            print("DEBUG: Updated app \(app.name) with color \(app.color)")
        }
        
        // Update local apps array
        allApps = updatedApps
        
        // Force save to UserDefaults
        saveAppsToUserDefaults()
        
        // Update filter
        updateDisplayedApps()
        
        // Update app cache for future reference
        for app in updatedApps {
            HomeViewController.appCache[app.name] = app
            print("DEBUG: Updated app cache for \(app.name)")
        }
        
        // Animate table view updates for a better user experience
        UIView.transition(with: tableView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            print("DEBUG: Reloading tableView in didUpdateAppSelections")
            self.tableView.reloadData()
        }, completion: { _ in
            // Force a second refresh to ensure all cells have the latest colors
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("DEBUG: Performing secondary reload of tableView")
                self.tableView.reloadData()
            }
        })
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
    
    // MARK: - Breathing Room Methods
    
    private func showBreathingRoom(for app: AppItem, duration: TimeInterval) {
        let breathingVC = BreathingRoomViewController(appName: app.name, delayDuration: duration)
        breathingVC.delegate = self
        present(breathingVC, animated: true)
    }
    
    // Launch the app after any delays or confirmations
    private func launchApp(_ app: AppItem) {
        // Record app launch in usage statistics
        _ = UsageTracker.shared.recordAppLaunch(appName: app.name)
        
        // Log the launch
        print("Would launch: \(app.name)")
        
        // Show a reminder to return to CoreLaunch
        self.showReturnReminder(for: app)
        
        // In a real app, you would use URL schemes to launch apps
        // For example: UIApplication.shared.open(URL(string: "messages://")!)
    }
    
    // MARK: - Achievements
    
    private func checkAchievementsAfterAppUsage(appName: String) {
        // Get usage statistics for this app
        if let appUsage = UsageTracker.shared.getAppUsageStats(appName: appName) {
            // Check if user stayed under their daily limit
            let dailyLimit = UserDefaults.standard.double(forKey: "dailyScreenTimeLimit")
            if dailyLimit > 0 {
                AchievementManager.shared.checkDailyGoalAchievements(usageTime: appUsage.totalTimeToday, limit: dailyLimit)
            }
            
            // Check for weekly reduction achievements
            let weeklyReductionTarget = UserDefaults.standard.double(forKey: "weeklyReductionTarget")
            if weeklyReductionTarget > 0 {
                let currentReduction = UsageTracker.shared.calculateWeeklyReduction()
                AchievementManager.shared.checkWeeklyReductionAchievements(currentReduction: currentReduction, target: weeklyReductionTarget)
            }
            
            // Update UI to reflect any new achievements
            updateAchievementNotification()
        }
    }
    

    
    // MARK: - BreathingRoomDelegate
    
    func breathingRoomDidComplete(for appName: String) {
        // Find the app item by name
        if let app = allApps.first(where: { $0.name == appName }) {
            // Launch the app
            launchApp(app)
        }
    }
    
    func breathingRoomWasCancelled(for appName: String) {
        // User cancelled, don't launch the app
        print("Breathing room cancelled for \(appName)")
    }
}

// MARK: - Motivational Messages
extension HomeViewController {
    private func getMotivationalMessages() -> [String] {
        return [
            "Take a moment to disconnect digitally and reconnect with yourself.",
            "Balance is key: technology should enhance your life, not consume it.",
            "Small breaks from your device lead to big moments of clarity.",
            "Your attention is valuable. Spend it mindfully.",
            "Technology works best when it serves your well-being, not the other way around.",
            "Digital minimalism creates space for mental flourishing.",
            "Presence over pixels: be here now.",
            "The most important connections happen offline.",
            "Nurturing your digital well-being is an act of self-care.",
            "Your screen time is a reflection of your priorities.",
            "Quality engagement matters more than quantity of notifications.",
            "Mindful tech use leads to more meaningful moments.",
            "Use technology intentionally, not habitually.",
            "Your focus determines your reality.",
            "Make technology work for you, not against you.",
            "Each notification-free moment is a gift to your attention.",
            "Digital choices today shape your well-being tomorrow.",
            "True productivity comes from focused attention, not constant connection.",
            "Regular digital breaks refresh your mind and spirit.",
            "The best innovations enhance our humanity, not replace it."
        ]
    }
    
    private func displayRandomMotivationalMessage() {
        if showMotivationalMessages {
            let messages = getMotivationalMessages()
            motivationalLabel.text = messages[Int.random(in: 0..<messages.count)]
        } else {
            motivationalLabel.text = ""
        }
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
        
        // Ensure proper background for Light theme
        if ThemeManager.shared.currentTheme.name == "Light" {
            cell.backgroundColor = .white
            cell.contentView.backgroundColor = .white
        }
        
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
    private var useMonochromeIcons = false
    
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
        
        // Set background color based on theme
        let theme = ThemeManager.shared.currentTheme
        if theme.name == "Light" {
            contentView.backgroundColor = .white
            backgroundColor = .white
        } else {
            contentView.backgroundColor = theme.backgroundColor
            backgroundColor = theme.backgroundColor
        }
        
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
        
        // Debug print
        print("DEBUG: AppCell configuring app: \(app.name) with color: \(app.color)")
        
        // Always double-check the app cache for the latest color
        let appColor: UIColor
        if let cachedApp = HomeViewController.appCache[app.name] {
            appColor = cachedApp.color
            print("DEBUG: Using cached color for \(app.name): \(appColor)")
        } else {
            appColor = app.color
        }
        
        // Check UserDefaults for settings
        let useMinimalistStyle = UserDefaults.standard.bool(forKey: "useMinimalistStyle")
        self.useMonochromeIcons = UserDefaults.standard.bool(forKey: "useMonochromeIcons")
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let textSizeMultiplier = UserDefaults.standard.float(forKey: "textSizeMultiplier")
        let fontSizeMultiplier = textSizeMultiplier > 0 ? textSizeMultiplier : 1.0
        let fontName = UserDefaults.standard.string(forKey: "fontName") ?? "System"
        
        // Calculate font size with multiplier
        let fontSize = CGFloat(17) * CGFloat(fontSizeMultiplier)
        
        // Apply icon color based on settings
        let iconColor = useMonochromeIcons ? (isDarkMode ? UIColor.white : UIColor.black) : appColor
        print("DEBUG: Setting colorIndicator color to: \(iconColor)")
        
        // Use a slight animation for color change to avoid flicker
        UIView.transition(with: colorIndicator, duration: 0.05, options: .transitionCrossDissolve, animations: {
            self.colorIndicator.backgroundColor = iconColor
        }, completion: nil)
        
        // Get the current theme and explicitly apply colors
        let theme = ThemeManager.shared.currentTheme
        
        // Force white background for Light and Monochrome themes
        if theme.name == "Light" || theme.name == "Monochrome" {
            contentView.backgroundColor = .white
            backgroundColor = .white
            // Explicitly set text color for Monochrome theme
            if theme.name == "Monochrome" {
                nameLabel.textColor = .black
            }
        } else {
            contentView.backgroundColor = theme.backgroundColor
            backgroundColor = theme.backgroundColor
        }
        
        // Force white text in dark themes
        if theme.name == "Dark" || theme.name == "Midnight" || 
           (theme.name == "Auto Light and Dark" && traitCollection.userInterfaceStyle == .dark) {
            nameLabel.textColor = .white
        } else if theme.name == "Monochrome" {
            nameLabel.textColor = .black
        } else {
            nameLabel.textColor = theme.textColor
        }
        
        // Apply style based on settings
        if useMinimalistStyle {
            if fontName == "System" {
                nameLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .light)
            } else {
                nameLabel.font = UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .light)
            }
            selectionStyle = .none
        } else {
            if fontName == "System" {
                nameLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
            } else {
                nameLabel.font = UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .regular)
            }
            selectionStyle = .default
        }
        
        // Final check for Monochrome theme - ensure text is black
        if theme.name == "Monochrome" {
            nameLabel.textColor = .black
            print("AppCell: Force black text for Monochrome theme for app: \(app.name)")
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Get the app from the nameLabel text if possible
        if let name = nameLabel.text, let app = HomeViewController.appCache[name] {
            configure(with: app)
        }
        
        // Update colors based on current theme
        let theme = ThemeManager.shared.currentTheme
        
        // Force white background for Light theme
        if theme.name == "Light" {
            contentView.backgroundColor = .white
            backgroundColor = .white
            print("AppCell: Light theme applied in trait change")
        } else {
            contentView.backgroundColor = theme.backgroundColor
            backgroundColor = theme.backgroundColor
        }
        
        // Force white text in dark themes
        if theme.name == "Dark" || theme.name == "Midnight" || 
           (theme.name == "Auto Light and Dark" && traitCollection.userInterfaceStyle == .dark) {
            nameLabel.textColor = .white
        } else if theme.name == "Monochrome" {
            nameLabel.textColor = .black
            // Special handling for monochrome icon colors
            if !useMonochromeIcons {
                colorIndicator.backgroundColor = .darkGray
            }
        } else {
            nameLabel.textColor = theme.textColor
        }
    }
}
