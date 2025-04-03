//
//  GoalSettingViewController.swift
//  CoreLaunch
//
//  Created on 4/2/25.
//

import UIKit

protocol GoalSettingDelegate: AnyObject {
    func didUpdateGoals(dailyLimit: TimeInterval, weeklyReduction: Double)
}

class GoalSettingViewController: UIViewController {
    
    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    private let hoursLabel = UILabel()
    private let hoursTextField = UITextField()
    
    private let minutesLabel = UILabel()
    private let minutesTextField = UITextField()
    
    private let reductionLabel = UILabel()
    private let reductionTextField = UITextField()
    
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    // MARK: - Properties
    private let usageTracker = UsageTracker.shared
    weak var delegate: GoalSettingDelegate?
    
    // Initial values
    private var initialHours: Int = 0
    private var initialMinutes: Int = 0
    private var initialReduction: Double = 0.05
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadInitialValues()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add a background blur effect for a modal-like appearance
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        
        // Create a container view for the content
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        view.addSubview(containerView)
        
        // Set up title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Set Screen Time Goal"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        
        // Set up subtitle label
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Set your daily usage limit"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        containerView.addSubview(subtitleLabel)
        
        // Hours input
        hoursLabel.translatesAutoresizingMaskIntoConstraints = false
        hoursLabel.text = "Hours"
        hoursLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        hoursLabel.textColor = .label
        containerView.addSubview(hoursLabel)
        
        hoursTextField.translatesAutoresizingMaskIntoConstraints = false
        hoursTextField.borderStyle = .roundedRect
        hoursTextField.keyboardType = .numberPad
        hoursTextField.textAlignment = .center
        hoursTextField.text = "\(initialHours)"
        containerView.addSubview(hoursTextField)
        
        // Minutes input
        minutesLabel.translatesAutoresizingMaskIntoConstraints = false
        minutesLabel.text = "Minutes"
        minutesLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        minutesLabel.textColor = .label
        containerView.addSubview(minutesLabel)
        
        minutesTextField.translatesAutoresizingMaskIntoConstraints = false
        minutesTextField.borderStyle = .roundedRect
        minutesTextField.keyboardType = .numberPad
        minutesTextField.textAlignment = .center
        minutesTextField.text = "\(initialMinutes)"
        containerView.addSubview(minutesTextField)
        
        // Reduction input
        reductionLabel.translatesAutoresizingMaskIntoConstraints = false
        reductionLabel.text = "Weekly Reduction Goal (%)"
        reductionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        reductionLabel.textColor = .label
        containerView.addSubview(reductionLabel)
        
        reductionTextField.translatesAutoresizingMaskIntoConstraints = false
        reductionTextField.borderStyle = .roundedRect
        reductionTextField.keyboardType = .decimalPad
        reductionTextField.textAlignment = .center
        reductionTextField.text = String(format: "%.1f", initialReduction * 100)
        containerView.addSubview(reductionTextField)
        
        // Buttons
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.layer.cornerRadius = 8
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        containerView.addSubview(saveButton)
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.systemBlue, for: .normal)
        cancelButton.backgroundColor = .systemGray6
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        containerView.addSubview(cancelButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Blur view fills the entire view
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Container positioned in center with fixed width
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Title and subtitle
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Hours input
            hoursLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            hoursLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            hoursLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            hoursTextField.topAnchor.constraint(equalTo: hoursLabel.bottomAnchor, constant: 8),
            hoursTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            hoursTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            hoursTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Minutes input
            minutesLabel.topAnchor.constraint(equalTo: hoursTextField.bottomAnchor, constant: 16),
            minutesLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            minutesLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            minutesTextField.topAnchor.constraint(equalTo: minutesLabel.bottomAnchor, constant: 8),
            minutesTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            minutesTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            minutesTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Reduction input
            reductionLabel.topAnchor.constraint(equalTo: minutesTextField.bottomAnchor, constant: 16),
            reductionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            reductionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            reductionTextField.topAnchor.constraint(equalTo: reductionLabel.bottomAnchor, constant: 8),
            reductionTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            reductionTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            reductionTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Buttons
            cancelButton.topAnchor.constraint(equalTo: reductionTextField.bottomAnchor, constant: 24),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.43, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            
            saveButton.topAnchor.constraint(equalTo: reductionTextField.bottomAnchor, constant: 24),
            saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            saveButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.43, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24)
        ])
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Data
    private func loadInitialValues() {
        let dailyLimit = usageTracker.getUsageGoal().dailyUsageLimit
        initialHours = Int(dailyLimit) / 3600
        initialMinutes = (Int(dailyLimit) % 3600) / 60
        initialReduction = usageTracker.getUsageGoal().weeklyReductionTarget
    }
    
    // MARK: - Actions
    @objc private func saveButtonTapped() {
        // Get input values
        let hours = Int(hoursTextField.text ?? "0") ?? 0
        let minutes = Int(minutesTextField.text ?? "0") ?? 0
        
        // Convert to time interval
        let dailyLimit = TimeInterval(hours * 3600 + minutes * 60)
        
        // Get reduction percentage
        let reductionText = reductionTextField.text ?? "5.0"
        let reductionPercentage = (Double(reductionText) ?? 5.0) / 100.0
        
        // Notify delegate
        delegate?.didUpdateGoals(
            dailyLimit: dailyLimit,
            weeklyReduction: reductionPercentage
        )
        
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
