//
//  IAPManager.swift
//  CoreLaunch
//
//  Created by x on 4/5/25.
//

import Foundation
import StoreKit

enum TipValue: String, CaseIterable {
    case small = "com.newatlantisstudios.corelaunch.tipjar.small"
    case medium = "com.newatlantisstudios.corelaunch.tipjar.medium"
    case large = "com.newatlantisstudios.corelaunch.tipjar.large1"
    
    var price: String {
        switch self {
        case .small: return "$0.99"
        case .medium: return "$2.99"
        case .large: return "$4.99"
        }
    }
    
    var description: String {
        switch self {
        case .small: return "Small Tip"
        case .medium: return "Medium Tip"
        case .large: return "Large Tip"
        }
    }
}

class IAPManager: NSObject {
    static let shared = IAPManager()
    
    private var products: [SKProduct] = []
    private var productRequest: SKProductsRequest?
    private var completionHandler: ((Bool, [SKProduct]?) -> Void)?
    
    override init() {
        super.init()
        
        // Register as payment queue observer
        print("💬 IAP: Registering as payment transaction observer")
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        // Remove as payment queue observer when deallocated
        print("💬 IAP: Removing payment transaction observer")
        SKPaymentQueue.default().remove(self)
    }
    
    func fetchProducts(completion: @escaping (Bool, [SKProduct]?) -> Void) {
        completionHandler = completion
        
        let productIdentifiers = Set(TipValue.allCases.map { $0.rawValue })
        print("🔍 IAP: Fetching products with identifiers:")
        for identifier in productIdentifiers {
            print("  - \(identifier)")
        }
        
        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest?.delegate = self
        productRequest?.start()
    }
    
    func purchase(product: SKProduct, completion: @escaping (Bool) -> Void) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        // Note: Result will be handled by SKPaymentTransactionObserver
    }
    
    func restorePurchases(completion: @escaping (Bool) -> Void) {
        SKPaymentQueue.default().restoreCompletedTransactions()
        // Note: Result will be handled by SKPaymentTransactionObserver
    }
}

// MARK: - SKProductsRequestDelegate
extension IAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        self.products = products
        
        // Debug logs for loaded products
        print("🛒 IAP: Successfully loaded \(products.count) products")
        for product in products {
            let priceFormatter = NumberFormatter()
            priceFormatter.numberStyle = .currency
            priceFormatter.locale = product.priceLocale
            let priceString = priceFormatter.string(from: product.price) ?? "\(product.price)"
            
            print("🛒 IAP Product: \(product.productIdentifier)")
            print("  - Title: \(product.localizedTitle)")
            print("  - Description: \(product.localizedDescription)")
            print("  - Price: \(priceString)")
        }
        
        // Log any invalid product identifiers
        if !response.invalidProductIdentifiers.isEmpty {
            print("❌ IAP: Found \(response.invalidProductIdentifiers.count) invalid product identifiers:")
            for invalidId in response.invalidProductIdentifiers {
                print("  - \(invalidId)")
            }
        }
        
        DispatchQueue.main.async {
            self.completionHandler?(true, products)
            self.completionHandler = nil
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("❌ IAP: Product request failed with error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.completionHandler?(false, nil)
            self.completionHandler = nil
        }
    }
}

// MARK: - SKPaymentTransactionObserver
extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                print("✅ IAP: Successfully purchased product: \(transaction.payment.productIdentifier)")
                SKPaymentQueue.default().finishTransaction(transaction)
                // You could store purchase info in UserDefaults if needed
                
            case .restored:
                print("🔄 IAP: Successfully restored purchase: \(transaction.payment.productIdentifier)")
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .failed:
                let errorDescription = transaction.error?.localizedDescription ?? "Unknown error"
                print("❌ IAP: Purchase failed for product: \(transaction.payment.productIdentifier)")
                print("  - Error: \(errorDescription)")
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .purchasing:
                print("⏳ IAP: Purchasing product: \(transaction.payment.productIdentifier)")
                break
                
            case .deferred:
                print("⏳ IAP: Purchase deferred for product: \(transaction.payment.productIdentifier)")
                break
                
            @unknown default:
                print("❓ IAP: Unknown transaction state for product: \(transaction.payment.productIdentifier)")
                break
            }
        }
    }
}
