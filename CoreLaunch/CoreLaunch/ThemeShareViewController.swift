//
//  ThemeShareViewController.swift
//  CoreLaunch
//
//  Created on 4/3/25.
//

import UIKit
import Photos

protocol ThemeShareDelegate: AnyObject {
    func didImportTheme(_ theme: ColorTheme)
}

class ThemeShareViewController: UIViewController {
    
    // MARK: - Properties
    var theme: ColorTheme!
    weak var delegate: ThemeShareDelegate?
    
    // MARK: - UI Components
    private let qrImageView = UIImageView()
    private let themeNameLabel = UILabel()
    private let themePreviewView = UIView()
    private let instructionLabel = UILabel()
    private let shareButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let scanButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        generateQRCode()
        
        // Add close button to navigation bar
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeButtonTapped))
        navigationItem.leftBarButtonItem = closeButton
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Share Theme"
        view.backgroundColor = .systemBackground
        
        // Setup QR code image view
        qrImageView.contentMode = .scaleAspectFit
        qrImageView.translatesAutoresizingMaskIntoConstraints = false
        qrImageView.backgroundColor = .white
        qrImageView.layer.cornerRadius = 10
        qrImageView.clipsToBounds = true
        view.addSubview(qrImageView)
        
        // Setup theme name label
        themeNameLabel.text = theme.name
        themeNameLabel.font = UIFont.boldSystemFont(ofSize: 20)
        themeNameLabel.textAlignment = .center
        themeNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(themeNameLabel)
        
        // Setup theme preview
        themePreviewView.translatesAutoresizingMaskIntoConstraints = false
        themePreviewView.layer.cornerRadius = 8
        themePreviewView.clipsToBounds = true
        view.addSubview(themePreviewView)
        
        // Add color swatches to preview
        let primarySwatch = createColorSwatch(with: theme.primaryColor, name: "Primary")
        let secondarySwatch = createColorSwatch(with: theme.secondaryColor, name: "Secondary")
        let accentSwatch = createColorSwatch(with: theme.accentColor, name: "Accent")
        let backgroundSwatch = createColorSwatch(with: theme.backgroundColor, name: "Background")
        let textSwatch = createColorSwatch(with: theme.textColor, name: "Text")
        
        let swatchStack = UIStackView(arrangedSubviews: [
            primarySwatch, secondarySwatch, accentSwatch, backgroundSwatch, textSwatch
        ])
        swatchStack.axis = .horizontal
        swatchStack.distribution = .fillEqually
        swatchStack.spacing = 8
        swatchStack.translatesAutoresizingMaskIntoConstraints = false
        themePreviewView.addSubview(swatchStack)
        
        // Instruction label
        instructionLabel.text = "Scan this QR code with another device to import this theme"
        instructionLabel.textAlignment = .center
        instructionLabel.font = UIFont.systemFont(ofSize: 14)
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.numberOfLines = 0
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        // Share button
        shareButton.setTitle("Share", for: .normal)
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shareButton)
        
        // Save button
        saveButton.setTitle("Save to Photos", for: .normal)
        saveButton.setImage(UIImage(systemName: "photo"), for: .normal)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        // Scan button
        scanButton.setTitle("Scan QR Code", for: .normal)
        scanButton.setImage(UIImage(systemName: "qrcode.viewfinder"), for: .normal)
        scanButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            themeNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            themeNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            themeNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            themeNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            qrImageView.topAnchor.constraint(equalTo: themeNameLabel.bottomAnchor, constant: 20),
            qrImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrImageView.widthAnchor.constraint(equalToConstant: 250),
            qrImageView.heightAnchor.constraint(equalToConstant: 250),
            
            themePreviewView.topAnchor.constraint(equalTo: qrImageView.bottomAnchor, constant: 20),
            themePreviewView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            themePreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            themePreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            themePreviewView.heightAnchor.constraint(equalToConstant: 70),
            
            swatchStack.topAnchor.constraint(equalTo: themePreviewView.topAnchor, constant: 10),
            swatchStack.leadingAnchor.constraint(equalTo: themePreviewView.leadingAnchor, constant: 10),
            swatchStack.trailingAnchor.constraint(equalTo: themePreviewView.trailingAnchor, constant: -10),
            swatchStack.bottomAnchor.constraint(equalTo: themePreviewView.bottomAnchor, constant: -10),
            
            instructionLabel.topAnchor.constraint(equalTo: themePreviewView.bottomAnchor, constant: 20),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            shareButton.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 30),
            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shareButton.widthAnchor.constraint(equalToConstant: 150),
            
            saveButton.topAnchor.constraint(equalTo: shareButton.bottomAnchor, constant: 15),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 150),
            
            scanButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 15),
            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanButton.widthAnchor.constraint(equalToConstant: 150),
        ])
        
        // Set theme preview background
        themePreviewView.backgroundColor = theme.backgroundColor
    }
    
    private func createColorSwatch(with color: UIColor, name: String) -> UIView {
        let container = UIView()
        
        let colorView = UIView()
        colorView.backgroundColor = color
        colorView.layer.cornerRadius = 4
        colorView.layer.borderWidth = 1
        // Use black border for light colors, white border for dark colors
        colorView.layer.borderColor = color.isLight ? UIColor.black.cgColor : UIColor.white.cgColor
        colorView.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 10)
        nameLabel.textAlignment = .center
        nameLabel.textColor = theme.textColor
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(colorView)
        container.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            colorView.topAnchor.constraint(equalTo: container.topAnchor),
            colorView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 25),
            colorView.heightAnchor.constraint(equalToConstant: 25),
            
            nameLabel.topAnchor.constraint(equalTo: colorView.bottomAnchor, constant: 4),
            nameLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        return container
    }
    
    // MARK: - Generate QR Code
    private func generateQRCode() {
        guard let theme = theme else { return }
        
        // Generate a larger QR code for better visibility
        if let qrImage = QRCodeGenerator.generateThemedQRCode(from: theme, size: 250) {
            qrImageView.image = qrImage
        } else {
            // Fallback to standard QR code if themed one fails
            qrImageView.image = QRCodeGenerator.generateQRCode(from: theme, size: 250)
            
            // Show error alert if neither method works
            if qrImageView.image == nil {
                let alert = UIAlertController(
                    title: "QR Code Generation Failed",
                    message: "Unable to generate QR code for this theme.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func shareButtonTapped() {
        guard let qrImage = qrImageView.image else { return }
        
        // Create an activity view controller
        let activityViewController = UIActivityViewController(
            activityItems: [qrImage, "Check out my CoreLaunch theme: \(theme.name)"],
            applicationActivities: nil
        )
        
        // Present the controller
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = shareButton
            popoverController.sourceRect = shareButton.bounds
        }
        
        present(activityViewController, animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let qrImage = qrImageView.image else { return }
        
        // Save QR code to photo library
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(qrImage, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            } else {
                DispatchQueue.main.async {
                    self.showPhotoLibraryAccessAlert()
                }
            }
        }
    }
    
    @objc private func scanButtonTapped() {
        let scanVC = ThemeScannerViewController()
        scanVC.delegate = self
        present(scanVC, animated: true)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showAlert(title: "Save Error", message: error.localizedDescription)
        } else {
            showAlert(title: "Saved", message: "QR code saved to your photos")
        }
    }
    
    private func showPhotoLibraryAccessAlert() {
        showAlert(
            title: "Photo Library Access Required",
            message: "Please allow photo library access in Settings to save QR codes"
        )
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ThemeScannerDelegate
extension ThemeShareViewController: ThemeScannerDelegate {
    func didScanTheme(_ theme: ColorTheme) {
        // When a theme is scanned, pass it to the delegate
        delegate?.didImportTheme(theme)
        
        // Show success message
        showAlert(
            title: "Theme Imported",
            message: "Successfully imported theme: \(theme.name)"
        )
    }
}
