//
//  UsageStatsAccessTest.swift
//  CoreLaunch
//
//  Created on 4/2/25.
//

import UIKit

// This file ensures proper import of usage statistics model
class UsageStatsAccessTest {
    func testAccess() {
        // Simple test to ensure imports work correctly
        let tracker = UsageTracker.shared
        let _ = tracker.getTodayUsage()
    }
}
