//
//  SettingsViewController.swift
//  CoreLaunch
//
//  Created by x on 4/2/25.
//

import UIKit

// No need to import CoreLaunch as we're already in the module

protocol SettingsDelegate: AnyObject {
    func didUpdateSettings()
    func didUpdateAppSelections(_ updatedApps: [AppItem])
}

class SettingsViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    weak var delegate: SettingsDelegate?
    
    // Settings
    private var use24HourTime = false
    private var showDate = true
    private var useMinimalistStyle = true
    private var useMonochromeIcons = false
    
    // Apps settings
    private var allApps: [AppItem] = []
    
    // MARK: - UI Elements
    private let closeButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSettings()
        loadApps()
        setupUI()
        configureTableView()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Settings"
        view.backgroundColor = .systemBackground
        
        // Close button
        closeButton.setTitle("Done", for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
        
        // Add button for adding new apps (if needed)
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAppButtonTapped))
        navigationItem.leftBarButtonItem = addButton
        
        // Table view
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        tableView.isEditing = false // Will be toggled to true for the apps section
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        saveSettings()
        delegate?.didUpdateSettings()
        dismiss(animated: true)
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(use24HourTime, forKey: "use24HourTime")
        defaults.set(showDate, forKey: "showDate")
        defaults.set(useMinimalistStyle, forKey: "useMinimalistStyle")
        defaults.set(useMonochromeIcons, forKey: "useMonochromeIcons")
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Load the current settings
        use24HourTime = defaults.bool(forKey: "use24HourTime")
        showDate = defaults.bool(forKey: "showDate")
        useMinimalistStyle = defaults.bool(forKey: "useMinimalistStyle")
        useMonochromeIcons = defaults.bool(forKey: "useMonochromeIcons")
    }
    
    private func loadApps() {
        // Load apps from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "savedApps") else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            allApps = try decoder.decode([AppItem].self, from: data)
        } catch {
            print("Failed to load apps: \(error)")
        }
    }
}

// MARK: - TableView DataSource & Delegate
extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2 // Time settings
        case 1:
            return 1 // Appearance settings
        case 2:
            return 1 // Icon settings
        case 3:
            return allApps.count // App selection
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Time Display"
        case 1:
            return "Appearance"
        case 2:
            return "App Icons"
        case 3:
            return "Home Screen Apps"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 3 {
            // Create a header with a button to toggle edit mode
            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 40))
            
            let titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.text = "Home Screen Apps"
            titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
            titleLabel.textColor = .secondaryLabel
            headerView.addSubview(titleLabel)
            
            let editButton = UIButton(type: .system)
            editButton.translatesAutoresizingMaskIntoConstraints = false
            editButton.setTitle(tableView.isEditing ? "Done" : "Reorder", for: .normal)
            editButton.addTarget(self, action: #selector(toggleReorderMode(_:)), for: .touchUpInside)
            headerView.addSubview(editButton)
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                
                editButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                editButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
            ])
            
            return headerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 3 ? 44 : UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 3 {
            return "Toggle which apps appear on your home screen."
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        cell.selectionStyle = .none
        
        let switchView = UISwitch()
        cell.accessoryView = switchView
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "24-Hour Time"
                switchView.isOn = use24HourTime
                switchView.tag = 0
                switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            case 1:
                cell.textLabel?.text = "Show Date"
                switchView.isOn = showDate
                switchView.tag = 1
                switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Minimalist Style"
                switchView.isOn = useMinimalistStyle
                switchView.tag = 2
                switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Monochrome App Icons"
                switchView.isOn = useMonochromeIcons
                switchView.tag = 3
                switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            default:
                break
            }
        case 3: // App selection
            if indexPath.row < allApps.count {
                let app = allApps[indexPath.row]
                cell.textLabel?.text = app.name
                
                // Create a simple colored dot for the app icon
                let iconSize: CGFloat = 24
                let iconView = UIView(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
                iconView.backgroundColor = app.getIconColor(useMonochrome: useMonochromeIcons, isDarkMode: traitCollection.userInterfaceStyle == .dark)
                iconView.layer.cornerRadius = iconSize / 2
                iconView.clipsToBounds = true
                
                // Create a container view to hold our icon
                let containerView = UIView(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
                containerView.addSubview(iconView)
                
                // Set the container as the accessory view
                let iconContainerView = UIView(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
                iconContainerView.addSubview(containerView)
                
                // Clear any existing accessoryView
                cell.accessoryView = nil
                
                // Set the icon image
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
                imageView.image = UIImage(systemName: "app.fill")
                imageView.tintColor = app.getIconColor(useMonochrome: useMonochromeIcons, isDarkMode: traitCollection.userInterfaceStyle == .dark)
                cell.imageView?.image = imageView.image
                
                // Set switch for app selection
                switchView.isOn = app.isSelected
                switchView.tag = 1000 + indexPath.row // Use tag 1000+ for app switches
                switchView.addTarget(self, action: #selector(appSwitchChanged(_:)), for: .valueChanged)
                cell.accessoryView = switchView
            }
        default:
            break
        }
        
        return cell
    }
    
    @objc func switchChanged(_ sender: UISwitch) {
        switch sender.tag {
        case 0:
            use24HourTime = sender.isOn
        case 1:
            showDate = sender.isOn
        case 2:
            useMinimalistStyle = sender.isOn
        case 3:
            useMonochromeIcons = sender.isOn
        default:
            break
        }
    }
    
    @objc func appSwitchChanged(_ sender: UISwitch) {
        // Get app index from tag (tag = 1000 + index)
        let appIndex = sender.tag - 1000
        
        if appIndex >= 0 && appIndex < allApps.count {
            // Update app selection
            allApps[appIndex].isSelected = sender.isOn
            
            // Ensure the selection is saved to UserDefaults
            saveAppSelectionsToUserDefaults()
            
            // Notify delegate to update the home screen
            delegate?.didUpdateAppSelections(allApps)
        }
    }
    
    private func saveAppSelectionsToUserDefaults() {
        // Save updated app selections to UserDefaults
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(allApps)
            UserDefaults.standard.set(data, forKey: "savedApps")
        } catch {
            print("Failed to save app selections: \(error)")
        }
    }
    
    @objc func toggleReorderMode(_ sender: UIButton) {
        // Toggle editing mode for the table view
        tableView.setEditing(!tableView.isEditing, animated: true)
        
        // Update button text
        sender.setTitle(tableView.isEditing ? "Done" : "Reorder", for: .normal)
        
        // Refresh section header
        tableView.reloadSections(IndexSet(integer: 3), with: .automatic)
    }
    
    @objc func addAppButtonTapped() {
        // Create alert controller for adding a new app
        let alert = UIAlertController(title: "Add New App", message: "Enter the name of the app to add to your home screen", preferredStyle: .alert)
        
        // Add text field for app name
        alert.addTextField { textField in
            textField.placeholder = "App Name"
        }
        
        // Add action to create the app
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self, 
                  let textField = alert.textFields?.first,
                  let appName = textField.text, !appName.isEmpty else { return }
            
            // Create a new app with random color
            let appColors: [UIColor] = [.systemBlue, .systemGreen, .systemIndigo, 
                                        .systemOrange, .systemYellow, .systemRed, 
                                        .systemPurple, .systemTeal]
            let randomColor = appColors.randomElement() ?? .systemBlue
            
            let newApp = AppItem(name: appName, color: randomColor)
            
            // Add to apps list
            self.allApps.append(newApp)
            
            // Save to UserDefaults
            self.saveAppSelectionsToUserDefaults()
            
            // Reload the table view
            self.tableView.reloadData()
            
            // Notify delegate
            self.delegate?.didUpdateAppSelections(self.allApps)
        }
        
        // Add cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // Add actions to alert controller
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        // Present alert controller
        present(alert, animated: true)
    }
    
    // MARK: - Table View Editing Support
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Only allow editing in the apps section
        return indexPath.section == 3
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        // During reordering mode, don't show delete buttons
        if indexPath.section == 3 && tableView.isEditing {
            return .none
        }
        return .delete
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Only allow moving in the apps section
        return indexPath.section == 3
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Ensure we're only moving within the apps section
        guard sourceIndexPath.section == 3 && destinationIndexPath.section == 3 else { return }
        
        // Update the app order in our data model
        let movedApp = allApps.remove(at: sourceIndexPath.row)
        allApps.insert(movedApp, at: destinationIndexPath.row)
        
        // Save the updated order
        saveAppSelectionsToUserDefaults()
        
        // Notify the home screen of the change
        delegate?.didUpdateAppSelections(allApps)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == 3 && editingStyle == .delete {
            // Prevent deleting all apps - maintain at least one app
            if allApps.count <= 1 {
                let alert = UIAlertController(
                    title: "Cannot Delete",
                    message: "You must have at least one app on your home screen",
                    preferredStyle: .alert
                )
                let okAction = UIAlertAction(title: "OK", style: .default)
                alert.addAction(okAction)
                present(alert, animated: true)
                return
            }
            
            // Remove the app from the array
            allApps.remove(at: indexPath.row)
            
            // Save changes
            saveAppSelectionsToUserDefaults()
            
            // Update the UI
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            // Notify delegate
            delegate?.didUpdateAppSelections(allApps)
        }
    }
}
