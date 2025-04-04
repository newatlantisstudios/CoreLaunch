//
//  QRCodeGenerator.swift
//  CoreLaunch
//
//  Created on 4/3/25.
//

import UIKit
import CoreImage

class QRCodeGenerator {
    
    enum QRCodeError: Error {
        case encodingFailed
        case qrGenerationFailed
    }
    
    /// Generate a QR code image from a ColorTheme
    /// - Parameters:
    ///   - theme: The theme to encode in the QR code
    ///   - size: The desired size of the QR code image
    /// - Returns: A UIImage containing the QR code, or nil if generation failed
    static func generateQRCode(from theme: ColorTheme, size: CGFloat = 200) -> UIImage? {
        do {
            // Encode the theme to JSON data
            let encoder = JSONEncoder()
            let themeData = try encoder.encode(theme)
            
            // Convert to base64 string for compact representation
            let base64String = themeData.base64EncodedString()
            
            // Create a QR code from the string
            guard let qrCodeData = base64String.data(using: .utf8) else {
                throw QRCodeError.encodingFailed
            }
            
            // Create CIFilter for QR code generation
            guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {
                throw QRCodeError.qrGenerationFailed
            }
            
            qrFilter.setValue(qrCodeData, forKey: "inputMessage")
            qrFilter.setValue("H", forKey: "inputCorrectionLevel") // High error correction
            
            // Get the output image
            guard let qrImage = qrFilter.outputImage else {
                throw QRCodeError.qrGenerationFailed
            }
            
            // Scale the image to the requested size
            let scaleX = size / qrImage.extent.size.width
            let scaleY = size / qrImage.extent.size.height
            let transformedImage = qrImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            
            // Convert CIImage to UIImage
            let context = CIContext()
            guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
                throw QRCodeError.qrGenerationFailed
            }
            
            return UIImage(cgImage: cgImage)
            
        } catch {
            print("Failed to generate QR code: \(error)")
            return nil
        }
    }
    
    /// Generate a themed QR code with custom colors based on the theme
    /// - Parameters:
    ///   - theme: The theme to encode and use for styling
    ///   - size: The desired size of the QR code image
    /// - Returns: A UIImage containing the styled QR code, or nil if generation failed
    static func generateThemedQRCode(from theme: ColorTheme, size: CGFloat = 200) -> UIImage? {
        guard let baseQRCode = generateQRCode(from: theme, size: size) else {
            return nil
        }
        
        // Create a colored version
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return baseQRCode
        }
        
        // Draw white background for better QR code contrast
        UIColor.white.setFill()
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        
        // Draw QR code in black
        if let cgImage = baseQRCode.cgImage {
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))
        }
        
        // Add a small preview rectangle with theme colors
        let previewSize = size * 0.15
        let previewRect = CGRect(x: (size - previewSize) / 2, y: (size - previewSize) / 2, width: previewSize, height: previewSize)
        
        // Draw preview background
        theme.backgroundColor.setFill()
        let backgroundPath = UIBezierPath(roundedRect: previewRect, cornerRadius: 5)
        backgroundPath.fill()
        
        // Draw primary color strip
        let stripHeight = previewSize / 3
        theme.primaryColor.setFill()
        let primaryRect = CGRect(x: previewRect.minX, y: previewRect.minY, width: previewSize, height: stripHeight)
        UIRectFill(primaryRect)
        
        // Draw secondary color strip
        theme.secondaryColor.setFill()
        let secondaryRect = CGRect(x: previewRect.minX, y: previewRect.minY + stripHeight, width: previewSize, height: stripHeight)
        UIRectFill(secondaryRect)
        
        // Draw accent color strip
        theme.accentColor.setFill()
        let accentRect = CGRect(x: previewRect.minX, y: previewRect.minY + (stripHeight * 2), width: previewSize, height: stripHeight)
        UIRectFill(accentRect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
