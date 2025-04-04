//
//  SettingsViewController.swift
//  CoreLaunch
//
//  Created by x on 4/2/25.
//

import UIKit
import Foundation

protocol SettingsDelegate: AnyObject {
    func didUpdateSettings()
    func didUpdateAppSelections(_ updatedApps: [AppItem])
    func didUpdateTheme()
}

// MARK: - ThemeScannerDelegate Protocol Extension
extension SettingsViewController {
    func didScanTheme(_ theme: ColorTheme) {
        // Implementation to handle scanned themes
        didImportTheme(theme)
    }
}

class SettingsViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    weak var delegate: SettingsDelegate?
    
    // Profile management
    private var profiles: [Profile] = []
    
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSettings()
        loadApps()
        setupUI()
        configureTableView()
        
        // Set the view title
        title = "Settings"
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("DEBUG: SettingsViewController viewWillDisappear - ensuring color persistence")
        
        // Force save app selections to UserDefaults as we leave
        saveAppSelectionsToUserDefaults()
        
        // Explicitly notify delegate to update colors
        delegate?.didUpdateAppSelections(allApps)
    }
    
    
    // MARK: - Theme Selection
    
    private func showThemeSelectionMenu() {
        let themeVC = ThemeSelectionViewController()
        themeVC.delegate = self
        themeVC.selectedTheme = currentTheme
        themeVC.theme = currentTheme // Initialize theme property
        let navController = UINavigationController(rootViewController: themeVC)
        present(navController, animated: true)
    }
    
    private func showCustomThemesMenu() {
        let customThemesVC = CustomThemesViewController()
        customThemesVC.delegate = self
        let navController = UINavigationController(rootViewController: customThemesVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    private func showCreateThemeMenu() {
        let createThemeVC = ThemeEditViewController()
        createThemeVC.delegate = self
        let navController = UINavigationController(rootViewController: createThemeVC)
        present(navController, animated: true)
    }
    
    // MARK: - Theme Share Delegate Method
    func didImportTheme(_ theme: ColorTheme) {
        // Register the imported theme
        ThemeManager.shared.registerCustomTheme(theme)
        
        // Show confirmation
        let alert = UIAlertController(
            title: "Theme Imported",
            message: "Successfully imported theme: \(theme.name)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Theme Selection View Controller
    class ThemeSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ThemeShareDelegate, ThemeScannerDelegate {
        private let tableView = UITableView()
        private let newThemeCell = "NewThemeCell"
        private let themeCell = "ThemePreviewCell"
        weak var delegate: SettingsViewController?
        var selectedTheme: ColorTheme!
        private var allThemes: [ColorTheme] = []
        var theme: ColorTheme! // Make theme accessible
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            allThemes = ThemeManager.shared.getAllThemes()
            
            // Setup navigation bar
            title = "Select Theme"
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
            
            // Add scan QR code button
            let scanButton = UIBarButtonItem(image: UIImage(systemName: "qrcode.viewfinder"), style: .plain, target: self, action: #selector(scanQRButtonTapped))
            navigationItem.rightBarButtonItem = scanButton
            
            // Setup table view
            view.backgroundColor = .systemBackground
            tableView.dataSource = self
            tableView.delegate = self
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: newThemeCell)
            tableView.register(ThemePreviewCell.self, forCellReuseIdentifier: themeCell)
            tableView.allowsSelection = true
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
        
        @objc private func scanQRButtonTapped() {
            let scanVC = ThemeScannerViewController()
            scanVC.delegate = self
            present(scanVC, animated: true)
        }
        
        @objc private func shareButtonTapped() {
            let shareVC = ThemeShareViewController()
            shareVC.theme = selectedTheme // Use selectedTheme instead of theme
            shareVC.delegate = self
            
            let navController = UINavigationController(rootViewController: shareVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
        
        @objc private func shareThemeButtonTapped(_ sender: UIButton) {
            let index = sender.tag
            guard index < allThemes.count else { return }
            
            let theme = allThemes[index]
            let shareVC = ThemeShareViewController()
            shareVC.theme = theme
            shareVC.delegate = self
            
            let navController = UINavigationController(rootViewController: shareVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
        
        @objc private func shareDefaultTheme() {
            // Create a default theme template with the colors shown in the UI
            let defaultTheme = ColorTheme(
                name: "New Theme",
                primaryColor: .systemBlue,
                secondaryColor: .systemGreen,
                accentColor: .systemOrange,
                backgroundColor: .black,
                textColor: .white,
                secondaryTextColor: .lightGray
            )
            
            // Create and present share view controller
            let shareVC = ThemeShareViewController()
            shareVC.theme = defaultTheme
            shareVC.delegate = self
            
            let navController = UINavigationController(rootViewController: shareVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
        
        // MARK: - ThemeShareDelegate
        
        func didImportTheme(_ theme: ColorTheme) {
            // Add the imported theme to custom themes
            ThemeManager.shared.registerCustomTheme(theme)
            
            // Refresh the themes list by getting fresh data
            let customThemes = ThemeManager.shared.loadCustomThemes()
            tableView.reloadData()
            
            // Show confirmation
            let alert = UIAlertController(
                title: "Theme Imported",
                message: "Successfully imported theme: \(theme.name)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
        
        // MARK: - ThemeScannerDelegate
        
        func didScanTheme(_ theme: ColorTheme) {
            // Same implementation as didImportTheme
            didImportTheme(theme)
        }
        
        // MARK: - UITableViewDataSource
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return allThemes.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            // Use the same cell style as in CustomThemesViewController
            let cell = tableView.dequeueReusableCell(withIdentifier: newThemeCell, for: indexPath)
            
            // Clear any existing subviews from reused cells
            for subview in cell.contentView.subviews {
                subview.removeFromSuperview()
            }
            
            let theme = allThemes[indexPath.row]
            
            // Create label for theme name text
            let titleLabel = UILabel()
            titleLabel.text = theme.name
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(titleLabel)
            
            // Create a stack view for the color blocks
            let colorStackView = UIStackView()
            colorStackView.axis = .horizontal
            colorStackView.distribution = .fillEqually
            colorStackView.spacing = 4
            colorStackView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add color blocks
            let colors: [UIColor] = [theme.primaryColor, theme.secondaryColor, theme.accentColor, theme.backgroundColor]
            for (index, color) in colors.enumerated() {
                let colorBlock = UIView()
                colorBlock.backgroundColor = color
                colorBlock.layer.cornerRadius = 4
                colorStackView.addArrangedSubview(colorBlock)
                
                // Add "Aa" label to the last color block
                if index == 3 {
                    let textLabel = UILabel()
                    textLabel.text = "Aa"
                    textLabel.textColor = theme.textColor
                    textLabel.textAlignment = .center
                    textLabel.font = UIFont.systemFont(ofSize: 14)
                    textLabel.translatesAutoresizingMaskIntoConstraints = false
                    colorBlock.addSubview(textLabel)
                    
                    NSLayoutConstraint.activate([
                        textLabel.centerXAnchor.constraint(equalTo: colorBlock.centerXAnchor),
                        textLabel.centerYAnchor.constraint(equalTo: colorBlock.centerYAnchor)
                    ])
                }
            }
            
            // Add the stack view to the cell
            cell.contentView.addSubview(colorStackView)
            
            // Configure constraints to match the Custom Themes layout
            NSLayoutConstraint.activate([
                // Title label constraints
                titleLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                
                // Color stack constraints
                colorStackView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
                colorStackView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                colorStackView.heightAnchor.constraint(equalToConstant: 24),
                colorStackView.widthAnchor.constraint(equalToConstant: 120)
            ])
            
            // Check if this is the currently selected theme
            if theme.name == selectedTheme.name {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            
            cell.selectionStyle = .default
            
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
            return 80 // Same height as in Custom Themes view
        }
    }
    
    // MARK: - Custom Themes View Controller
    class CustomThemesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ThemeShareDelegate, ThemeScannerDelegate, UITableViewDragDelegate, UITableViewDropDelegate {
        private let newThemeCell = "NewThemeCell"
        private let themeCell = "ThemePreviewCell"
        private let tableView = UITableView()
        weak var delegate: SettingsViewController?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Setup navigation bar
            title = "Custom Themes"
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
            
            // Add scan QR code button
            let scanButton = UIBarButtonItem(image: UIImage(systemName: "qrcode.viewfinder"), style: .plain, target: self, action: #selector(scanQRButtonTapped))
            navigationItem.rightBarButtonItem = scanButton
            
            // Setup table view
            view.backgroundColor = .systemBackground
            tableView.dataSource = self
            tableView.delegate = self
            tableView.dragDelegate = self
            tableView.dropDelegate = self
            tableView.register(ThemePreviewCell.self, forCellReuseIdentifier: themeCell)
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: newThemeCell)
            tableView.allowsSelection = true
            tableView.isEditing = false
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
        
        @objc private func scanQRButtonTapped() {
            let scanVC = ThemeScannerViewController()
            scanVC.delegate = self
            present(scanVC, animated: true)
        }
        
        @objc private func shareThemeButtonTapped(_ sender: UIButton) {
            let index = sender.tag
            let customThemes = getFilteredCustomThemes()
            guard index < customThemes.count else { return }
            
            let theme = customThemes[index]
            let shareVC = ThemeShareViewController()
            shareVC.theme = theme
            shareVC.delegate = self
            
            let navController = UINavigationController(rootViewController: shareVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
        
        // MARK: - ThemeShareDelegate
        
        func didImportTheme(_ theme: ColorTheme) {
            // Register the imported theme
            ThemeManager.shared.registerCustomTheme(theme)
            
            // Show confirmation
            let alert = UIAlertController(
                title: "Theme Imported",
                message: "Successfully imported theme: \(theme.name)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            
            // Reload table view to show the new theme
            tableView.reloadData()
        }
        
        // MARK: - ThemeScannerDelegate
        
        func didScanTheme(_ theme: ColorTheme) {
            // Same implementation as didImportTheme
            didImportTheme(theme)
        }
        
        // MARK: - UITableViewDataSource
        
        private func getFilteredCustomThemes() -> [ColorTheme] {
            // Filter out any theme that also has the name "New Theme" to avoid duplication
            return ThemeManager.shared.loadCustomThemes().filter { $0.name != "New Theme" }
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return getFilteredCustomThemes().count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            // Regular custom theme cells - using same layout as New Theme cell
            let cell = tableView.dequeueReusableCell(withIdentifier: newThemeCell, for: indexPath)
            
            // Clear any existing subviews from reused cells
            for subview in cell.contentView.subviews {
                subview.removeFromSuperview()
            }
            
            let customThemes = getFilteredCustomThemes()
            let theme = customThemes[indexPath.row] // Adjust index for the "New Theme" row
            
            // Create label for theme name text
            let titleLabel = UILabel()
            titleLabel.text = theme.name
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(titleLabel)
            
            // Create a stack view for the color blocks
            let colorStackView = UIStackView()
            colorStackView.axis = .horizontal
            colorStackView.distribution = .fillEqually
            colorStackView.spacing = 4
            colorStackView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add color blocks
            let colors: [UIColor] = [theme.primaryColor, theme.secondaryColor, theme.accentColor, theme.backgroundColor]
            for (index, color) in colors.enumerated() {
                let colorBlock = UIView()
                colorBlock.backgroundColor = color
                colorBlock.layer.cornerRadius = 4
                colorStackView.addArrangedSubview(colorBlock)
                
                // Add "Aa" label to the last color block
                if index == 3 {
                    let textLabel = UILabel()
                    textLabel.text = "Aa"
                    textLabel.textColor = theme.textColor
                    textLabel.textAlignment = .center
                    textLabel.font = UIFont.systemFont(ofSize: 14)
                    textLabel.translatesAutoresizingMaskIntoConstraints = false
                    colorBlock.addSubview(textLabel)
                    
                    NSLayoutConstraint.activate([
                        textLabel.centerXAnchor.constraint(equalTo: colorBlock.centerXAnchor),
                        textLabel.centerYAnchor.constraint(equalTo: colorBlock.centerYAnchor)
                    ])
                }
            }
            
            // Add the stack view to the cell
            cell.contentView.addSubview(colorStackView)
            
            // Configure constraints to match the New Theme row layout
            NSLayoutConstraint.activate([
                // Title label constraints
                titleLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                
                // Color stack constraints
                colorStackView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
                colorStackView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                colorStackView.heightAnchor.constraint(equalToConstant: 24),
                colorStackView.widthAnchor.constraint(equalToConstant: 120)
            ])
            
            cell.selectionStyle = .default
            
            return cell
        }
        
        // MARK: - UITableViewDelegate
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let customThemes = getFilteredCustomThemes()
            let theme = customThemes[indexPath.row]
            let editVC = ThemeEditViewController()
            editVC.delegate = delegate
            editVC.theme = theme
            editVC.isThemeEditing = true
            navigationController?.pushViewController(editVC, animated: true)
        }
        
        func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        // Add this method to handle tableView editing actions
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                let customThemes = getFilteredCustomThemes()
                let themeToDelete = customThemes[indexPath.row]
                ThemeManager.shared.deleteCustomTheme(named: themeToDelete.name)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                if delegate?.currentTheme.name == themeToDelete.name {
                    delegate?.currentTheme = ColorTheme.defaultTheme
                    delegate?.tableView.reloadData()
                }
            }
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 80
        }
        
        // MARK: - UITableViewDragDelegate
        
        @objc private func shareDefaultTheme() {
            // Create a default theme template with the colors shown in the UI
            let defaultTheme = ColorTheme(
                name: "New Theme",
                primaryColor: .systemBlue,
                secondaryColor: .systemGreen,
                accentColor: .systemOrange,
                backgroundColor: .black,
                textColor: .white,
                secondaryTextColor: .lightGray
            )
            
            // Create and present share view controller
            let shareVC = ThemeShareViewController()
            shareVC.theme = defaultTheme
            shareVC.delegate = self
            
            let navController = UINavigationController(rootViewController: shareVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
        
        func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
                let customThemes = getFilteredCustomThemes()
                let theme = customThemes[indexPath.row]
                let itemProvider = NSItemProvider(object: theme.name as NSString)
                let dragItem = UIDragItem(itemProvider: itemProvider)
                dragItem.localObject = theme
                return [dragItem]
            }
        
        // MARK: - UITableViewDropDelegate
        
        func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
            // Implementation for drop handling if needed
            // Since we're primarily using the built-in editing mode for deletion,
            // we can leave this minimal for now
            return
        }
        
        func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
    }
    
    // MARK: - Theme Edit View Controller
    class ThemeEditViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ThemeShareDelegate, ThemeScannerDelegate {
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
            
            // Set navigation bar appearance based on background color
            let isDarkBackground = !theme.backgroundColor.isLight
            if isDarkBackground {
                navigationController?.navigationBar.tintColor = .white
                navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            } else {
                navigationController?.navigationBar.tintColor = .systemBlue
                navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            }
            
            // No share button in navigation bar
            
            // Setup table view
            view.backgroundColor = .systemBackground
            tableView.dataSource = self
            tableView.delegate = self
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ColorCell")
            view.addSubview(tableView)
            
            // Add a Share button if editing an existing theme
            if isThemeEditing {
                let shareThemeButton = UIButton(type: .system)
                shareThemeButton.setTitle("Share Theme", for: .normal)
                // Create properly sized share icon with correct proportions
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium, scale: .default)
                let shareIcon = UIImage(systemName: "square.and.arrow.up", withConfiguration: symbolConfig)
                
                // Use a stack view instead of relying on imageEdgeInsets
                let iconView = UIImageView(image: shareIcon)
                iconView.contentMode = .scaleAspectFit
                iconView.tintColor = theme.primaryColor.isLight ? .black : .white
                
                let titleLabel = UILabel()
                titleLabel.text = "Share Theme"
                titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
                titleLabel.textColor = theme.primaryColor.isLight ? .black : .white
                
                let stackView = UIStackView(arrangedSubviews: [iconView, titleLabel])
                stackView.axis = .horizontal
                stackView.alignment = .center
                stackView.spacing = 8
                stackView.distribution = .fillProportionally
                
                // Remove title and image from button and use stack view instead
                shareThemeButton.setTitle(nil, for: .normal)
                shareThemeButton.setImage(nil, for: .normal)
                
                // Add stack view to button
                stackView.translatesAutoresizingMaskIntoConstraints = false
                shareThemeButton.addSubview(stackView)
                
                // Center the stack view in the button
                NSLayoutConstraint.activate([
                    stackView.centerXAnchor.constraint(equalTo: shareThemeButton.centerXAnchor),
                    stackView.centerYAnchor.constraint(equalTo: shareThemeButton.centerYAnchor)
                ])
                shareThemeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
                shareThemeButton.backgroundColor = theme.primaryColor
                shareThemeButton.tintColor = theme.primaryColor.isLight ? .black : .white
                shareThemeButton.setTitleColor(theme.primaryColor.isLight ? .black : .white, for: .normal)
                shareThemeButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
                shareThemeButton.layer.cornerRadius = 10
                shareThemeButton.layer.shadowColor = UIColor.black.cgColor
                shareThemeButton.layer.shadowOffset = CGSize(width: 0, height: 2)
                shareThemeButton.layer.shadowRadius = 4
                shareThemeButton.layer.shadowOpacity = 0.2
                shareThemeButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
                shareThemeButton.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(shareThemeButton)
                
                NSLayoutConstraint.activate([
                    shareThemeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                    shareThemeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    shareThemeButton.widthAnchor.constraint(equalToConstant: 200),
                    shareThemeButton.heightAnchor.constraint(equalToConstant: 44)
                ])
                
                // Adjust table view height to accommodate the button
                tableView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                    tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    tableView.bottomAnchor.constraint(equalTo: shareThemeButton.topAnchor, constant: -20)
                ])
            } else {
                // Layout for table view without the share button
                tableView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                    tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
            }
            
            // Add color picker view if needed
            updateBackgroundWithTheme()
        }
        
        @objc private func cancelButtonTapped() {
            dismiss(animated: true)
        }
        
        @objc private func scanQRButtonTapped() {
            let scanVC = ThemeScannerViewController()
            scanVC.delegate = self
            present(scanVC, animated: true)
        }
        
        // MARK: - ThemeShareDelegate
        
        func didImportTheme(_ theme: ColorTheme) {
            // Register the imported theme
            ThemeManager.shared.registerCustomTheme(theme)
            
            // Show confirmation
            let alert = UIAlertController(
                title: "Theme Imported",
                message: "Successfully imported theme: \(theme.name)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
        
        // MARK: - ThemeScannerDelegate
        
        func didScanTheme(_ theme: ColorTheme) {
            // Same implementation as didImportTheme
            didImportTheme(theme)
        }
        
        @objc private func shareButtonTapped() {
            let shareVC = ThemeShareViewController()
            shareVC.theme = theme
            shareVC.delegate = self
            
            let navController = UINavigationController(rootViewController: shareVC)
            present(navController, animated: true)
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
            
            // Set appropriate cell text colors based on background color darkness
            let isDarkBackground = !theme.backgroundColor.isLight
            
            // If background is dark, ensure text is visible
            if isDarkBackground {
                // Apply text colors to table view
                tableView.separatorColor = .lightGray
                
                // Force refresh all visible cells
                for cell in tableView.visibleCells {
                    cell.textLabel?.textColor = .white
                    cell.detailTextLabel?.textColor = .lightGray
                    
                    // Update any text fields in the cells
                    for subview in cell.contentView.subviews {
                        if let textField = subview as? UITextField {
                            textField.textColor = .white
                        }
                    }
                    
                    // Ensure accessory views are visible
                    if let colorPreview = cell.accessoryView as? UIView, colorPreview.frame.size.width == 24 && colorPreview.frame.size.height == 24 {
                        colorPreview.layer.borderColor = UIColor.white.cgColor
                    }
                }
            }
            
            // Update share button color if it exists
            if isThemeEditing {
                // Find the share button by looking for a UIButton that has nil title (since we removed the title)
                if let shareButton = view.subviews.first(where: {
                    if let button = $0 as? UIButton,
                       button.subviews.contains(where: { $0 is UIStackView }) {
                        return true
                    }
                    return false
                }) as? UIButton {
                    shareButton.backgroundColor = theme.primaryColor
                    let textColor = theme.primaryColor.isLight ? UIColor.black : UIColor.white
                    shareButton.tintColor = textColor
                    shareButton.setTitleColor(textColor, for: .normal)
                }
            }
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
            
            // Set cell background color to maintain theme preview
            cell.backgroundColor = theme.backgroundColor
            
            // Determine if background is dark to set appropriate text colors
            let isDarkBackground = !theme.backgroundColor.isLight
            let textColor = isDarkBackground ? UIColor.white : UIColor.black
            let secondaryTextColor = isDarkBackground ? UIColor.lightGray : UIColor.darkGray
            
            // Apply text color
            cell.textLabel?.textColor = textColor
            cell.detailTextLabel?.textColor = secondaryTextColor
            
            if indexPath.section == 0 {
                // Theme name cell
                cell.textLabel?.text = "Name"
                
                let nameField = UITextField(frame: CGRect(x: 0, y: 0, width: 150, height: 30))
                nameField.text = theme.name
                nameField.placeholder = "Enter theme name"
                nameField.textAlignment = .right
                nameField.textColor = textColor
                nameField.backgroundColor = isDarkBackground ? UIColor.darkGray : UIColor.white
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
                colorPreview.layer.borderColor = isDarkBackground ? UIColor.white.cgColor : UIColor.lightGray.cgColor
                
                cell.accessoryView = colorPreview
                cell.accessoryType = .disclosureIndicator
                
                // Use a contrasting tint color for the disclosure indicator
                cell.tintColor = textColor
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
            
            // Use a navigation controller to present the color picker
            let navController = UINavigationController(rootViewController: colorPickerVC)
            present(navController, animated: true, completion: nil)
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
            
            // Add cancel button to navigation bar
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(backButtonTapped))
            
            // Add done button to navigation bar
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
            
            // Setup color picker
            colorPicker.selectedColor = initialColor
            colorPicker.supportsAlpha = false
            colorPicker.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
            colorPicker.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(colorPicker)
            
            // Setup preview view
            previewView.backgroundColor = initialColor
            previewView.layer.cornerRadius = 8
            previewView.layer.borderWidth = 1
            previewView.layer.borderColor = initialColor.isLight ? UIColor.black.cgColor : UIColor.white.cgColor
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
            
            // We're now using the navigation bar buttons instead of this separate done button
        }
        
        @objc private func colorChanged(_ sender: UIColorWell) {
            guard let color = sender.selectedColor else { return }
            previewView.backgroundColor = color
            hexLabel.text = color.toHex
            
            // Update border color based on the brightness of the selected color
            previewView.layer.borderWidth = 1
            previewView.layer.borderColor = color.isLight ? UIColor.black.cgColor : UIColor.white.cgColor
        }
        
        @objc private func backButtonTapped() {
            dismiss(animated: true, completion: nil)
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
            
            dismiss(animated: true, completion: nil)
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
            
            // Add color blocks - all the same size
            for _ in 0..<3 {
                let colorBlock = UIView()
                colorBlock.layer.cornerRadius = 4
                colorBlock.layer.borderWidth = 1
                colorBlock.layer.borderColor = UIColor.lightGray.cgColor
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
                previewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -50),
                previewLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10)
            ])
        }
        
        func configure(with theme: ColorTheme) {
            nameLabel.text = theme.name
            
            // Update color blocks
            if let blocks = colorPreviewContainer.arrangedSubviews as? [UIView], blocks.count >= 3 {
                // Secondary color
                blocks[0].backgroundColor = theme.secondaryColor
                blocks[0].layer.borderColor = theme.secondaryColor.isLight ? UIColor.black.cgColor : UIColor.white.cgColor
                
                // Primary color
                blocks[1].backgroundColor = theme.primaryColor
                blocks[1].layer.borderColor = theme.primaryColor.isLight ? UIColor.black.cgColor : UIColor.white.cgColor
                
                // Accent color
                blocks[2].backgroundColor = theme.accentColor
                blocks[2].layer.borderColor = theme.accentColor.isLight ? UIColor.black.cgColor : UIColor.white.cgColor
            }
            
            // Create a background view to show theme background color
            let backgroundView = UIView()
            backgroundView.backgroundColor = theme.backgroundColor
            backgroundView.layer.cornerRadius = 4
            backgroundView.layer.borderWidth = 1
            backgroundView.layer.borderColor = theme.backgroundColor.isLight ? UIColor.black.cgColor : UIColor.white.cgColor
            
            // Important: Set the text color directly from the theme
            previewLabel.textColor = theme.textColor
            previewLabel.text = "Aa"  // Ensure text is always "Aa"
            
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
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        // Use a plain left bar button item, like in AchievementsView
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        // Table view
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsSubtitleCell")
        // Register a value1 style cell for the app items (right-aligned detail text)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsValueCell")
        tableView.isEditing = false // Will be toggled to true for the apps section
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        // Save settings before dismissing
        saveSettings()
        
        // Force save app selections to ensure they're available immediately
        saveAppSelectionsToUserDefaults()
        
        // Notify delegate to update all settings
        delegate?.didUpdateSettings()
        delegate?.didUpdateTheme()
        delegate?.didUpdateAppSelections(allApps)
        
        // Take snapshot to freeze the current view during transition
        if let parentView = navigationController?.presentingViewController?.view {
            let snapshot = parentView.snapshotView(afterScreenUpdates: true)
            if let snapshot = snapshot {
                snapshot.frame = parentView.frame
                parentView.addSubview(snapshot)
                
                // Dismiss with completion to remove snapshot
                navigationController?.dismiss(animated: true) {
                    snapshot.removeFromSuperview()
                }
            } else {
                navigationController?.dismiss(animated: true)
            }
        } else {
            navigationController?.dismiss(animated: true)
        }
    }
    
    private func showAddProfileDialog() {
        let alert = UIAlertController(
            title: "New Profile",
            message: "Enter a name for your new settings profile",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Profile Name"
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let self = self, let textField = alert.textFields?.first,
                  let profileName = textField.text, !profileName.isEmpty else {
                return
            }
            
            // Create new profile with current settings
            let newProfile = ProfileManager.shared.createProfile(name: profileName)
            
            // Switch to the new profile
            if let index = ProfileManager.shared.profiles.firstIndex(where: { $0.id == newProfile.id }) {
                ProfileManager.shared.switchToProfile(at: index)
            }
            
            // Refresh UI
            self.loadSettings()
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(createAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
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
        
        // Update current profile
        ProfileManager.shared.updateActiveProfile()
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
        
        // Refresh profiles list
        profiles = ProfileManager.shared.profiles
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
extension SettingsViewController: UITableViewDataSource, UITableViewDelegate, UIColorPickerViewControllerDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 9
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return ProfileManager.shared.profiles.count + 1 // Profiles + Add New Profile
        case 1:
            return 2 // Time settings
        case 2:
            return 1 // Appearance settings
        case 3:
            return 1 // Icon settings
        case 4:
            return 1 // Wellness settings
        case 5:
            return 2 // Text size and font settings
        case 6:
            return 3 // Theme settings (Select theme, Custom theme, Create new theme)
        case 7:
            return 2 // Focus & Mindfulness (Focus Mode and Breathing Room)
        case 8:
            return allApps.count // App selection
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Profiles"
        case 1:
            return "Time Display"
        case 2:
            return "Appearance"
        case 3:
            return "App Icons"
        case 4:
            return "Wellness"
        case 5:
            return "Text Settings"
        case 6:
            return "Theme Settings"
        case 7:
            return "Focus & Mindfulness"
        case 8:
            return "HOME SCREEN APPS"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 8 {
            // Create a header with a button to toggle edit mode
            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 40))
            
            let titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.text = "HOME SCREEN APPS"
            titleLabel.font = UIFont.systemFont(ofSize: 13) // Match other section headers
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
        return section == 4 || section == 8 ? 44 : UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Create and switch between different setting profiles."
        case 4:
            return "Motivational messages will appear on your home screen to encourage digital wellbeing."
        case 5:
            return "Adjust the text size and font used throughout the app."
        case 6:
            return "Choose a color theme or create your own custom theme."
        case 7:
            return "Tools to help you stay focused and mindful when using your apps."
        case 8:
            return "Toggle which apps appear on your home screen."
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Let the footer height be determined by its content
        return UITableView.automaticDimension
    }
    
    // Using titleForFooterInSection instead of custom views for better text handling
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        cell.selectionStyle = .none
        
        // Reset any previous image
        cell.imageView?.image = nil
        
        let switchView = UISwitch()
        cell.accessoryView = switchView
        
        switch indexPath.section {
        case 0: // Profiles section
            cell.accessoryView = nil
            
            if indexPath.row < ProfileManager.shared.profiles.count {
                // Profile cell
                let profile = ProfileManager.shared.profiles[indexPath.row]
                cell.textLabel?.text = profile.name
                
                // Check if this is the active profile
                if indexPath.row == ProfileManager.shared.activeProfileIndex {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
                
                cell.selectionStyle = .default
            } else {
                // Add new profile cell
                cell.textLabel?.text = "Add New Profile"
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            }
            
        case 1:
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
        case 2:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Minimalist Style"
                switchView.isOn = useMinimalistStyle
                switchView.tag = 2
                switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            default:
                break
            }
        case 3:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Monochrome App Icons"
                switchView.isOn = useMonochromeIcons
                switchView.tag = 3
                switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            default:
                break
            }
        case 4: // Wellness settings
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Show Motivational Messages"
                switchView.isOn = showMotivationalMessages
                switchView.tag = 4
                switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            default:
                break
            }
        case 5: // Text Settings
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
                let fontLabel = UILabel()
                fontLabel.text = fontName
                fontLabel.textAlignment = .right
                fontLabel.font = UIFont.systemFont(ofSize: 14)
                fontLabel.textColor = .secondaryLabel
                
                // Size the label to fit content with some padding
                fontLabel.sizeToFit()
                let labelWidth = min(max(fontLabel.frame.width + 10, 120), 200) // Min 120, max 200 width
                fontLabel.frame = CGRect(x: 0, y: 0, width: labelWidth, height: 20)
                cell.accessoryView = fontLabel
                
            default:
                break
            }
        case 6: // Theme settings
            cell.accessoryView = nil
            switch indexPath.row {
            case 0: // Theme selection
                cell.textLabel?.text = "Current Theme"
                
                // Add a constraint based approach to show both text and arrow
                let valueLabel = UILabel()
                valueLabel.text = currentTheme.name
                valueLabel.textAlignment = .right
                valueLabel.font = UIFont.systemFont(ofSize: 16)
                valueLabel.textColor = .secondaryLabel
                valueLabel.translatesAutoresizingMaskIntoConstraints = false
                
                // Create a container view for the value and arrow
                let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
                containerView.addSubview(valueLabel)
                
                // Create a right arrow image
                let arrowImage = UIImageView(image: UIImage(systemName: "chevron.right"))
                arrowImage.tintColor = .tertiaryLabel
                arrowImage.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(arrowImage)
                
                // Set constraints
                NSLayoutConstraint.activate([
                    valueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    valueLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                    
                    arrowImage.leadingAnchor.constraint(equalTo: valueLabel.trailingAnchor, constant: 8),
                    arrowImage.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    arrowImage.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                    arrowImage.widthAnchor.constraint(equalToConstant: 13),
                    arrowImage.heightAnchor.constraint(equalToConstant: 20)
                ])
                
                cell.accessoryView = containerView
                cell.selectionStyle = .default
                
            case 1: // Edit custom themes
                cell.textLabel?.text = "Edit Custom Themes"
                cell.accessoryType = .disclosureIndicator
                
            case 2: // Create new theme
                cell.textLabel?.text = "Create New Theme"
                cell.accessoryType = .disclosureIndicator
                
            default:
                break
            }
            
        case 7: // Focus & Mindfulness
            cell.accessoryType = .disclosureIndicator
            cell.accessoryView = nil // Remove switch view
            
            switch indexPath.row {
            case 0: // Focus Mode
                cell.textLabel?.text = "Focus Mode"
                // Add a small icon
                cell.imageView?.image = UIImage(systemName: "timer")
                cell.imageView?.tintColor = .systemBlue
            case 1: // Breathing Room
                cell.textLabel?.text = "Breathing Room"
                // Add a small icon
                cell.imageView?.image = UIImage(systemName: "lungs")
                cell.imageView?.tintColor = .systemIndigo
            default:
                break
            }
            
        case 8: // App selection
            if indexPath.row < allApps.count {
                let app = allApps[indexPath.row]
                cell.textLabel?.text = app.name
                
                // Use disclosure indicator instead of switch
                cell.accessoryView = nil
                cell.accessoryType = .disclosureIndicator
                
                // Create a custom app icon that matches the home screen
                let iconSize: CGFloat = 12
                let circleView = UIView(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
                circleView.backgroundColor = app.getIconColor(useMonochrome: useMonochromeIcons, isDarkMode: traitCollection.userInterfaceStyle == .dark)
                circleView.layer.cornerRadius = iconSize / 2
                circleView.clipsToBounds = true
                
                // Add the circle to a custom view that we'll place in the cell
                let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                containerView.backgroundColor = .clear
                circleView.translatesAutoresizingMaskIntoConstraints = false
                containerView.addSubview(circleView)
                
                // Center the circle in its container
                NSLayoutConstraint.activate([
                    circleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                    circleView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                    circleView.widthAnchor.constraint(equalToConstant: iconSize),
                    circleView.heightAnchor.constraint(equalToConstant: iconSize)
                ])
                
                // Create an image from the container view
                UIGraphicsBeginImageContextWithOptions(containerView.bounds.size, false, 0)
                if let context = UIGraphicsGetCurrentContext() {
                    containerView.layer.render(in: context)
                    let image = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    // Set the image to the cell's imageView
                    cell.imageView?.image = image
                }
                
                cell.selectionStyle = .default // Enable selection for tapping the row
                
                return cell
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
    
    // Show app options menu with toggle and color picker
    private func showAppOptionsMenu(for appIndex: Int, at indexPath: IndexPath) {
        let app = allApps[appIndex]
        
        // Create an action sheet
        let actionSheet = UIAlertController(
            title: app.name,
            message: "Manage app settings",
            preferredStyle: .actionSheet
        )
        
        // Add option to change color
        let changeColorAction = UIAlertAction(title: "Change Color", style: .default) { [weak self] _ in
            self?.showAppColorPicker(for: appIndex)
        }
        
        // Add toggle option
        let toggleTitle = app.isSelected ? "Disable App" : "Enable App"
        let toggleAction = UIAlertAction(title: toggleTitle, style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // Toggle selection
            self.allApps[appIndex].isSelected = !app.isSelected
            
            // Save to UserDefaults
            self.saveAppSelectionsToUserDefaults()
            
            // Update the table cell
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
            
            // Notify delegate
            self.delegate?.didUpdateAppSelections(self.allApps)
        }
        
        // Add cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // Add actions to the sheet
        actionSheet.addAction(changeColorAction)
        actionSheet.addAction(toggleAction)
        actionSheet.addAction(cancelAction)
        
        // Present the action sheet
        present(actionSheet, animated: true)
    }
    
    private func showAppColorPicker(for appIndex: Int) {
        let colorPickerVC = UIColorPickerViewController()
        colorPickerVC.selectedColor = allApps[appIndex].color
        colorPickerVC.delegate = self
        colorPickerVC.title = "Choose color for \(allApps[appIndex].name)"
        
        // Use a property to keep track of which app we're changing
        colorPickerVC.view.tag = appIndex
        
        present(colorPickerVC, animated: true)
    }
    
    private func saveAppSelectionsToUserDefaults() {
        // Save updated app selections to UserDefaults
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(allApps)
            UserDefaults.standard.set(data, forKey: "savedApps")
            UserDefaults.standard.synchronize() // Force immediate save
            
            // Debug: print what was saved
            print("DEBUG: Saved \(allApps.count) apps to UserDefaults")
            for app in allApps {
                print("DEBUG: Saved app \(app.name) with color \(app.color)")
            }
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
    
    // MARK: - UIColorPickerViewControllerDelegate
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let appIndex = viewController.view.tag
        if appIndex >= 0 && appIndex < allApps.count {
            print("DEBUG: Color picker finished for app \(allApps[appIndex].name)")
            
            // Update the app's color
            let newColor = viewController.selectedColor
            print("DEBUG: Changing color for \(allApps[appIndex].name) to \(newColor)")
            allApps[appIndex].color = newColor
            
            // Save to UserDefaults immediately to ensure persistence
            saveAppSelectionsToUserDefaults()
            
            // Reload the table view
            tableView.reloadData()
            
            // Make sure the delegate gets the updated apps
            print("DEBUG: Calling delegate methods")
            delegate?.didUpdateSettings()
            delegate?.didUpdateTheme()
            delegate?.didUpdateAppSelections(allApps)
        }
    }
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        // Real-time color updates for preview
        let appIndex = viewController.view.tag
        if appIndex >= 0 && appIndex < allApps.count {
            // Preview the color change
            allApps[appIndex].color = viewController.selectedColor
            
            // Save changes immediately to UserDefaults for persistence
            saveAppSelectionsToUserDefaults()
            
            // Update both the settings view and home screen
            tableView.reloadData()
            
            // Call all delegate methods to ensure complete refresh
            delegate?.didUpdateSettings()
            delegate?.didUpdateTheme()
            delegate?.didUpdateAppSelections(allApps)
        }
    }
    
    // MARK: - Table View Editing Support
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Allow editing in profiles and apps sections
        return indexPath.section == 0 || indexPath.section == 8
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        // Handle profiles section
        if indexPath.section == 0 {
            // Can't delete the "Add New Profile" row
            if indexPath.row == ProfileManager.shared.profiles.count {
                return .none
            }
            return .delete
        }
        
        // During reordering mode, don't show delete buttons
        if indexPath.section == 8 && tableView.isEditing {
            return .none
        }
        return .delete
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Only allow moving in the apps section
        return indexPath.section == 8
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Match the row height of the home screen for app cells
        if indexPath.section == 8 {
            return 60
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Ensure we're only moving within the apps section
        guard sourceIndexPath.section == 8 && destinationIndexPath.section == 8 else { return }
        
        // Update the app order in our data model
        let movedApp = allApps.remove(at: sourceIndexPath.row)
        allApps.insert(movedApp, at: destinationIndexPath.row)
        
        // Save the updated order
        saveAppSelectionsToUserDefaults()
        
        // Notify the home screen of the change
        delegate?.didUpdateAppSelections(allApps)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Handle profile selection
        if indexPath.section == 0 {
            if indexPath.row < ProfileManager.shared.profiles.count {
                // Switch to selected profile
                ProfileManager.shared.switchToProfile(at: indexPath.row)
                
                // Reload settings from the selected profile
                loadSettings()
                
                // Update UI
                tableView.reloadData()
            } else {
                // Show dialog to create new profile
                showAddProfileDialog()
            }
        }
        // Show font picker when font cell is selected
        else if indexPath.section == 5 && indexPath.row == 1 {
            showFontSelectionMenu(for: indexPath)
        } else if indexPath.section == 6 {
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
        } else if indexPath.section == 7 {
            switch indexPath.row {
            case 0: // Focus Mode
                let focusModeVC = FocusModeViewController()
                let navController = UINavigationController(rootViewController: focusModeVC)
                present(navController, animated: true)
            case 1: // Breathing Room
                let breathingRoomVC = BreathingRoomSettingsViewController()
                let navController = UINavigationController(rootViewController: breathingRoomVC)
                present(navController, animated: true)
            default:
                break
            }
        } else if indexPath.section == 8 {
            // Handle app selection when tapping on an app row
            if indexPath.row < allApps.count {
                // Show options for this app
                showAppOptionsMenu(for: indexPath.row, at: indexPath)
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
        if indexPath.section == 0 && editingStyle == .delete {
            // Delete profile
            if ProfileManager.shared.profiles.count > 1 {
                ProfileManager.shared.deleteProfile(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                
                // Refresh UI
                loadSettings()
                tableView.reloadData()
            } else {
                let alert = UIAlertController(
                    title: "Cannot Delete",
                    message: "You must have at least one profile",
                    preferredStyle: .alert
                )
                let okAction = UIAlertAction(title: "OK", style: .default)
                alert.addAction(okAction)
                present(alert, animated: true)
            }
        } else if indexPath.section == 8 && editingStyle == .delete {
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
