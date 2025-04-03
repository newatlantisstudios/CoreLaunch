//
//  FocusModeViewController.swift
//  CoreLaunch
//
//  Created on 4/2/25.
//

import UIKit

class FocusModeViewController: UIViewController {
    
    // MARK: - UI Elements
    private let statusView = UIView()
    private let statusTitleLabel = UILabel()
    private let statusDescriptionLabel = UILabel()
    private let timerLabel = UILabel()
    private let progressBar = UIProgressView(progressViewStyle: .bar)
    private let timerRingView = UIView()
    private let endFocusButton = UIButton(type: .system)
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let focusButton = UIButton(type: .system)
    
    // MARK: - Properties
    private let focusManager = FocusModeManager.shared
    private var distractingApps: [AppItem] = []
    private var allApps: [AppItem] = []
    private var timer: Timer?
    private var durationMinutes: Int = 25 // Default Pomodoro duration
    private let presetDurations = [("Quick Focus", 5), ("Pomodoro", 25), ("Long Session", 50)]
    private var selectedPresetIndex = 1 // Default to Pomodoro
    private let pomodoroBreakDuration = 5 // Break duration in minutes
    private var pomodoroCount = 0 // Track completed pomodoros
    private var isBreakTime = false // Track if currently on break
    private var scheduledDate: Date? // For scheduling focus sessions
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Focus Mode"
        view.backgroundColor = .systemBackground
        
        // Add history and stats buttons to navigation bar
        let historyButton = UIBarButtonItem(image: UIImage(systemName: "clock.arrow.circlepath"), style: .plain, target: self, action: #selector(showFocusHistory))
        let statsButton = UIBarButtonItem(image: UIImage(systemName: "chart.bar"), style: .plain, target: self, action: #selector(showFocusStats))
        navigationItem.rightBarButtonItems = [statsButton, historyButton]
        
        loadApps()
        setupUI()
        setupNotificationObservers()
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Status view
        setupStatusView()
        
        // Preset duration segment control
        let presetSegmentControl = UISegmentedControl(items: presetDurations.map { "\($0.0) (\($0.1)m)" })
        presetSegmentControl.selectedSegmentIndex = selectedPresetIndex
        presetSegmentControl.addTarget(self, action: #selector(presetDurationChanged(_:)), for: .valueChanged)
        presetSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        
        // Custom duration section
        let durationControl = UIStepper()
        durationControl.minimumValue = 5
        durationControl.maximumValue = 120
        durationControl.stepValue = 5
        durationControl.value = Double(durationMinutes)
        durationControl.addTarget(self, action: #selector(durationChanged(_:)), for: .valueChanged)
        
        let durationLabel = UILabel()
        durationLabel.textAlignment = .left
        durationLabel.font = UIFont.systemFont(ofSize: 16)
        durationLabel.text = "Custom Duration: \(durationMinutes) minutes"
        durationLabel.tag = 100 // Tag for easy update later
        
        // Button to schedule focus time
        let scheduleButton = UIButton(type: .system)
        scheduleButton.setTitle("Schedule for Later", for: .normal)
        scheduleButton.addTarget(self, action: #selector(scheduleButtonTapped), for: .touchUpInside)
        
        // Pomodoro mode toggle
        let pomodoroSwitch = UISwitch()
        pomodoroSwitch.isOn = false
        pomodoroSwitch.addTarget(self, action: #selector(pomodoroSwitchChanged(_:)), for: .valueChanged)
        
        let pomodoroLabel = UILabel()
        pomodoroLabel.text = "Pomodoro Mode"
        pomodoroLabel.font = UIFont.systemFont(ofSize: 16)
        
        let pomodoroStack = UIStackView(arrangedSubviews: [pomodoroLabel, pomodoroSwitch])
        pomodoroStack.axis = .horizontal
        pomodoroStack.spacing = 8
        pomodoroStack.distribution = .fill
        
        // Stack for duration controls
        let durationStack = UIStackView(arrangedSubviews: [durationLabel, durationControl])
        durationStack.axis = .horizontal
        durationStack.distribution = .fill
        durationStack.spacing = 16
        
        // Stack for scheduling/pomodoro options
        let optionsStack = UIStackView(arrangedSubviews: [scheduleButton, pomodoroStack])
        optionsStack.axis = .horizontal
        optionsStack.distribution = .equalSpacing
        optionsStack.spacing = 16
        
        // Outer stack for all controls
        let controlsStack = UIStackView(arrangedSubviews: [presetSegmentControl, durationStack, optionsStack])
        controlsStack.axis = .vertical
        controlsStack.spacing = 16
        controlsStack.alignment = .fill
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsStack)
        
        // Table view for app selection
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AppCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Focus button
        focusButton.setTitle("Start Focus Session", for: .normal)
        focusButton.setTitleColor(.white, for: .normal)
        focusButton.backgroundColor = .systemBlue
        focusButton.layer.cornerRadius = 10
        focusButton.translatesAutoresizingMaskIntoConstraints = false
        focusButton.addTarget(self, action: #selector(startFocusButtonTapped), for: .touchUpInside)
        view.addSubview(focusButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Status view at the top
            statusView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            statusView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Controls stack below status view
            controlsStack.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 20),
            controlsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            controlsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Table view taking remaining space
            tableView.topAnchor.constraint(equalTo: controlsStack.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: focusButton.topAnchor, constant: -16),
            
            // Focus button at the bottom
            focusButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            focusButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            focusButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            focusButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupStatusView() {
        statusView.backgroundColor = .secondarySystemBackground
        statusView.layer.cornerRadius = 12
        statusView.clipsToBounds = true
        statusView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusView)
        
        // Title label
        statusTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        statusTitleLabel.textAlignment = .left
        statusTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        statusView.addSubview(statusTitleLabel)
        
        // Description label
        statusDescriptionLabel.font = UIFont.systemFont(ofSize: 14)
        statusDescriptionLabel.textColor = .secondaryLabel
        statusDescriptionLabel.numberOfLines = 0
        statusDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        statusView.addSubview(statusDescriptionLabel)
        
        // Timer label
        // Timer ring view (will contain the circular progress indicator)
        timerRingView.translatesAutoresizingMaskIntoConstraints = false
        timerRingView.backgroundColor = .clear
        timerRingView.isHidden = true
        statusView.addSubview(timerRingView)
        
        // Timer label
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 34, weight: .medium)
        timerLabel.textAlignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.isHidden = true
        timerRingView.addSubview(timerLabel)
        
        // Progress bar
        progressBar.progressTintColor = .systemGreen
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.isHidden = true
        statusView.addSubview(progressBar)
        
        // End focus button
        endFocusButton.setTitle("End Focus Session", for: .normal)
        endFocusButton.setTitleColor(.systemRed, for: .normal)
        endFocusButton.backgroundColor = .systemGray6
        endFocusButton.layer.cornerRadius = 8
        endFocusButton.translatesAutoresizingMaskIntoConstraints = false
        endFocusButton.addTarget(self, action: #selector(endFocusButtonTapped), for: .touchUpInside)
        endFocusButton.isHidden = true
        statusView.addSubview(endFocusButton)
        
        // Layout
        NSLayoutConstraint.activate([
            // Title label
            statusTitleLabel.topAnchor.constraint(equalTo: statusView.topAnchor, constant: 16),
            statusTitleLabel.leadingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: 16),
            statusTitleLabel.trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: -16),
            
            // Description label
            statusDescriptionLabel.topAnchor.constraint(equalTo: statusTitleLabel.bottomAnchor, constant: 8),
            statusDescriptionLabel.leadingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: 16),
            statusDescriptionLabel.trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: -16),
            
            // Timer ring view
            timerRingView.topAnchor.constraint(equalTo: statusDescriptionLabel.bottomAnchor, constant: 16),
            timerRingView.centerXAnchor.constraint(equalTo: statusView.centerXAnchor),
            timerRingView.widthAnchor.constraint(equalToConstant: 140),
            timerRingView.heightAnchor.constraint(equalToConstant: 140),
            
            // Timer label inside ring view
            timerLabel.centerXAnchor.constraint(equalTo: timerRingView.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: timerRingView.centerYAnchor),
            
            // Progress bar
            progressBar.topAnchor.constraint(equalTo: timerRingView.bottomAnchor, constant: 16),
            progressBar.leadingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: 16),
            progressBar.trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: -16),
            
            // End focus button
            endFocusButton.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 20),
            endFocusButton.centerXAnchor.constraint(equalTo: statusView.centerXAnchor),
            endFocusButton.widthAnchor.constraint(equalToConstant: 220),
            endFocusButton.heightAnchor.constraint(equalToConstant: 40),
            endFocusButton.bottomAnchor.constraint(equalTo: statusView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(focusModeStateChanged),
            name: NSNotification.Name("FocusModeStateChanged"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(focusModeTimerUpdated),
            name: NSNotification.Name("FocusModeTimerUpdated"),
            object: nil
        )
    }
    
    // MARK: - Data Management
    
    private func loadApps() {
        // Load apps from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "savedApps") else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            allApps = try decoder.decode([AppItem].self, from: data)
            
            // Get list of distracting apps from focus manager
            let distractingAppNames = focusManager.getDistractingApps()
            
            // Filter allApps to get distracting apps
            distractingApps = allApps.filter { distractingAppNames.contains($0.name) }
            
        } catch {
            print("Failed to load apps: \(error)")
        }
    }
    
    private func saveDistractingApps() {
        // Get names of all apps marked as distracting
        let distractingAppNames = distractingApps.map { $0.name }
        
        // Save to focus manager
        focusManager.setDistractingApps(distractingAppNames)
    }
    
    // MARK: - UI Updates
    
    private func updateUI() {
        let state = focusManager.getCurrentState()
        
        switch state {
        case .active:
            updateForActiveState()
        case .scheduled:
            updateForScheduledState()
        case .inactive:
            updateForInactiveState()
        }
        
        // Reload table to show current distracting apps
        loadApps()
        tableView.reloadData()
    }
    
    private func updateForActiveState() {
        guard let session = focusManager.activeFocusSession else {
            updateForInactiveState()
            return
        }
        
        // Check if we're in a break (no blocked apps)
        let isInBreak = session.blockedApps.isEmpty && isBreakTime
        
        // Update status view
        if isInBreak {
            statusTitleLabel.text = "Break Time"
            statusDescriptionLabel.text = "Take a short break before your next focus session."
            statusView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.2)
        } else {
            statusTitleLabel.text = "Focus Mode Active"
            
            // Show more detailed information about which apps are blocked
            let blockedAppsText = session.blockedApps.isEmpty ? 
                "No apps are currently blocked." : 
                "Blocked apps: " + session.blockedApps.joined(separator: ", ")
                
            statusDescriptionLabel.text = "Stay productive! " + blockedAppsText
            statusView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            
            // If in Pomodoro mode, show additional info
            let isPomodoroMode = view.subviews.compactMap { $0 as? UIStackView }
                .flatMap { $0.arrangedSubviews }
                .flatMap { ($0 as? UIStackView)?.arrangedSubviews ?? [] }
                .compactMap { $0 as? UISwitch }
                .first?.isOn ?? false
            
            if isPomodoroMode && !isBreakTime {
                // Show which apps are blocked in Pomodoro mode as well
                let blockedAppsText = session.blockedApps.isEmpty ? 
                    "No apps are currently blocked." : 
                    "Blocked apps: " + session.blockedApps.joined(separator: ", ")
                    
                statusDescriptionLabel.text = "Pomodoro \(pomodoroCount + 1) in progress. " + blockedAppsText
            }
        }
        
        // Show timer components
        timerRingView.isHidden = false
        timerLabel.isHidden = false
        progressBar.isHidden = false
        endFocusButton.isHidden = false
        
        // Update progress bar color based on session type
        progressBar.progressTintColor = isInBreak ? .systemIndigo : .systemGreen
        
        // Update timer display
        updateTimerDisplay()
        
        // Update focus button
        focusButton.setTitle(isInBreak ? "Break in Progress" : "Focus Session in Progress", for: .normal)
        focusButton.isEnabled = false
        focusButton.backgroundColor = .systemGray
        
        // Add height to the status view for timer
        NSLayoutConstraint.activate([
            statusView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
    }
    
    private func updateForScheduledState() {
        guard let session = focusManager.scheduledFocusSession else {
            updateForInactiveState()
            return
        }
        
        // Format the start time
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        let startTimeString = dateFormatter.string(from: session.startTime)
        
        // Calculate duration in minutes
        let durationMinutes = Int(session.duration / 60)
        
        // Update status view
        statusTitleLabel.text = "Focus Mode Scheduled"
        statusDescriptionLabel.text = "Your \(durationMinutes)-minute focus session will start at \(startTimeString)."
        statusView.backgroundColor = .secondarySystemBackground
        
        // Hide timer components
        timerLabel.isHidden = true
        progressBar.isHidden = true
        
        // Show cancel button
        endFocusButton.isHidden = false
        endFocusButton.setTitle("Cancel Session", for: .normal)
        endFocusButton.setTitleColor(.systemRed, for: .normal)
        
        // Update focus button
        focusButton.setTitle("Start Focus Now", for: .normal)
        focusButton.isEnabled = true
        focusButton.backgroundColor = .systemBlue
        
        // Add height to the status view
        NSLayoutConstraint.activate([
            statusView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150)
        ])
    }
    
    private func updateForInactiveState() {
        // Update status view
        statusTitleLabel.text = "Focus Mode"
        statusDescriptionLabel.text = "Select apps to block during focus time."
        statusView.backgroundColor = .secondarySystemBackground
        
        // Hide timer components
        timerLabel.isHidden = true
        progressBar.isHidden = true
        endFocusButton.isHidden = true
        
        // Update focus button
        focusButton.setTitle("Start Focus Session", for: .normal)
        focusButton.isEnabled = true
        focusButton.backgroundColor = .systemBlue
        
        // Reset status view height
        for constraint in statusView.constraints where constraint.firstAttribute == .height {
            statusView.removeConstraint(constraint)
        }
        
        // Set standard height
        NSLayoutConstraint.activate([
            statusView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
    }
    
    private func updateTimerDisplay() {
        guard let session = focusManager.activeFocusSession else { return }
        
        // Update timer label
        timerLabel.text = session.formattedRemainingTime
        
        // Update progress bar
        progressBar.progress = Float(session.percentComplete)
        
        // Update timer ring
        updateTimerRing(with: Float(session.percentComplete))
    }
    
    private func updateTimerRing(with progress: Float) {
        // Remove any existing layers first
        timerRingView.layer.sublayers?.forEach { layer in
            if layer is CAShapeLayer {
                layer.removeFromSuperlayer()
            }
        }
        
        let center = CGPoint(x: timerRingView.bounds.width / 2, y: timerRingView.bounds.height / 2)
        let radius = min(timerRingView.bounds.width, timerRingView.bounds.height) / 2 - 10
        
        // Background track layer
        let trackLayer = CAShapeLayer()
        let trackPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        trackLayer.path = trackPath.cgPath
        trackLayer.strokeColor = UIColor.systemGray5.cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = 8
        timerRingView.layer.addSublayer(trackLayer)
        
        // Progress layer
        let progressLayer = CAShapeLayer()
        let progressPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi / 2, endAngle: 2 * .pi * CGFloat(progress) - .pi / 2, clockwise: true)
        progressLayer.path = progressPath.cgPath
        progressLayer.strokeColor = progressBar.progressTintColor?.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 8
        progressLayer.lineCap = .round
        timerRingView.layer.addSublayer(progressLayer)
    }
    
    // Called when view layout changes
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update timer ring if showing
        if !timerRingView.isHidden, let session = focusManager.activeFocusSession {
            updateTimerRing(with: Float(session.percentComplete))
        }
    }
    
    // MARK: - Actions
    
    @objc private func presetDurationChanged(_ sender: UISegmentedControl) {
        selectedPresetIndex = sender.selectedSegmentIndex
        durationMinutes = presetDurations[selectedPresetIndex].1
        
        // Update the duration label and stepper
        if let durationLabel = view.viewWithTag(100) as? UILabel {
            durationLabel.text = "Custom Duration: \(durationMinutes) minutes"
        }
    }
    
    @objc private func durationChanged(_ sender: UIStepper) {
        durationMinutes = Int(sender.value)
        
        // Update the duration label
        if let durationLabel = view.viewWithTag(100) as? UILabel {
            durationLabel.text = "Custom Duration: \(durationMinutes) minutes"
        }
        
        // Deselect any preset
        if let segmentControl = view.subviews.compactMap({ $0 as? UIStackView }).first?.arrangedSubviews.first as? UISegmentedControl {
            segmentControl.selectedSegmentIndex = UISegmentedControl.noSegment
        }
    }
    
    @objc private func pomodoroSwitchChanged(_ sender: UISwitch) {
        // If turning on Pomodoro mode, set to 25 minutes and select the Pomodoro preset
        if sender.isOn {
            durationMinutes = 25
            selectedPresetIndex = 1
            
            if let segmentControl = view.subviews.compactMap({ $0 as? UIStackView }).first?.arrangedSubviews.first as? UISegmentedControl {
                segmentControl.selectedSegmentIndex = selectedPresetIndex
            }
            
            if let durationLabel = view.viewWithTag(100) as? UILabel {
                durationLabel.text = "Custom Duration: \(durationMinutes) minutes"
            }
            
            // Show alert explaining Pomodoro mode
            let alert = UIAlertController(
                title: "Pomodoro Mode Activated",
                message: "Pomodoro mode will automatically cycle between \(durationMinutes)-minute focus sessions and \(pomodoroBreakDuration)-minute breaks. After 4 pomodoros, you'll get a longer 15-minute break.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    @objc private func scheduleButtonTapped() {
        // Create a proper date picker view controller instead of trying to add it to an alert
        let datePickerVC = UIViewController()
        datePickerVC.modalPresentationStyle = .formSheet
        datePickerVC.preferredContentSize = CGSize(width: 300, height: 400)
        datePickerVC.view.backgroundColor = .systemBackground  // Add solid background color
        
        // Create container view for the content
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground  // Add solid background color
        containerView.translatesAutoresizingMaskIntoConstraints = false
        datePickerVC.view.addSubview(containerView)
        
        // Add title
        let titleLabel = UILabel()
        titleLabel.text = "Schedule Focus Session"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Add subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Select when to start your \(durationMinutes)-minute focus session:"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.numberOfLines = 0
        containerView.addSubview(subtitleLabel)
        
        // Create date picker
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .inline  // Use the inline style which shows calendar
        datePicker.minimumDate = Date(timeIntervalSinceNow: 60) // At least 1 minute in the future
        datePicker.date = Date(timeIntervalSinceNow: 60*15) // Default to 15 minutes from now
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.backgroundColor = .systemBackground
        datePicker.tintColor = .systemBlue
        containerView.addSubview(datePicker)
        
        // Add schedule button
        let scheduleButton = UIButton(type: .system)
        scheduleButton.setTitle("Schedule", for: .normal)
        scheduleButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        scheduleButton.backgroundColor = .systemBlue
        scheduleButton.setTitleColor(.white, for: .normal)
        scheduleButton.layer.cornerRadius = 10
        scheduleButton.clipsToBounds = true
        scheduleButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(scheduleButton)
        
        // Add cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cancelButton)
        
        // Setup constraints for proper layout
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: datePickerVC.view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: datePickerVC.view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: datePickerVC.view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: datePickerVC.view.bottomAnchor),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Subtitle label
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Date picker
            datePicker.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            datePicker.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            datePicker.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 20),
            datePicker.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -20),
            
            // Schedule button
            scheduleButton.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 24),
            scheduleButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            scheduleButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            scheduleButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Cancel button
            cancelButton.topAnchor.constraint(equalTo: scheduleButton.bottomAnchor, constant: 12),
            cancelButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
        
        // Add button actions
        scheduleButton.addAction(UIAction { [weak self, weak datePickerVC] _ in
            self?.scheduleFocusSession(startTime: datePicker.date)
            datePickerVC?.dismiss(animated: true)
        }, for: .touchUpInside)
        
        cancelButton.addAction(UIAction { [weak datePickerVC] _ in
            datePickerVC?.dismiss(animated: true)
        }, for: .touchUpInside)
        
        // Present the date picker view controller
        present(datePickerVC, animated: true)
    }
    
    @objc private func startFocusButtonTapped() {
        let state = focusManager.getCurrentState()
        
        if state == .scheduled {
            // If there's a scheduled session, cancel it and start a new one immediately
            focusManager.cancelScheduledFocusSession()
        }
        
        // Reset Pomodoro counter if starting a new session
        pomodoroCount = 0
        isBreakTime = false
        
        // Get the currently selected distracting apps
        let distractingAppNames = distractingApps.map { $0.name }
        
        // Convert duration to seconds
        let durationSeconds = TimeInterval(durationMinutes * 60)
        
        // Check if Pomodoro mode is active
        let isPomodoroMode = view.subviews.compactMap { $0 as? UIStackView }
            .flatMap { $0.arrangedSubviews }
            .flatMap { ($0 as? UIStackView)?.arrangedSubviews ?? [] }
            .compactMap { $0 as? UISwitch }
            .first?.isOn ?? false
        
        // Start focus session
        _ = focusManager.startFocusSession(duration: durationSeconds, blockedApps: distractingAppNames)
        
        // Update UI
        updateUI()
        
        // Show success message with detailed app blocking information
        let blockedAppsText = distractingAppNames.isEmpty ?
            "No apps will be blocked during this session." :
            "The following apps will be blocked: " + distractingAppNames.joined(separator: ", ")
            
        let alert = UIAlertController(
            title: "Focus Mode Activated",
            message: (isPomodoroMode ? 
                "Your focus session will last \(durationMinutes) minutes, followed by a \(pomodoroBreakDuration)-minute break.\n\n" :
                "Your focus session will end in \(durationMinutes) minutes.\n\n") + blockedAppsText,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func scheduleFocusSession(startTime: Date) {
        // Get the currently selected distracting apps
        let distractingAppNames = distractingApps.map { $0.name }
        
        // Convert duration to seconds
        let durationSeconds = TimeInterval(durationMinutes * 60)
        
        // Schedule the focus session
        _ = focusManager.scheduleFocusSession(startTime: startTime, duration: durationSeconds, blockedApps: distractingAppNames)
        
        // Format time for display
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        let timeString = formatter.string(from: startTime)
        
        // Update UI
        updateUI()
        
        // Show confirmation
        let alert = UIAlertController(
            title: "Focus Session Scheduled",
            message: "Your \(durationMinutes)-minute focus session is scheduled to start at \(timeString).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func endFocusButtonTapped() {
        let state = focusManager.getCurrentState()
        
        if state == .active {
            // End active focus session
            focusManager.endFocusSession(completed: false)
        } else if state == .scheduled {
            // Cancel scheduled session
            focusManager.cancelScheduledFocusSession()
        }
        
        // Update UI
        updateUI()
    }
    
    @objc private func focusModeStateChanged() {
        DispatchQueue.main.async {
            self.updateUI()
        }
    }
    
    @objc private func focusModeTimerUpdated() {
        DispatchQueue.main.async {
            self.updateTimerDisplay()
            self.checkForPomodoroTransition()
        }
    }
    
    private func checkForPomodoroTransition() {
        // Check if Pomodoro mode is on
        let isPomodoroMode = view.subviews.compactMap { $0 as? UIStackView }
            .flatMap { $0.arrangedSubviews }
            .flatMap { ($0 as? UIStackView)?.arrangedSubviews ?? [] }
            .compactMap { $0 as? UISwitch }
            .first?.isOn ?? false
        
        if !isPomodoroMode { return }
        
        guard let session = focusManager.activeFocusSession else { return }
        
        // Check if the session has less than 1 second remaining
        if session.remainingTime < 1.0 {
            // Session is about to end naturally - handle Pomodoro transition
            if isBreakTime {
                // Break is ending, start a new focus session
                isBreakTime = false
                pomodoroCount += 1
                
                // Determine if we need a long break after 4 pomodoros
                let nextBreakDuration = (pomodoroCount % 4 == 0) ? 15 : pomodoroBreakDuration
                
                // Show notification that break is over
                let alert = UIAlertController(
                    title: "Break Time Complete",
                    message: "Time to start your next Pomodoro! \(pomodoroCount) completed so far.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Start Next Pomodoro", style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    
                    // Start next focus session
                    let distractingAppNames = self.distractingApps.map { $0.name }
                    let durationSeconds = TimeInterval(self.durationMinutes * 60)
                    _ = self.focusManager.startFocusSession(duration: durationSeconds, blockedApps: distractingAppNames)
                    self.updateUI()
                })
                alert.addAction(UIAlertAction(title: "End Pomodoro Sessions", style: .cancel))
                present(alert, animated: true)
                
            } else {
                // Focus session is ending, start a break
                isBreakTime = true
                
                // Determine break duration (longer break after 4 pomodoros)
                let breakDuration = (pomodoroCount > 0 && pomodoroCount % 4 == 0) ? 15 : pomodoroBreakDuration
                
                // Show notification that focus is over and break is starting
                let alert = UIAlertController(
                    title: "Pomodoro Complete!",
                    message: "Great job! Take a \(breakDuration)-minute break before your next Pomodoro.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Start Break", style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    
                    // Start break session (no blocked apps during break)
                    let breakDurationSeconds = TimeInterval(breakDuration * 60)
                    _ = self.focusManager.startFocusSession(duration: breakDurationSeconds, blockedApps: [])
                    
                    // Update status view to show it's a break
                    self.statusTitleLabel.text = "Break Time"
                    self.statusDescriptionLabel.text = "Relax for \(breakDuration) minutes before your next focus session."
                    self.updateUI()
                })
                alert.addAction(UIAlertAction(title: "Skip Break", style: .cancel) { [weak self] _ in
                    guard let self = self else { return }
                    
                    // Skip break and start next pomodoro
                    self.isBreakTime = false
                    self.pomodoroCount += 1
                    
                    let distractingAppNames = self.distractingApps.map { $0.name }
                    let durationSeconds = TimeInterval(self.durationMinutes * 60)
                    _ = self.focusManager.startFocusSession(duration: durationSeconds, blockedApps: distractingAppNames)
                    self.updateUI()
                })
                present(alert, animated: true)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isAppDistracting(_ app: AppItem) -> Bool {
        return distractingApps.contains { $0.name == app.name }
    }
    
    private func toggleDistractingApp(_ app: AppItem) {
        if isAppDistracting(app) {
            // Remove from distracting apps
            distractingApps.removeAll { $0.name == app.name }
        } else {
            // Add to distracting apps
            distractingApps.append(app)
        }
        
        // Save changes
        saveDistractingApps()
        
        // Reload table
        tableView.reloadData()
    }
}

extension FocusModeViewController {
    // MARK: - Navigation Actions

    @objc private func showFocusStats() {
        // Create and present stats view controller
        let statsVC = FocusStatsViewController()
        navigationController?.pushViewController(statsVC, animated: true)
    }

    @objc private func showFocusHistory() {
        // Create a simple alert with focus session history
        let alert = UIAlertController(
            title: "Focus Session History",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        // Get all completed focus sessions
        let sessions = focusManager.getFocusSessionHistory().filter { $0.isCompleted }
        
        if sessions.isEmpty {
            alert.message = "No completed focus sessions yet."
        } else {
            // Create a string with session info
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            
            let historyText = sessions.suffix(10).map { session -> String in
                let startDate = dateFormatter.string(from: session.startTime)
                let duration = Int(session.duration / 60)
                
                // Display actual blocked apps
                let blockedAppsDetail = session.blockedApps.isEmpty ? 
                    "No apps blocked" : 
                    "Blocked: " + session.blockedApps.joined(separator: ", ")
                
                return "\(startDate): \(duration) min\n" + blockedAppsDetail
            }.joined(separator: "\n\n")
            
            alert.message = historyText
        }
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - TableView DataSource & Delegate

extension FocusModeViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allApps.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Select Apps to Block During Focus Time"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AppCell", for: indexPath)
        
        if indexPath.row < allApps.count {
            let app = allApps[indexPath.row]
            
            // Configure cell
            cell.textLabel?.text = app.name
            
            // Check if this app is in the distracting apps list
            let isDistracting = isAppDistracting(app)
            
            // Add checkmark if app is in distracting list
            cell.accessoryType = isDistracting ? .checkmark : .none
            
            // Remove the icon/image
            cell.imageView?.image = nil
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row < allApps.count {
            let app = allApps[indexPath.row]
            toggleDistractingApp(app)
        }
    }
}
