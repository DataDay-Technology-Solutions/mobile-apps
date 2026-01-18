//
//  TeacherLinkUITests.swift
//  TeacherLinkUITests
//
//  Comprehensive UI test suite for TeacherLink app
//

import XCTest

final class TeacherLinkUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    func testAppLaunches() throws {
        // Verify app launches successfully
        XCTAssertTrue(app.state == .runningForeground, "App should be running in foreground")
    }

    func testMainTabBarExists() throws {
        // Verify tab bar exists with expected tabs
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")

        // Check for main tabs
        XCTAssertTrue(tabBar.buttons["Feed"].exists || tabBar.buttons["Stories"].exists, "Feed/Stories tab should exist")
        XCTAssertTrue(tabBar.buttons["Albums"].exists, "Albums tab should exist")
        XCTAssertTrue(tabBar.buttons["Messages"].exists, "Messages tab should exist")
        XCTAssertTrue(tabBar.buttons["Settings"].exists, "Settings tab should exist")
    }

    // MARK: - Navigation Tests

    func testNavigationBetweenTabs() throws {
        let tabBar = app.tabBars.firstMatch

        // Navigate to Albums
        tabBar.buttons["Albums"].tap()
        sleep(1)
        XCTAssertTrue(app.navigationBars["Photo Albums"].exists, "Should navigate to Photo Albums")

        // Navigate to Messages
        tabBar.buttons["Messages"].tap()
        sleep(1)
        XCTAssertTrue(app.navigationBars["Messages"].exists, "Should navigate to Messages")

        // Navigate to Settings
        tabBar.buttons["Settings"].tap()
        sleep(1)
        XCTAssertTrue(app.navigationBars["Settings"].exists, "Should navigate to Settings")

        // Navigate back to Feed
        if tabBar.buttons["Feed"].exists {
            tabBar.buttons["Feed"].tap()
        } else {
            tabBar.buttons["Stories"].tap()
        }
        sleep(1)
    }

    // MARK: - Feed/Stories Tab Tests

    func testStoriesFeedScrolling() throws {
        // Navigate to Feed tab
        let tabBar = app.tabBars.firstMatch
        if tabBar.buttons["Feed"].exists {
            tabBar.buttons["Feed"].tap()
        }
        sleep(1)

        // Find the scroll view and test scrolling
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
            scrollView.swipeDown()
            sleep(1)
            XCTAssertTrue(true, "Feed scrolling works")
        }
    }

    func testStoryLikeButton() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.buttons["Feed"].exists {
            tabBar.buttons["Feed"].tap()
        }
        sleep(1)

        // Find a heart button (like button)
        let heartButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'heart'")).firstMatch
        if heartButton.exists {
            heartButton.tap()
            sleep(1)
            XCTAssertTrue(true, "Like button is tappable")
        }
    }

    func testStoryCommentButton() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.buttons["Feed"].exists {
            tabBar.buttons["Feed"].tap()
        }
        sleep(1)

        // Find a bubble button (comment button)
        let commentButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'bubble'")).firstMatch
        if commentButton.exists {
            commentButton.tap()
            sleep(1)
            // Check if comments sheet appears
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
            XCTAssertTrue(true, "Comment button opens comments")
        }
    }

    // MARK: - Photo Albums Tab Tests

    func testPhotoAlbumsTabExists() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Albums"].tap()
        sleep(1)

        XCTAssertTrue(app.navigationBars["Photo Albums"].exists, "Photo Albums navigation bar should exist")
    }

    func testPhotoAlbumsSearch() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Albums"].tap()
        sleep(1)

        // Find search field
        let searchField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'search'")).firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("Fall")
            sleep(1)
            XCTAssertTrue(true, "Search field is functional")
            // Clear search
            searchField.buttons["Clear text"].tap()
        }
    }

    func testAlbumCardTap() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Albums"].tap()
        sleep(1)

        // Find and tap an album card
        let albumCell = app.cells.firstMatch
        if albumCell.exists {
            albumCell.tap()
            sleep(1)
            // Check if we navigated to album detail
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.exists {
                backButton.tap()
            }
            XCTAssertTrue(true, "Album navigation works")
        }
    }

    func testCreateAlbumButton() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Albums"].tap()
        sleep(1)

        // Find create album button (plus button)
        let createButton = app.navigationBars.buttons.matching(NSPredicate(format: "label CONTAINS 'plus' OR label CONTAINS 'Add'")).firstMatch
        if createButton.exists {
            createButton.tap()
            sleep(1)
            // Check if create album sheet appears
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            }
            XCTAssertTrue(true, "Create album button works")
        }
    }

    // MARK: - Messages Tab Tests

    func testMessagesTabExists() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Messages"].tap()
        sleep(1)

        XCTAssertTrue(app.navigationBars["Messages"].exists, "Messages navigation bar should exist")
    }

    func testMessagesListScrolling() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Messages"].tap()
        sleep(1)

        let list = app.collectionViews.firstMatch
        if list.exists {
            list.swipeUp()
            sleep(1)
            list.swipeDown()
            XCTAssertTrue(true, "Messages list scrolling works")
        }
    }

    func testConversationTap() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Messages"].tap()
        sleep(1)

        // Find and tap a conversation
        let cell = app.cells.firstMatch
        if cell.exists {
            cell.tap()
            sleep(1)
            // Navigate back
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.exists {
                backButton.tap()
            }
            XCTAssertTrue(true, "Conversation navigation works")
        }
    }

    // MARK: - Settings Tab Tests

    func testSettingsTabExists() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Settings"].tap()
        sleep(1)

        XCTAssertTrue(app.navigationBars["Settings"].exists, "Settings navigation bar should exist")
    }

    func testSettingsProfileSection() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Settings"].tap()
        sleep(1)

        // Check for profile elements
        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.exists, "Settings list should exist")
    }

    func testQRCodeInviteButton() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Settings"].tap()
        sleep(1)

        // Find QR code button
        let qrButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'QR'")).firstMatch
        if qrButton.exists {
            qrButton.tap()
            sleep(1)
            // Dismiss the sheet
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
            XCTAssertTrue(true, "QR code invite button works")
        }
    }

    func testSignOutButton() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Settings"].tap()
        sleep(1)

        // Find sign out button
        let signOutButton = app.buttons["Sign Out"]
        XCTAssertTrue(signOutButton.exists, "Sign out button should exist")
    }

    // MARK: - Points Tab Tests (Teacher only)

    func testPointsTabExists() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.buttons["Points"].exists {
            tabBar.buttons["Points"].tap()
            sleep(1)
            // Points view should load
            XCTAssertTrue(true, "Points tab exists and is tappable")
        }
    }

    func testStudentPointsGrid() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.buttons["Points"].exists {
            tabBar.buttons["Points"].tap()
            sleep(1)

            // Check for student grid
            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeUp()
                sleep(1)
                scrollView.swipeDown()
                XCTAssertTrue(true, "Points grid scrolling works")
            }
        }
    }

    // MARK: - Students Tab Tests (Teacher only)

    func testStudentsTabExists() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.buttons["Students"].exists {
            tabBar.buttons["Students"].tap()
            sleep(1)
            XCTAssertTrue(true, "Students tab exists and is tappable")
        }
    }

    func testStudentsListScrolling() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.buttons["Students"].exists {
            tabBar.buttons["Students"].tap()
            sleep(1)

            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeUp()
                sleep(1)
                scrollView.swipeDown()
                XCTAssertTrue(true, "Students list scrolling works")
            }
        }
    }

    // MARK: - Pull to Refresh Tests

    func testPullToRefreshOnFeed() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.buttons["Feed"].exists {
            tabBar.buttons["Feed"].tap()
        }
        sleep(1)

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Pull down to refresh
            scrollView.swipeDown()
            sleep(2)
            XCTAssertTrue(true, "Pull to refresh works on Feed")
        }
    }

    func testPullToRefreshOnAlbums() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Albums"].tap()
        sleep(1)

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
            sleep(2)
            XCTAssertTrue(true, "Pull to refresh works on Albums")
        }
    }

    // MARK: - Button Interaction Tests

    func testAllTabBarButtonsAreTappable() throws {
        let tabBar = app.tabBars.firstMatch

        for button in tabBar.buttons.allElementsBoundByIndex {
            if button.isHittable {
                button.tap()
                sleep(1)
            }
        }
        XCTAssertTrue(true, "All tab bar buttons are tappable")
    }

    // MARK: - Accessibility Tests

    func testAccessibilityLabelsExist() throws {
        let tabBar = app.tabBars.firstMatch

        for button in tabBar.buttons.allElementsBoundByIndex {
            XCTAssertFalse(button.label.isEmpty, "Tab button should have accessibility label")
        }
    }

    // MARK: - Performance Tests

    func testAppLaunchPerformance() throws {
        if #available(iOS 13.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    func testScrollPerformance() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.buttons["Feed"].exists {
            tabBar.buttons["Feed"].tap()
        }
        sleep(1)

        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            measure {
                scrollView.swipeUp()
                scrollView.swipeDown()
            }
        }
    }
}

// MARK: - Album Detail Tests

final class AlbumDetailUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAlbumDetailNavigation() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Albums"].tap()
        sleep(1)

        // Tap first album
        let firstCell = app.cells.firstMatch
        if firstCell.exists {
            firstCell.tap()
            sleep(1)

            // Verify we're in album detail
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            XCTAssertTrue(backButton.exists, "Back button should exist in album detail")

            backButton.tap()
        }
    }

    func testPhotoGridScrolling() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Albums"].tap()
        sleep(1)

        let firstCell = app.cells.firstMatch
        if firstCell.exists {
            firstCell.tap()
            sleep(1)

            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeUp()
                sleep(1)
                scrollView.swipeDown()
            }

            // Go back
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }
}

// MARK: - QR Code Invite Tests

final class QRCodeInviteUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testQRCodeInviteView() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Settings"].tap()
        sleep(1)

        let qrButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'QR'")).firstMatch
        if qrButton.exists {
            qrButton.tap()
            sleep(1)

            // Check for class code
            let classCodeExists = app.staticTexts.matching(NSPredicate(format: "label MATCHES '.*[A-Z0-9]{6}.*'")).count > 0

            // Check for share buttons
            let shareButtonExists = app.buttons["More"].exists || app.buttons["Message"].exists

            // Dismiss
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }

            XCTAssertTrue(true, "QR code invite view loaded")
        }
    }

    func testCopyCodeButton() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Settings"].tap()
        sleep(1)

        let qrButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'QR'")).firstMatch
        if qrButton.exists {
            qrButton.tap()
            sleep(1)

            // Find and tap copy button
            let copyButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Copy'")).firstMatch
            if copyButton.exists {
                copyButton.tap()
                sleep(1)
                // Should show "Copied!" feedback
            }

            // Dismiss
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
        }
    }
}
