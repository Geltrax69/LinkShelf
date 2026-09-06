import AppKit
import Foundation
import XCTest

@MainActor
final class LibraryShellUITests: XCTestCase {
    private func launch(appearance: String = "light", reset: Bool = true) -> XCUIApplication {
        // Otherwise a window left full screen by a previous run (or by hand)
        // is restored and every sheet lookup in the suite misses.
        if reset {
            let saved = URL.libraryDirectory.appending(path: "Saved Application State/com.geltrax69.LinkShelf.savedState")
            try? FileManager.default.removeItem(at: saved)
        }
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--appearance=\(appearance)"]
        if reset { app.launchArguments.append("--reset-preferences") }
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10))
        return app
    }

    func testNavigationAndKeyboardShortcuts() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["Your links, in good company"].exists)
        for (destination, heading) in [
            ("favorites", "Keep the essentials close"),
            ("recent", "Pick up where you left off"),
            ("archive", "A little room for later"),
            ("trash", "Nothing in the trash")
        ] {
            app.staticTexts["destination.\(destination)"].click()
            XCTAssertTrue(app.staticTexts[heading].waitForExistence(timeout: 3))
        }
        app.typeKey("1", modifierFlags: .command)
        XCTAssertTrue(app.staticTexts["Your links, in good company"].exists)
        app.typeKey("2", modifierFlags: .command)
        XCTAssertTrue(app.staticTexts["Keep the essentials close"].exists)
    }

    func testBuildInformationCanBeDismissed() {
        let app = launch()
        app.buttons["buildInformation"].click()
        XCTAssertTrue(app.staticTexts["A foundation for your library"].waitForExistence(timeout: 3))
        app.buttons["Done"].click()
        XCTAssertFalse(app.staticTexts["A foundation for your library"].exists)
    }

    func testLayoutPreferenceSurvivesRelaunch() {
        var app = launch()
        app.buttons["List view"].click()
        XCTAssertTrue(app.staticTexts["List view · 0 links"].exists)
        app.terminate()
        app = launch(reset: false)
        XCTAssertTrue(app.staticTexts["List view · 0 links"].exists)
    }

    func testCompactWindowAndSettings() {
        let app = launch()
        let window = app.windows.firstMatch
        let corner = window.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 1))
            .withOffset(CGVector(dx: -1, dy: -1))
        let target = window.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: 720, dy: 532))
        corner.press(forDuration: 0.1, thenDragTo: target)
        XCTAssertLessThanOrEqual(window.frame.width, 725)
        XCTAssertTrue(app.staticTexts["destination.favorites"].isHittable)
        XCTAssertTrue(app.links["buildInformationFooter"].isHittable)
        let compact = XCTAttachment(screenshot: window.screenshot())
        compact.name = "Library-compact"
        compact.lifetime = .keepAlways
        add(compact)

        app.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(app.popUpButtons["appearancePicker"].waitForExistence(timeout: 3))
        app.popUpButtons["appearancePicker"].click()
        app.menuItems["Dark"].click()
        let settings = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        settings.name = "Settings-dark"
        settings.lifetime = .keepAlways
        add(settings)
    }

    func testLightAndDarkAppearanceScreenshots() {
        for appearance in ["light", "dark"] {
            let app = launch(appearance: appearance)
            let window = app.windows.firstMatch
            let corner = window.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 1))
                .withOffset(CGVector(dx: -1, dy: -1))
            let target = window.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: 1040, dy: 700))
            corner.press(forDuration: 0.1, thenDragTo: target)
            XCTAssertGreaterThanOrEqual(window.frame.width, 1035)
            XCTAssertTrue(app.staticTexts["Your links, in good company"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.staticTexts["destination.all"].isHittable)
            XCTAssertTrue(app.links["buildInformationFooter"].isHittable)
            // Move the pointer away from toolbar controls before capturing tooltips.
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.6)).hover()
            let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
            attachment.name = "Library-\(appearance)"
            attachment.lifetime = .keepAlways
            add(attachment)
            app.terminate()
        }
    }

    func testPasteLinkCreateFolderAndFile() {
        let app = launch()
        app.buttons["addLink"].click()
        let field = app.textFields["linkField"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.click()
        field.typeText("developer.apple.com")
        app.buttons["Save"].click()
        if !app.staticTexts["1 link"].waitForExistence(timeout: 5) {
            XCTFail("link not saved. UI: \(app.debugDescription)")
        }

        app.buttons["newFolder"].click()
        let name = app.textFields["folderNameField"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        name.click()
        name.typeText("Reading")
        app.buttons["Create"].click()
        let folder = app.staticTexts["folder.Reading"]
        XCTAssertTrue(folder.waitForExistence(timeout: 3))

        app.staticTexts["destination.all"].click()
        app.descendants(matching: .any).matching(identifier: "link.developer.apple.com").firstMatch.rightClick()
        app.menuItems["Move to Folder"].click()
        app.menuItems["Reading"].click()
        folder.click()
        XCTAssertTrue(app.staticTexts["1 link"].waitForExistence(timeout: 3))
    }

    func testInvalidPasteIsReported() {
        let app = launch()
        app.buttons["addLink"].click()
        let field = app.textFields["linkField"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.click()
        field.typeText("definitely-not-a-link")
        app.buttons["Save"].click()
        XCTAssertTrue(app.staticTexts["libraryError"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["0 links"].exists)
    }
}