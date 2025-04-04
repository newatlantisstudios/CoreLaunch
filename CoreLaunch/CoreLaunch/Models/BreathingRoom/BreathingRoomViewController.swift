//
//  BreathingRoomViewController.swift
//  CoreLaunch
//
//  Created on 4/4/25.
//

import UIKit

protocol BreathingRoomDelegate: AnyObject {
    func breathingRoomDidComplete(for appName: String)
    func breathingRoomWasCancelled(for appName: String)
}

class BreathingRoomViewController: UIViewController {
    
    // MARK: - Properties
    private let appName: String
    private let delayDuration: TimeInterval
    private var remainingTime: TimeInterval
    private var timer: Timer?
    
    private let containerView = UIView()
    private let timerLabel = UILabel()
    private let reflectionPromptLabel = UILabel()
    private let appNameLabel = UILabel()
    private let progressView = UIProgressView()
    private let cancelButton = UIButton(type: .system)
    private let continueButton = UIButton(type: .system)
    private let breathingAnimationView = UIView()
    
    weak var delegate: BreathingRoomDelegate?
    
    // MARK: - Initialization
    init(appName: String, delayDuration: TimeInterval) {
        self.appName = appName
        self.delayDuration = delayDuration
        self.remainingTime = delayDuration
        
        super.init(nibName: nil, bundle: nil)
        
        // Make sure the presentation is modal
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAnimation()
        updateTimerLabel()
        startTimer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startBreathingAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        
        // Setup container view
        containerView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Setup app name label
        appNameLabel.text = appName
        appNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        appNameLabel.textColor = .white
        appNameLabel.textAlignment = .center
        appNameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(appNameLabel)
        
        // Setup timer label
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 64, weight: .bold)
        timerLabel.textColor = .white
        timerLabel.textAlignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(timerLabel)
        
        // Setup reflection prompt
        reflectionPromptLabel.text = BreathingRoomManager.shared.getRandomReflectionPrompt()
        reflectionPromptLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        reflectionPromptLabel.textColor = .white
        reflectionPromptLabel.textAlignment = .center
        reflectionPromptLabel.numberOfLines = 0
        reflectionPromptLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(reflectionPromptLabel)
        
        // Setup progress view
        progressView.progressTintColor = .white
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progressView.progress = 0
        progressView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(progressView)
        
        // Setup breathing animation view
        breathingAnimationView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        breathingAnimationView.layer.cornerRadius = 100
        breathingAnimationView.clipsToBounds = true
        breathingAnimationView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(breathingAnimationView)
        
        // Setup cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.5)
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cancelButton)
        
        // Setup continue button
        continueButton.setTitle("Continue Now", for: .normal)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.5)
        continueButton.layer.cornerRadius = 8
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(continueButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
            
            appNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            appNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            appNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            breathingAnimationView.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 20),
            breathingAnimationView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            breathingAnimationView.widthAnchor.constraint(equalToConstant: 200),
            breathingAnimationView.heightAnchor.constraint(equalToConstant: 200),
            
            timerLabel.centerXAnchor.constraint(equalTo: breathingAnimationView.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: breathingAnimationView.centerYAnchor),
            
            reflectionPromptLabel.topAnchor.constraint(equalTo: breathingAnimationView.bottomAnchor, constant: 24),
            reflectionPromptLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            reflectionPromptLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            
            progressView.topAnchor.constraint(equalTo: reflectionPromptLabel.bottomAnchor, constant: 24),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            cancelButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.4),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            
            continueButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            continueButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            continueButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.4),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Timer & Progress Methods
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func updateTimer() {
        // Decrease remaining time
        remainingTime -= 0.1
        
        // Update UI
        updateTimerLabel()
        updateProgress()
        
        // Check if timer is completed
        if remainingTime <= 0 {
            completeBreathingRoom()
        }
    }
    
    private func updateTimerLabel() {
        let seconds = max(0, Int(ceil(remainingTime)))
        timerLabel.text = "\(seconds)"
    }
    
    private func updateProgress() {
        let progress = 1.0 - (remainingTime / delayDuration)
        progressView.setProgress(Float(progress), animated: true)
    }
    
    // MARK: - Animation
    private func setupAnimation() {
        // Set initial state of the breathing animation
        breathingAnimationView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        breathingAnimationView.alpha = 0.7
    }
    
    private func startBreathingAnimation() {
        // Calculate animation duration based on remaining time
        // We want multiple breath cycles during the waiting period
        let animationDuration = min(4.0, delayDuration / 2)
        
        // Start the breathing animation loop
        animateBreathing(duration: animationDuration)
    }
    
    private func animateBreathing(duration: TimeInterval) {
        // Breathe in (expand)
        UIView.animate(withDuration: duration / 2, delay: 0, options: [.curveEaseInOut], animations: { [weak self] in
            self?.breathingAnimationView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self?.breathingAnimationView.alpha = 1.0
        }) { [weak self] _ in
            // Breathe out (contract)
            UIView.animate(withDuration: duration / 2, delay: 0, options: [.curveEaseInOut], animations: {
                self?.breathingAnimationView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self?.breathingAnimationView.alpha = 0.7
            }) { [weak self] _ in
                // Continue the breathing animation if timer is still active
                if self?.remainingTime ?? 0 > 0 {
                    self?.animateBreathing(duration: duration)
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func cancelButtonTapped() {
        timer?.invalidate()
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.breathingRoomWasCancelled(for: self.appName)
        }
    }
    
    @objc private func continueButtonTapped() {
        completeBreathingRoom()
    }
    
    private func completeBreathingRoom() {
        timer?.invalidate()
        timer = nil
        
        // Animate a quick fade out
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.view.alpha = 0
        }) { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: false) {
                self.delegate?.breathingRoomDidComplete(for: self.appName)
            }
        }
    }
}
