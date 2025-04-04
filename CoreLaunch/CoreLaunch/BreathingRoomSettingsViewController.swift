//
//  BreathingRoomSettingsViewController.swift
//  CoreLaunch
//
//  Created on 4/4/25.
//

import UIKit

class BreathingRoomSettingsViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var allApps: [AppItem] = []
    private var breathingManager = BreathingRoomManager.shared
    private var reflectionPrompts: [String] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Breathing Room"
        view.backgroundColor = .systemBackground
        
        // Add a done button
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        
        // Setup table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        tableView.register(SliderTableViewCell.self, forCellReuseIdentifier: "SliderCell")
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Data
    private func loadData() {
        // Load all apps from HomeViewController's cache or UserDefaults
        if let data = UserDefaults.standard.data(forKey: "savedApps"),
           let apps = try? JSONDecoder().decode([AppItem].self, from: data) {
            allApps = apps
        }
        
        // Load reflection prompts
        reflectionPrompts = breathingManager.reflectionPrompts
    }
    
    @objc private func doneButtonTapped() {
        dismiss(animated: true)
    }
    
    private func showAddPromptDialog() {
        let alert = UIAlertController(
            title: "Add Reflection Prompt",
            message: "Enter a question or statement to help you reflect during the delay.",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Enter reflection prompt"
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            guard let self = self, let textField = alert?.textFields?.first, let text = textField.text, !text.isEmpty else { return }
            
            // Add the new prompt
            self.breathingManager.addReflectionPrompt(text)
            
            // Reload prompts section
            self.reflectionPrompts = self.breathingManager.reflectionPrompts
            self.tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func showResetPromptsConfirmation() {
        let alert = UIAlertController(
            title: "Reset Prompts",
            message: "Are you sure you want to reset all reflection prompts to defaults?",
            preferredStyle: .alert
        )
        
        let resetAction = UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Reset prompts
            self.breathingManager.resetReflectionPromptsToDefault()
            
            // Reload prompts section
            self.reflectionPrompts = self.breathingManager.reflectionPrompts
            self.tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}

// MARK: - TableView Extension
extension BreathingRoomSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // General settings
            return 2
        case 1: // App-specific settings
            return allApps.count
        case 2: // Reflection prompts
            return reflectionPrompts.count + 2 // Prompts + Add button + Reset button
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "General Settings"
        case 1:
            return "App Settings"
        case 2:
            return "Reflection Prompts"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Enable Breathing Room to add a pause before opening apps, helping you reflect on your intentions."
        case 1:
            return "Customize which apps require a moment of pause before opening."
        case 2:
            return "Customize the reflection prompts shown during the breathing room delay."
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: // General settings
            if indexPath.row == 0 {
                // Enable/disable breathing room
                let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
                cell.textLabel?.text = "Enable Breathing Room"
                
                let switchView = UISwitch()
                switchView.isOn = breathingManager.isEnabled
                switchView.tag = 0
                switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                
                return cell
            } else {
                // Default delay duration slider
                let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCell", for: indexPath) as! SliderTableViewCell
                cell.configure(title: "Default Delay Duration", 
                               value: Float(breathingManager.defaultDelay),
                               minimumValue: 1.0,
                               maximumValue: 30.0,
                               tag: 1)
                cell.valueChanged = { [weak self] newValue in
                    self?.breathingManager.setDefaultDelay(TimeInterval(newValue))
                }
                
                return cell
            }
            
        case 1: // App-specific settings
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
            let app = allApps[indexPath.row]
            cell.textLabel?.text = app.name
            cell.textLabel?.textColor = .label  // Always use black text
            
            // Create switch for breathing room
            let switchView = UISwitch()
            let appSetting = breathingManager.getAppSetting(for: app.name)
            switchView.isOn = appSetting?.isEnabled ?? false
            switchView.tag = 1000 + indexPath.row // Use tag 1000+ for app switches
            switchView.addTarget(self, action: #selector(appSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            
            return cell
            
        case 2: // Reflection prompts
            if indexPath.row < reflectionPrompts.count {
                // Display existing prompts
                let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
                cell.textLabel?.text = reflectionPrompts[indexPath.row]
                cell.textLabel?.textColor = .label // Use system label color (black in light mode)
                cell.textLabel?.numberOfLines = 0
                cell.accessoryView = nil // Remove any accessory view/toggle
                cell.selectionStyle = .none
                return cell
            } else if indexPath.row == reflectionPrompts.count {
                // Add prompt button
                let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
                cell.textLabel?.text = "Add New Prompt"
                cell.textLabel?.textColor = .systemBlue
                cell.accessoryView = nil
                cell.accessoryType = .none
                return cell
            } else {
                // Reset to defaults button
                let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
                cell.textLabel?.text = "Reset to Defaults"
                cell.textLabel?.textColor = .systemRed
                cell.accessoryView = nil
                return cell
            }
            
        default:
            return UITableViewCell()
        }
    }
    
    @objc func switchChanged(_ sender: UISwitch) {
        switch sender.tag {
        case 0: // Global enable/disable
            breathingManager.setEnabled(sender.isOn)
        default:
            break
        }
    }
    
    @objc func appSwitchChanged(_ sender: UISwitch) {
        // Get app index from tag (tag = 1000 + index)
        let appIndex = sender.tag - 1000
        
        if appIndex >= 0 && appIndex < allApps.count {
            let app = allApps[appIndex]
            
            // Get current delay duration or use default
            let currentSetting = breathingManager.getAppSetting(for: app.name)
            let delayDuration = currentSetting?.delayDuration ?? breathingManager.defaultDelay
            
            // Update app breathing room setting
            breathingManager.setAppSetting(appName: app.name, isEnabled: sender.isOn, delayDuration: delayDuration)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            // Show delay duration configuration for the selected app
            let app = allApps[indexPath.row]
            showDelayDurationConfiguration(for: app)
        } else if indexPath.section == 2 {
            if indexPath.row == reflectionPrompts.count {
                // Add new prompt
                showAddPromptDialog()
            } else if indexPath.row == reflectionPrompts.count + 1 {
                // Reset to defaults
                showResetPromptsConfirmation()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Only allow editing prompts
        return indexPath.section == 2 && indexPath.row < reflectionPrompts.count
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row < reflectionPrompts.count && editingStyle == .delete {
            // Delete the prompt
            breathingManager.removeReflectionPrompt(at: indexPath.row)
            
            // Update local array and UI
            reflectionPrompts = breathingManager.reflectionPrompts
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    private func showDelayDurationConfiguration(for app: AppItem) {
        // Get current setting or use default
        let currentSetting = breathingManager.getAppSetting(for: app.name)
        let isEnabled = currentSetting?.isEnabled ?? false
        let currentDelay = currentSetting?.delayDuration ?? breathingManager.defaultDelay
        
        let alert = UIAlertController(
            title: "Delay for \(app.name)",
            message: "Set how long the breathing room delay should be for this app.",
            preferredStyle: .alert
        )
        
        // Add a slider for delay duration
        alert.addTextField { textField in
            textField.placeholder = "Delay in seconds (1-30)"
            textField.text = "\(Int(currentDelay))"
            textField.keyboardType = .numberPad
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self = self, let textField = alert?.textFields?.first, let text = textField.text, let delayValue = Double(text) else { return }
            
            // Ensure value is within bounds
            let cappedDelay = max(1.0, min(delayValue, 30.0))
            
            // Update app setting
            self.breathingManager.setAppSetting(appName: app.name, isEnabled: isEnabled, delayDuration: cappedDelay)
            
            // Reload table
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}

// Custom cell for sliders
class SliderTableViewCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let slider = UISlider()
    private let valueLabel = UILabel()
    
    var valueChanged: ((Float) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Configure title label
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Configure slider
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        contentView.addSubview(slider)
        
        // Configure value label
        valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(valueLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            slider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: valueLabel.leadingAnchor, constant: -8),
            
            valueLabel.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            valueLabel.widthAnchor.constraint(equalToConstant: 40),
            
            contentView.bottomAnchor.constraint(equalTo: slider.bottomAnchor, constant: 12)
        ])
    }
    
    func configure(title: String, value: Float, minimumValue: Float, maximumValue: Float, tag: Int) {
        titleLabel.text = title
        slider.minimumValue = minimumValue
        slider.maximumValue = maximumValue
        slider.value = value
        slider.tag = tag
        updateValueLabel()
    }
    
    @objc private func sliderValueChanged(_ sender: UISlider) {
        updateValueLabel()
        valueChanged?(sender.value)
    }
    
    private func updateValueLabel() {
        valueLabel.text = "\(Int(slider.value))s"
    }
}
