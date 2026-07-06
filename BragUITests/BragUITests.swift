import XCTest

final class BragUITests: XCTestCase {
    private var interruptionMonitorToken: NSObjectProtocol?

    override func setUpWithError() throws {
        continueAfterFailure = false
        interruptionMonitorToken = addUIInterruptionMonitor(withDescription: "System alert dismissal") { alert in
            for label in ["Allow", "OK", "Don't Allow", "Cancel"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
    }

    override func tearDownWithError() throws {
        if let token = interruptionMonitorToken {
            removeUIInterruptionMonitor(token)
        }
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testHomeScreenLoads() throws {
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["Brag"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.buttons["addEntryButton"].waitForExistence(timeout: 12))
    }

    func testAddEntry() throws {
        let app = launchApp()
        app.buttons["addEntryButton"].tap()

        let textField = app.textViews.firstMatch.exists ? app.textViews["entryTextField"] : app.textFields["entryTextField"]
        let field = app.textFields["entryTextField"].exists ? app.textFields["entryTextField"] : app.textViews["entryTextField"]
        XCTAssertTrue(field.waitForExistence(timeout: 12))
        field.tap()
        field.typeText("Shipped the release")

        app.buttons["saveEntryButton"].tap()

        XCTAssertTrue(app.staticTexts["Shipped the release"].waitForExistence(timeout: 12))
        _ = textField
    }

    func testDeleteEntry() throws {
        let app = launchApp()
        app.buttons["addEntryButton"].tap()
        let field = app.textFields["entryTextField"].exists ? app.textFields["entryTextField"] : app.textViews["entryTextField"]
        XCTAssertTrue(field.waitForExistence(timeout: 12))
        field.tap()
        field.typeText("Temp entry")
        app.buttons["saveEntryButton"].tap()

        XCTAssertTrue(app.staticTexts["Temp entry"].waitForExistence(timeout: 12))
        app.staticTexts["Temp entry"].tap()
        app.buttons["deleteEntryButton"].tap()
        XCTAssertFalse(app.staticTexts["Temp entry"].waitForExistence(timeout: 6))
    }

    func testSummaryViewOpens() throws {
        let app = launchApp()
        app.buttons["addEntryButton"].tap()
        let field = app.textFields["entryTextField"].exists ? app.textFields["entryTextField"] : app.textViews["entryTextField"]
        XCTAssertTrue(field.waitForExistence(timeout: 12))
        field.tap()
        field.typeText("A summarized win")
        app.buttons["saveEntryButton"].tap()

        app.buttons["summaryButton"].tap()
        XCTAssertTrue(app.staticTexts["summaryText"].waitForExistence(timeout: 12))
    }

    func testFreeLimitTriggersPaywall() throws {
        let app = launchApp()
        for i in 0..<10 {
            app.buttons["addEntryButton"].tap()
            let field = app.textFields["entryTextField"].exists ? app.textFields["entryTextField"] : app.textViews["entryTextField"]
            if field.waitForExistence(timeout: 8) {
                field.tap()
                field.typeText("Win \(i)")
            }
            app.buttons["saveEntryButton"].tap()
        }
        app.buttons["addEntryButton"].tap()
        XCTAssertTrue(app.staticTexts["Brag Pro"].waitForExistence(timeout: 12), "Paywall did not appear after hitting the free entry limit")
    }

    func testSettingsToggle() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()
        let toggle = app.switches["reminderToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 12))
        toggle.tap()
        XCTAssertTrue(toggle.exists)
    }
}
