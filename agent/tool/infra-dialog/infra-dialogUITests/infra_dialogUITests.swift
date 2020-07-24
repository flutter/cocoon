// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XCTest

// An XCUITest to dismiss System Dialogs.
class infra_dialogUITests: XCTestCase {

    override func setUp() {
        // Dismiss system dialogs, e.g. No SIM Card Installed
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let buttonTexts = ["OK", "Later", "Allow", "Remind Me Later", "Close"]
        // Sometimes a second dialog pops up when one is closed, so let's run 3 times.
        for _ in 0..<3 {
            for text in buttonTexts {
                let button = springboard.buttons[text]
                if button.exists {
                    button.tap()
                }
            }
        }

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    override func tearDown() {
        // Empty
    }

    func testExample() {
        // Empty
    }
}
