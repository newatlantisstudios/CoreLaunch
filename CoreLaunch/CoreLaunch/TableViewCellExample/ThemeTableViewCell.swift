//
//  ThemeTableViewCell.swift
//  CoreLaunch
//
//  Created on 4/3/25.
//

import UIKit

class ThemeTableViewCell: UITableViewCell {
    // MARK: - Properties
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Share button has been removed per requirement
        // Cell remains simple without additional controls
    }
    
    // MARK: - Actions
    @objc private func shareButtonTapped() {
        // Handle share button tap
        print("Share button tapped")
        
        // Example of how to call a method from the parent view controller
        // if let parentVC = self.nextResponder as? SomeViewController {
        //     parentVC.shareTheme()
        // }
    }
}

// Example extension to demonstrate how to reference another class's method
extension ThemeTableViewCell {
    // This demonstrates how to properly set up a selector for a method in a different class
    func setupButtonWithCustomSelector(parentVC: UIViewController, selector: Selector) {
        let button = UIButton(type: .system)
        button.addTarget(parentVC, action: selector, for: .touchUpInside)
        contentView.addSubview(button)
    }
}
