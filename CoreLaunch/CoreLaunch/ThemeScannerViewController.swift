//
//  ThemeScannerViewController.swift
//  CoreLaunch
//
//  Created on 4/3/25.
//

import UIKit
import AVFoundation
import PhotosUI

protocol ThemeScannerDelegate: AnyObject {
    func didScanTheme(_ theme: ColorTheme)
}

class ThemeScannerViewController: UIViewController {
    
    // MARK: - Properties
    private let scanner = QRCodeScanner()
    weak var delegate: ThemeScannerDelegate?
    
    // MARK: - UI Components
    private let cameraView = UIView()
    private let instructionLabel = UILabel()
    private let scannerFrame = UIImageView()
    private let cancelButton = UIButton(type: .system)
    private let pickPhotoButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scanner.stopScanning()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // Camera view
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraView)
        
        // Scanner frame
        scannerFrame.image = UIImage(systemName: "viewfinder")
        scannerFrame.tintColor = .white
        scannerFrame.contentMode = .scaleAspectFit
        scannerFrame.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scannerFrame)
        
        // Instruction label
        instructionLabel.text = "Position the QR code within the frame"
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.font = UIFont.systemFont(ofSize: 16)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.tintColor = .white
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        
        // Pick photo button
        pickPhotoButton.setTitle("Choose Photo", for: .normal)
        pickPhotoButton.tintColor = .white
        pickPhotoButton.addTarget(self, action: #selector(pickPhotoButtonTapped), for: .touchUpInside)
        pickPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pickPhotoButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            scannerFrame.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scannerFrame.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scannerFrame.widthAnchor.constraint(equalToConstant: 250),
            scannerFrame.heightAnchor.constraint(equalToConstant: 250),
            
            instructionLabel.bottomAnchor.constraint(equalTo: scannerFrame.topAnchor, constant: -20),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            pickPhotoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            pickPhotoButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Scanner Setup
    private func startScanning() {
        scanner.setupScanner(in: cameraView, viewController: self) { [weak self] result in
            switch result {
            case .success(let theme):
                // Theme successfully scanned
                DispatchQueue.main.async {
                    self?.handleScannedTheme(theme)
                }
                
            case .failure(let error):
                // Handle error
                DispatchQueue.main.async {
                    self?.handleScannerError(error)
                }
            }
        }
    }
    
    private func handleScannedTheme(_ theme: ColorTheme) {
        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Pass theme to delegate
        delegate?.didScanTheme(theme)
        
        // Dismiss scanner
        dismiss(animated: true)
    }
    
    private func handleScannerError(_ error: Error) {
        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Show error message
        let alertController = UIAlertController(
            title: "Scan Failed",
            message: "Could not scan QR code: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            // Resume scanning if it was a temporary error
            if let error = error as? QRCodeScanner.QRScannerError,
               error != .cameraAccessDenied && error != .cameraUnavailable {
                self?.scanner.startScanning()
            }
        })
        
        present(alertController, animated: true)
    }
    
    // MARK: - Actions
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func pickPhotoButtonTapped() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ThemeScannerViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Could not load image: \(error.localizedDescription)")
                }
                return
            }
            
            guard let image = object as? UIImage else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Could not process image")
                }
                return
            }
            
            // Try to decode theme from QR code
            if let theme = QRCodeScanner.decodeThemeFromQRImage(image) {
                DispatchQueue.main.async {
                    self?.handleScannedTheme(theme)
                }
            } else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Invalid QR Code", message: "The selected image does not contain a valid theme QR code")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
