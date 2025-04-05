//
//  TipJarViewController.swift
//  CoreLaunch
//
//  Created by x on 4/5/25.
//

import UIKit
import StoreKit

class TipJarViewController: UIViewController {
    
    // MARK: - Properties
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let buttonStackView = UIStackView()
    private var productButtons: [UIButton] = []
    private var products: [SKProduct] = []
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📱 TipJarVC: View did load")
        setupUI()
        loadProducts()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Tip Jar"
        view.backgroundColor = .systemBackground
        
        // Close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        // Container view setup
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Title label setup
        titleLabel.text = "Support CoreLaunch"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Description label setup
        descriptionLabel.text = "If you love using CoreLaunch, consider supporting our small team with a tip. Your support helps us maintain and improve the app with new features and updates."
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionLabel)
        
        // Button stack view setup
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 12
        buttonStackView.distribution = .fillEqually
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buttonStackView)
        
        // Loading indicator setup
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(loadingIndicator)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            
            buttonStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: buttonStackView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: buttonStackView.centerYAnchor)
        ])
        
        // Create placeholder buttons
        loadingIndicator.startAnimating()
    }
    
    private func createProductButtons() {
        // Clear any existing buttons
        buttonStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        productButtons.removeAll()
        
        print("🛒 TipJarVC: Creating \(products.count) product buttons")
        
        for product in products {
            let button = UIButton(type: .system)
            
            // Determine the tip size
            let tipValue = TipValue.allCases.first { $0.rawValue == product.productIdentifier }
            
            // Format price
            let priceFormatter = NumberFormatter()
            priceFormatter.numberStyle = .currency
            priceFormatter.locale = product.priceLocale
            let priceString = priceFormatter.string(from: product.price) ?? "\(product.price)"
            
            // Set button title
            let buttonTitle = "\(tipValue?.description ?? "Tip") - \(priceString)"
            button.setTitle(buttonTitle, for: .normal)
            
            print("  - Created button for: \(product.productIdentifier) with title: \(buttonTitle)")
            
            // Button styling
            button.backgroundColor = ThemeManager.shared.currentTheme.primaryColor
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            button.layer.cornerRadius = 12
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
            
            // Add action
            button.tag = productButtons.count
            button.addTarget(self, action: #selector(tipButtonTapped(_:)), for: .touchUpInside)
            
            // Add to stack view
            buttonStackView.addArrangedSubview(button)
            productButtons.append(button)
        }
        
        loadingIndicator.stopAnimating()
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func tipButtonTapped(_ sender: UIButton) {
        guard sender.tag < products.count else {
            print("❌ TipJarVC: Invalid button tag: \(sender.tag), products count: \(products.count)")
            return 
        }
        
        let product = products[sender.tag]
        print("🛒 TipJarVC: Initiating purchase for \(product.productIdentifier)")
        loadingIndicator.startAnimating()
        
        IAPManager.shared.purchase(product: product) { [weak self] success in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                
                if success {
                    print("✅ TipJarVC: Purchase succeeded for \(product.productIdentifier)")
                    self?.showThankYouAlert()
                } else {
                    print("❌ TipJarVC: Purchase failed for \(product.productIdentifier)")
                    self?.showPurchaseFailedAlert()
                }
            }
        }
    }
    
    // MARK: - Product Loading
    private func loadProducts() {
        loadingIndicator.startAnimating()
        print("🛒 TipJarVC: Loading products...")
        
        IAPManager.shared.fetchProducts { [weak self] success, products in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                if success, let products = products, !products.isEmpty {
                    print("✅ TipJarVC: Successfully loaded \(products.count) products")
                    self.products = products
                    self.createProductButtons()
                } else {
                    print("❌ TipJarVC: Failed to load products or empty product list")
                    self.showProductLoadErrorAlert()
                }
            }
        }
    }
    
    // MARK: - Alert Helpers
    private func showThankYouAlert() {
        let alert = UIAlertController(
            title: "Thank You!",
            message: "Your support means a lot to us. We appreciate your contribution to helping make CoreLaunch better.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "You're Welcome!", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func showPurchaseFailedAlert() {
        let alert = UIAlertController(
            title: "Purchase Failed",
            message: "There was an issue processing your payment. Please try again later.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showProductLoadErrorAlert() {
        let alert = UIAlertController(
            title: "Couldn't Load Products",
            message: "There was an issue loading the tip options. Please try again later.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}
