//
//  QRCodeScanner.swift
//  CoreLaunch
//
//  Created on 4/3/25.
//

import UIKit
import AVFoundation

class QRCodeScanner: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    
    enum QRScannerError: Error {
        case invalidQRCodeData
        case invalidThemeFormat
        case cameraAccessDenied
        case cameraUnavailable
        case setupFailed
    }
    
    typealias ScanCompletion = (Result<ColorTheme, Error>) -> Void
    
    // Capture session management
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentViewController: UIViewController?
    private var completion: ScanCompletion?
    
    // Initialize with a view to display the camera preview
    func setupScanner(in view: UIView, viewController: UIViewController, completion: @escaping ScanCompletion) {
        self.currentViewController = viewController
        self.completion = completion
        
        // Check camera authorization status
        checkCameraAuthorization { [weak self] authorized in
            guard let self = self, authorized else {
                completion(.failure(QRScannerError.cameraAccessDenied))
                return
            }
            
            self.setupCaptureSession(in: view)
        }
    }
    
    // Start scanning for QR codes
    func startScanning() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
    
    // Stop scanning
    func stopScanning() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    // Check camera authorization
    private func checkCameraAuthorization(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
            
        case .denied, .restricted:
            completion(false)
            
            // Show alert to direct user to settings
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.showCameraAccessAlert()
            }
            
        @unknown default:
            completion(false)
        }
    }
    
    // Show alert for camera access
    private func showCameraAccessAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please allow camera access in Settings to scan QR codes",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        currentViewController?.present(alert, animated: true)
    }
    
    // Setup camera capture session
    private func setupCaptureSession(in view: UIView) {
        // Get the back camera
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            self.completion?(.failure(QRScannerError.cameraUnavailable))
            return
        }
        
        do {
            // Create input
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            // Check if we can add the input to our session
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                self.completion?(.failure(QRScannerError.setupFailed))
                return
            }
            
            // Setup metadata output
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                
                // Set delegate and use the main queue for callbacks
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                self.completion?(.failure(QRScannerError.setupFailed))
                return
            }
            
            // Setup preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.layer.bounds
            
            DispatchQueue.main.async { [weak self] in
                guard let previewLayer = self?.previewLayer else { return }
                view.layer.addSublayer(previewLayer)
                
                // Start capturing
                self?.startScanning()
            }
            
        } catch {
            self.completion?(.failure(error))
        }
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Stop scanning as soon as we find a QR code
        stopScanning()
        
        // Process the scanned QR code
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let qrCodeString = metadataObject.stringValue {
            processQRCode(qrCodeString)
        } else {
            self.completion?(.failure(QRScannerError.invalidQRCodeData))
        }
    }
    
    // Process QR code data
    private func processQRCode(_ qrCodeString: String) {
        // Convert base64 string back to Data
        guard let qrCodeData = Data(base64Encoded: qrCodeString) else {
            self.completion?(.failure(QRScannerError.invalidQRCodeData))
            return
        }
        
        do {
            // Decode ColorTheme from data
            let decoder = JSONDecoder()
            let theme = try decoder.decode(ColorTheme.self, from: qrCodeData)
            
            // Successfully decoded theme
            self.completion?(.success(theme))
            
        } catch {
            self.completion?(.failure(QRScannerError.invalidThemeFormat))
        }
    }
    
    // Static method to decode a theme from an image containing a QR code
    static func decodeThemeFromQRImage(_ image: UIImage) -> ColorTheme? {
        // Create CIDetector for QR codes
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                       context: nil,
                                       options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else {
            return nil
        }
        
        // Convert UIImage to CIImage
        guard let ciImage = CIImage(image: image) else {
            return nil
        }
        
        // Detect QR codes in the image
        let features = detector.features(in: ciImage)
        
        // Process the first detected QR code
        if let qrFeature = features.first as? CIQRCodeFeature,
           let qrCodeString = qrFeature.messageString {
            
            // Convert base64 string back to Data
            guard let qrCodeData = Data(base64Encoded: qrCodeString) else {
                return nil
            }
            
            do {
                // Decode ColorTheme from data
                let decoder = JSONDecoder()
                let theme = try decoder.decode(ColorTheme.self, from: qrCodeData)
                return theme
                
            } catch {
                print("Failed to decode theme: \(error)")
                return nil
            }
        }
        
        return nil
    }
}
