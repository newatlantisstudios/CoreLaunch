//
//  FixedHomeScreenSection.swift
//  CoreLaunch
//
//  Created by Claude on 4/5/25.
//

import UIKit

struct HomeScreenOption {
    let title: String
    var isEnabled: Bool
    let tag: Int
    
    static let options: [HomeScreenOption] = [
        HomeScreenOption(title: "24-Hour Time", isEnabled: false, tag: 0),
        HomeScreenOption(title: "Show Date", isEnabled: true, tag: 1),
        HomeScreenOption(title: "Minimalist Style", isEnabled: true, tag: 2),
        HomeScreenOption(title: "Monochrome App Icons", isEnabled: false, tag: 3)
    ]
}

class FixedHomeScreenSectionViewController: UITableViewController {
    var options: [HomeScreenOption] = HomeScreenOption.options
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        loadOptionsFromUserDefaults()
    }
    
    private func loadOptionsFromUserDefaults() {
        let defaults = UserDefaults.standard
        
        options[0].isEnabled = defaults.bool(forKey: "use24HourTime")
        options[1].isEnabled = defaults.bool(forKey: "showDate")
        options[2].isEnabled = defaults.bool(forKey: "useMinimalistStyle")
        options[3].isEnabled = defaults.bool(forKey: "useMonochromeIcons")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        cell.selectionStyle = .none
        
        let option = options[indexPath.row]
        cell.textLabel?.text = option.title
        
        let switchView = UISwitch()
        switchView.isOn = option.isEnabled
        switchView.tag = option.tag
        switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = switchView
        
        return cell
    }
    
    @objc func switchChanged(_ sender: UISwitch) {
        let defaults = UserDefaults.standard
        
        // Find the option with this tag
        if let index = options.firstIndex(where: { $0.tag == sender.tag }) {
            options[index].isEnabled = sender.isOn
            
            // Save to UserDefaults based on tag
            switch sender.tag {
            case 0:
                defaults.set(sender.isOn, forKey: "use24HourTime")
            case 1:
                defaults.set(sender.isOn, forKey: "showDate")
            case 2:
                defaults.set(sender.isOn, forKey: "useMinimalistStyle")
            case 3:
                defaults.set(sender.isOn, forKey: "useMonochromeIcons")
                print("Monochrome Icons setting changed to: \(sender.isOn)")
            default:
                break
            }
            
            // Immediately synchronize to ensure settings are saved
            defaults.synchronize()
        }
    }
}
