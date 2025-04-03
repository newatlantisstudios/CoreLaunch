        // Add method to reload table data
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
    func didUpdateTheme()
}

class SettingsViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    weak var delegate: SettingsDelegate?
    
    // Current theme
    private var currentTheme: ColorTheme = ThemeManager.shared.currentTheme
    
    // Settings
    private var use24HourTime = false
    private var showDate = true
    private var useMinimalistStyle = true
    private var useMonochromeIcons = false
    private var showMotivationalMessages = true
    
    // Text Settings
    private var textSizeMultiplier: Float = 1.0 // Default size
    private var fontName = "System" // Default font
    
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
    
    // MARK: - Theme Selection
    
    private func showThemeSelectionMenu() {
        let themeVC = ThemeSelectionViewController()
        themeVC.delegate = self
        themeVC.selectedTheme = currentTheme
        let navController = UINavigationController(rootViewController: themeVC)
        present(navController, animated: true)
    }
    
    private func showCustomThemesMenu() {
        let customThemesVC = CustomThemesViewController()
        customThemesVC.delegate = self
        let navController = UINavigationController(rootViewController: customThemesVC)
        present(navController, animated: true)
    }
    
    private func showCreateThemeMenu() {
        let createThemeVC = ThemeEditViewController()
        createThemeVC.delegate = self
        let navController = UINavigationController(rootViewController: createThemeVC)
        present(navController, animated: true)
    }
    
    // MARK: - Theme Selection View Controller
    class ThemeSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
        private let tableView = UITableView()
        weak var delegate: SettingsViewController?
        var selectedTheme: ColorTheme!
        private var allThemes: [ColorTheme] = []
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            allThemes = ThemeManager.shared.getAllThemes()
            
            // Setup navigation bar
            title = "Select Theme"
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
            
            // Setup table view
            view.backgroundColor = .systemBackground
            tableView.dataSource = self
            tableView.delegate = self
            tableView.register(ThemePreviewCell.self, forCellReuseIdentifier: "ThemePreviewCell")
            view.addSubview(tableView)
            
            // Layout
            tableView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        @objc private func cancelButtonTapped() {
            dismiss(animated: true)
        }
        
        // MARK: - UITableViewDataSource
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return allThemes.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ThemePreviewCell", for: indexPath) as? ThemePreviewCell else {
                return UITableViewCell()
            }
            
            let theme = allThemes[indexPath.row]
            cell.configure(with: theme)
            
            // Check if this is the currently selected theme
            if theme.name == selectedTheme.name {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            
            return cell
        }
        
        // MARK: - UITableViewDelegate
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let selectedTheme = allThemes[indexPath.row]
            print("Selected theme: \(selectedTheme.name), background color: \(selectedTheme.backgroundColor)")
            
            ThemeManager.shared.currentTheme = selectedTheme
            delegate?.currentTheme = selectedTheme
            delegate?.tableView.reloadData()
            
            // Special handling for Monochrome theme
            if selectedTheme.name == "Monochrome" {
                // Force apply white background to avoid gray display
                if let window = UIApplication.shared.windows.first {
                    window.backgroundColor = .white
                }
            }
            
            // Force UI update
            NotificationCenter.default.post(name: NSNotification.Name("ThemeDidChangeNotification"), object: nil)
            
            // For Monochrome theme, post notification again after a slight delay
            // to ensure all UI components update properly
            if selectedTheme.name == "Monochrome" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    NotificationCenter.default.post(name: NSNotification.Name("ThemeDidChangeNotification"), object: nil)
                }
            }
            
            dismiss(animated: true)
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 80 // Taller rows to fit theme preview
        }
    }
    
    // MARK: - Custom Themes View Controller
    class CustomThemesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
        private let tableView = UITableView()
        weak var delegate: SettingsViewController?
        private var customThemes: [ColorTheme] = []
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            customThemes = ThemeManager.shared.loadCustomThemes()
            
            // Setup navigation bar
            title = "Custom Themes"
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
            
            // Setup table view
            view.backgroundColor = .systemBackground
            tableView.dataSource = self
            tableView.delegate = self
            tableView.register(ThemePreviewCell.self, forCellReuseIdentifier: "ThemePreviewCell")
            tableView.allowsSelection = true
            tableView.isEditing = true
            view.addSubview(tableView)
            
            // Layout
            tableView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        @objc private func cancelButtonTapped() {
            dismiss(animated: true)
        }
        
        // MARK: - UITableViewDataSource
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return customThemes.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ThemePreviewCell", for: indexPath) as? ThemePreviewCell else {
                return UITableViewCell()
            }
            
            let theme = customThemes[indexPath.row]
            cell.configure(with: theme)
            
            return cell
        }
        
        // MARK: - UITableViewDelegate
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let theme = customThemes[indexPath.row]
            
            // Show edit screen
            let editVC = ThemeEditViewController()
            editVC.delegate = delegate
            editVC.theme = theme
            editVC.isThemeEditing = true
            
            navigationController?.pushViewController(editVC, animated: true)
        }
        
        func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                let themeToDelete = customThemes[indexPath.row]
                
                // Delete the theme
                ThemeManager.shared.deleteCustomTheme(named: themeToDelete.name)
                
                // Update the data source
                customThemes.remove(at: indexPath.row)
                
                // Update the UI
                tableView.deleteRows(at: [indexPath], with: .automatic)
                
                // If the current theme was deleted, switch to Auto Light and Dark theme
                if delegate?.currentTheme.name == themeToDelete.name {
                    delegate?.currentTheme = ColorTheme.defaultTheme
                    delegate?.tableView.reloadData()
                }
            }
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 80
        }
    }
    
    // MARK: - Theme Edit View Controller
    class ThemeEditViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
        private let tableView = UITableView(frame: .zero, style: .insetGrouped)
        weak var delegate: SettingsViewController?
        var theme: ColorTheme = ColorTheme(name: "New Theme", primaryColor: .systemBlue, secondaryColor: .systemGreen, accentColor: .systemOrange, backgroundColor: .systemBackground, textColor: .label, secondaryTextColor: .secondaryLabel)
        var isThemeEditing: Bool = false
        
        private let colorProperties = ["Name", "Primary Color", "Secondary Color", "Accent Color", "Background Color", "Text Color", "Secondary Text Color"]
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Setup navigation bar
            title = isThemeEditing ? "Edit Theme" : "Create Theme"
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonTapped))
            
            // Setup table view
            view.backgroundColor = .systemBackground
            tableView.dataSource = self
            tableView.delegate = self
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ColorCell")
            view.addSubview(tableView)
            
            // Layout
            tableView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            // Add color picker view if needed
            updateBackgroundWithTheme()
        }
        
        @objc private func cancelButtonTapped() {
            dismiss(animated: true)
        }
        
        @objc private func saveButtonTapped() {
            // Validate theme name
            if theme.name.isEmpty {
                let alert = UIAlertController(title: "Invalid Name", message: "Please enter a name for your theme", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            
            // Save the theme
            ThemeManager.shared.registerCustomTheme(theme)
            
            // Set as current if desired
            let alert = UIAlertController(title: "Theme Saved", message: "Would you like to use this theme now?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.currentTheme = self.theme
                self.delegate?.tableView.reloadData()
                self.dismiss(animated: true)
            })
            
            alert.addAction(UIAlertAction(title: "No", style: .cancel) { [weak self] _ in
                self?.dismiss(animated: true)
            })
            
            present(alert, animated: true)
        }
        
        internal func updateBackgroundWithTheme() {
            // Apply the theme's colors to the view for preview
            view.backgroundColor = theme.backgroundColor
            tableView.backgroundColor = theme.backgroundColor.darker(by: 5)
        }
        
        // Add method to reload table data
        func reloadTableData() {
            self.tableView.reloadData()
        }
        
        // MARK: - UITableViewDataSource
        
        func numberOfSections(in tableView: UITableView) -> Int {
            return 2
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return section == 0 ? 1 : colorProperties.count - 1
        }
        
        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return section == 0 ? "Theme Name" : "Colors"
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ColorCell", for: indexPath)
            
            if indexPath.section == 0 {
                // Theme name cell
                cell.textLabel?.text = "Name"
                
                let nameField = UITextField(frame: CGRect(x: 0, y: 0, width: 150, height: 30))
                nameField.text = theme.name
                nameField.placeholder = "Enter theme name"
                nameField.textAlignment = .right
                nameField.addTarget(self, action: #selector(themeNameChanged(_:)), for: .editingChanged)
                cell.accessoryView = nameField
            } else {
                // Color selection cells
                let propertyIndex = indexPath.row + 1 // Skip "Name" which is handled separately
                let propertyName = colorProperties[propertyIndex]
                cell.textLabel?.text = propertyName
                
                let colorIndex = indexPath.row
                let color = getColorForIndex(colorIndex)
                
                let colorPreview = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
                colorPreview.backgroundColor = color
                colorPreview.layer.cornerRadius = 12
                colorPreview.layer.borderWidth = 1
                colorPreview.layer.borderColor = UIColor.lightGray.cgColor
                
                cell.accessoryView = colorPreview
                cell.accessoryType = .disclosureIndicator
            }
            
            return cell
        }
        
        @objc private func themeNameChanged(_ sender: UITextField) {
            theme.name = sender.text ?? ""
        }
        
        private func getColorForIndex(_ index: Int) -> UIColor {
            switch index {
            case 0: return theme.primaryColor
            case 1: return theme.secondaryColor
            case 2: return theme.accentColor
            case 3: return theme.backgroundColor
            case 4: return theme.textColor
            case 5: return theme.secondaryTextColor
            default: return .systemBlue
            }
        }
        
        // MARK: - UITableViewDelegate
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            
            if indexPath.section == 1 {
                let colorIndex = indexPath.row
                showColorPicker(for: colorIndex)
            }
        }
        
        private func showColorPicker(for colorIndex: Int) {
            let colorPickerVC = ColorPickerViewController()
            colorPickerVC.delegate = self
            colorPickerVC.colorIndex = colorIndex
            colorPickerVC.initialColor = getColorForIndex(colorIndex)
            navigationController?.pushViewController(colorPickerVC, animated: true)
        }
    }
    
    // MARK: - ColorPickerViewController
    class ColorPickerViewController: UIViewController {
        weak var delegate: ThemeEditViewController?
        var colorIndex: Int = 0
        var initialColor: UIColor = .systemBlue
        
        private let colorPicker = UIColorWell()
        private let previewView = UIView()
        private let hexLabel = UILabel()
        
        // Method to access ThemeEditViewController's tableView safely
        private func reloadDelegateTableView() {
            delegate?.reloadTableData()
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Setup view
            title = "Choose Color"
            view.backgroundColor = .systemBackground
            
            // Setup color picker
            colorPicker.selectedColor = initialColor
            colorPicker.supportsAlpha = false
            colorPicker.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
            colorPicker.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(colorPicker)
            
            // Setup preview view
            previewView.backgroundColor = initialColor
            previewView.layer.cornerRadius = 8
            previewView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(previewView)
            
            // Setup hex label
            hexLabel.text = initialColor.toHex
            hexLabel.textAlignment = .center
            hexLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
            hexLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hexLabel)
            
            // Layout
            NSLayoutConstraint.activate([
                colorPicker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                colorPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                colorPicker.widthAnchor.constraint(equalToConstant: 44),
                colorPicker.heightAnchor.constraint(equalToConstant: 44),
                
                previewView.topAnchor.constraint(equalTo: colorPicker.bottomAnchor, constant: 30),
                previewView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                previewView.widthAnchor.constraint(equalToConstant: 200),
                previewView.heightAnchor.constraint(equalToConstant: 200),
                
                hexLabel.topAnchor.constraint(equalTo: previewView.bottomAnchor, constant: 20),
                hexLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                hexLabel.widthAnchor.constraint(equalToConstant: 200)
            ])
            
            // Add done button
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        }
        
        @objc private func colorChanged(_ sender: UIColorWell) {
            guard let color = sender.selectedColor else { return }
            previewView.backgroundColor = color
            hexLabel.text = color.toHex
        }
        
        @objc private func doneButtonTapped() {
            // Update the color in the theme
            guard let color = colorPicker.selectedColor else { return }
            
            switch colorIndex {
            case 0: delegate?.theme.primaryColor = color
            case 1: delegate?.theme.secondaryColor = color
            case 2: delegate?.theme.accentColor = color
            case 3: delegate?.theme.backgroundColor = color
            case 4: delegate?.theme.textColor = color
            case 5: delegate?.theme.secondaryTextColor = color
            default: break
            }
            
            delegate?.updateBackgroundWithTheme()
            reloadDelegateTableView()
            
            navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Theme Preview Cell
    class ThemePreviewCell: UITableViewCell {
        private let nameLabel = UILabel()
        private let colorPreviewContainer = UIStackView()
        private let previewLabel = UILabel()
        private var backgroundPreview: UIView?
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupViews()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            // Remove the background preview when cell is reused
            backgroundPreview?.removeFromSuperview()
            backgroundPreview = nil
        }
        
        private func setupViews() {
            // Configure name label
            nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            nameLabel.textColor = .label
            
            // Configure preview label
            previewLabel.font = UIFont.systemFont(ofSize: 14)
            previewLabel.textColor = .secondaryLabel
            previewLabel.text = "Aa"
            
            // Configure color preview container
            colorPreviewContainer.axis = .horizontal
            colorPreviewContainer.distribution = .fillEqually
            colorPreviewContainer.spacing = 4
            
            // Add color blocks
            for _ in 0..<3 {
                let colorBlock = UIView()
                colorBlock.layer.cornerRadius = 4
                colorPreviewContainer.addArrangedSubview(colorBlock)
            }
            
            // Add to content view
            contentView.addSubview(nameLabel)
            contentView.addSubview(colorPreviewContainer)
            contentView.addSubview(previewLabel)
            
            // Layout constraints
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            colorPreviewContainer.translatesAutoresizingMaskIntoConstraints = false
            previewLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                
                colorPreviewContainer.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
                colorPreviewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                colorPreviewContainer.widthAnchor.constraint(equalToConstant: 100),
                colorPreviewContainer.heightAnchor.constraint(equalToConstant: 24),
                
                previewLabel.centerYAnchor.constraint(equalTo: colorPreviewContainer.centerYAnchor),
                previewLabel.leadingAnchor.constraint(equalTo: colorPreviewContainer.trailingAnchor, constant: 16),
                previewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                previewLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10)
            ])
        }
        
        func configure(with theme: ColorTheme) {
            nameLabel.text = theme.name
            
            // Update color blocks
            if let blocks = colorPreviewContainer.arrangedSubviews as? [UIView], blocks.count >= 3 {
                blocks[0].backgroundColor = theme.secondaryColor
                blocks[1].backgroundColor = theme.primaryColor
                blocks[2].backgroundColor = theme.accentColor
            }
            
            // Create a background view to show theme background color
            let backgroundView = UIView()
            backgroundView.backgroundColor = theme.backgroundColor
            backgroundView.layer.cornerRadius = 4
            
            // Important: Set the text color directly from the theme
            previewLabel.textColor = theme.textColor
            
            // Remove old background preview if it exists
            backgroundPreview?.removeFromSuperview()
            
            // Add new background preview
            previewLabel.superview?.insertSubview(backgroundView, belowSubview: previewLabel)
            self.backgroundPreview = backgroundView
            
            // Add constraints for background preview
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            if let previewSuperview = previewLabel.superview {
                NSLayoutConstraint.activate([
                    backgroundView.leadingAnchor.constraint(equalTo: previewLabel.leadingAnchor, constant: -8),
                    backgroundView.trailingAnchor.constraint(equalTo: previewLabel.trailingAnchor, constant: 8),
                    backgroundView.topAnchor.constraint(equalTo: previewLabel.topAnchor, constant: -4),
                    backgroundView.bottomAnchor.constraint(equalTo: previewLabel.bottomAnchor, constant: 4)
                ])
            }
        }
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
        delegate?.didUpdateTheme()
        dismiss(animated: true)
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(use24HourTime, forKey: "use24HourTime")
        defaults.set(showDate, forKey: "showDate")
        defaults.set(useMinimalistStyle, forKey: "useMinimalistStyle")
        defaults.set(useMonochromeIcons, forKey: "useMonochromeIcons")
        defaults.set(showMotivationalMessages, forKey: "showMotivationalMessages")
        defaults.set(textSizeMultiplier, forKey: "textSizeMultiplier")
        defaults.set(fontName, forKey: "fontName")
        
        // Theme is saved through ThemeManager
        ThemeManager.shared.currentTheme = currentTheme
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Load the current settings
        use24HourTime = defaults.bool(forKey: "use24HourTime")
        showDate = defaults.bool(forKey: "showDate")
        useMinimalistStyle = defaults.bool(forKey: "useMinimalistStyle")
        useMonochromeIcons = defaults.bool(forKey: "useMonochromeIcons")
        showMotivationalMessages = defaults.bool(forKey: "showMotivationalMessages")
        
        // Load text settings with defaults if not set
        textSizeMultiplier = defaults.float(forKey: "textSizeMultiplier")
        if textSizeMultiplier == 0 { textSizeMultiplier = 1.0 } // Handle default case
        
        if let savedFontName = defaults.string(forKey: "fontName") {
            fontName = savedFontName
        }
        
        // Load theme from ThemeManager
        currentTheme = ThemeManager.shared.currentTheme
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
        return 7
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
            return 1 // Wellness settings
        case 4:
            return 2 // Text size and font settings
        case 5:
            return 3 // Theme settings (Select theme, Custom theme, Create new theme)
        case 6:
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
            return "Wellness"
        case 4:
            return "Text Settings"
        case 5:
            return "Theme Settings"
        case 6:
            return "Home Screen Apps"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 6 {
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
        return section == 4 ? 44 : UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 3:
            return "Motivational messages will appear on your home screen to encourage digital wellbeing."
        case 4:
            return "Adjust the text size and font used throughout the app."
        case 5:
            return "Choose a color theme or create your own custom theme."
        case 6:
            return "Toggle which apps appear on your home screen."
        default:
            return nil
        }
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
        case 3: // Wellness settings
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Show Motivational Messages"
                switchView.isOn = showMotivationalMessages
                switchView.tag = 4
                switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            default:
                break
            }
        case 4: // Text Settings
            cell.accessoryView = nil // Clear switch for these cells
            
            switch indexPath.row {
            case 0: // Text Size slider
                cell.textLabel?.text = "Text Size"
                
                // Create slider for text size
                let slider = UISlider(frame: CGRect(x: 0, y: 0, width: 150, height: 30))
                slider.minimumValue = 0.7
                slider.maximumValue = 1.5
                slider.value = textSizeMultiplier
                slider.addTarget(self, action: #selector(textSizeChanged(_:)), for: .valueChanged)
                cell.accessoryView = slider
                
            case 1: // Font selection
                cell.textLabel?.text = "Font"
                cell.accessoryType = .disclosureIndicator
                
                // Show the currently selected font name
                let fontLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 120, height: 20))
                fontLabel.text = fontName
                fontLabel.textAlignment = .right
                fontLabel.font = UIFont.systemFont(ofSize: 14)
                fontLabel.textColor = .secondaryLabel
                cell.accessoryView = fontLabel
                
            default:
                break
            }
        case 5: // Theme settings
            cell.accessoryView = nil
            switch indexPath.row {
            case 0: // Theme selection
                cell.textLabel?.text = "Current Theme"
                cell.accessoryType = .disclosureIndicator
                
                let themeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 120, height: 20))
                themeLabel.text = currentTheme.name
                themeLabel.textAlignment = .right
                themeLabel.font = UIFont.systemFont(ofSize: 14)
                themeLabel.textColor = .secondaryLabel
                cell.accessoryView = themeLabel
                
            case 1: // Edit custom themes
                cell.textLabel?.text = "Edit Custom Themes"
                cell.accessoryType = .disclosureIndicator
                
            case 2: // Create new theme
                cell.textLabel?.text = "Create New Theme"
                cell.accessoryType = .disclosureIndicator
                
            default:
                break
            }
            
        case 6: // App selection
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
        case 4:
            showMotivationalMessages = sender.isOn
        default:
            break
        }
    }
    
    @objc func textSizeChanged(_ sender: UISlider) {
        textSizeMultiplier = sender.value
        // Update preview in real-time if needed
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
        tableView.reloadSections(IndexSet(integer: 5), with: .automatic)
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
        return indexPath.section == 6
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        // During reordering mode, don't show delete buttons
        if indexPath.section == 6 && tableView.isEditing {
            return .none
        }
        return .delete
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Only allow moving in the apps section
        return indexPath.section == 6
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Ensure we're only moving within the apps section
        guard sourceIndexPath.section == 6 && destinationIndexPath.section == 6 else { return }
        
        // Update the app order in our data model
        let movedApp = allApps.remove(at: sourceIndexPath.row)
        allApps.insert(movedApp, at: destinationIndexPath.row)
        
        // Save the updated order
        saveAppSelectionsToUserDefaults()
        
        // Notify the home screen of the change
        delegate?.didUpdateAppSelections(allApps)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Show font picker when font cell is selected
        if indexPath.section == 4 && indexPath.row == 1 {
            showFontSelectionMenu(for: indexPath)
        } else if indexPath.section == 5 {
            switch indexPath.row {
            case 0: // Theme selection
                showThemeSelectionMenu()
            case 1: // Edit custom themes
                showCustomThemesMenu()
            case 2: // Create new theme
                showCreateThemeMenu()
            default:
                break
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func showFontSelectionMenu(for indexPath: IndexPath) {
        let fontVC = FontSelectionViewController()
        fontVC.delegate = self
        let navController = UINavigationController(rootViewController: fontVC)
        present(navController, animated: true)
    }
    
    // MARK: - Font Selection View Controller
    class FontSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
        private let tableView = UITableView()
        weak var delegate: SettingsViewController?
        
        // Available fonts
        private let fonts = [
            "System",
            "Helvetica Neue",
            "Arial",
            "Avenir",
            "Georgia",
            "Futura",
            "Times New Roman",
            "San Francisco",
            "Courier"
        ]
        
        // Preview text to show
        private let previewText = "AaBbCcDdEeFf 123"
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Setup navigation bar
            title = "Select Font"
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
            
            // Setup table view
            view.backgroundColor = .systemBackground
            tableView.dataSource = self
            tableView.delegate = self
            tableView.register(FontPreviewCell.self, forCellReuseIdentifier: "FontPreviewCell")
            view.addSubview(tableView)
            
            // Layout
            tableView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        @objc private func cancelButtonTapped() {
            dismiss(animated: true)
        }
        
        // MARK: - UITableViewDataSource
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return fonts.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "FontPreviewCell", for: indexPath) as? FontPreviewCell else {
                return UITableViewCell()
            }
            
            let fontName = fonts[indexPath.row]
            cell.configure(with: fontName, previewText: previewText)
            
            // Check if this is the currently selected font
            if let currentFont = delegate?.fontName, currentFont == fontName {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            
            return cell
        }
        
        // MARK: - UITableViewDelegate
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let selectedFont = fonts[indexPath.row]
            delegate?.fontName = selectedFont
            delegate?.tableView.reloadData()
            dismiss(animated: true)
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 70 // Taller rows to fit font preview
        }
    }
    
    // MARK: - Font Preview Cell
    class FontPreviewCell: UITableViewCell {
        private let nameLabel = UILabel()
        private let previewLabel = UILabel()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupViews()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupViews() {
            // Configure name label
            nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            nameLabel.textColor = .secondaryLabel
            
            // Configure preview label
            previewLabel.font = UIFont.systemFont(ofSize: 18)
            previewLabel.textColor = .label
            
            // Add to content view
            contentView.addSubview(nameLabel)
            contentView.addSubview(previewLabel)
            
            // Layout constraints
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            previewLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                
                previewLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
                previewLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                previewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                previewLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
            ])
        }
        
        func configure(with fontName: String, previewText: String) {
            nameLabel.text = fontName
            previewLabel.text = previewText
            
            // Set the preview text font
            if fontName == "System" {
                previewLabel.font = UIFont.systemFont(ofSize: 18)
            } else {
                previewLabel.font = UIFont(name: fontName, size: 18) ?? UIFont.systemFont(ofSize: 18)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == 6 && editingStyle == .delete {
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
