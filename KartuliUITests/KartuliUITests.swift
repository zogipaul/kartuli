import XCTest

final class KartuliUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(unlocked: Bool = false, largeText: Bool = false, reset: Bool = true, suite: String = UUID().uuidString) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--qa-suite", "com.example.kartuli.qa.\(suite)"]
        if reset { app.launchArguments.append("--qa-reset") }
        if unlocked { app.launchArguments.append("--qa-unlocked") }
        if largeText { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 10))
        // Native tab items can enter the accessibility tree before the splash
        // transition is removed. Wait for the actual learning control as well.
        XCTAssertTrue(app.buttons[unlocked ? "Build your first words" : "Continue lesson"].waitForExistence(timeout: 10))
        return app
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    private func screenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testLessonCompletionKeepsOriginalLettersAndPersistsProgress() {
        let suite = UUID().uuidString
        var app = launch(suite: suite)
        app.buttons["Continue lesson"].tap()
        for (index, glyph) in ["ა", "ბ", "გ"].enumerated() {
            let next = app.buttons["Continue"]
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            XCTAssertTrue(next.isHittable)
            next.tap()
            let answer = app.buttons[glyph]
            reveal(answer, in: app)
            answer.tap()
            app.buttons["Check answer"].tap()
            app.buttons[index == 2 ? "Finish lesson" : "Continue"].tap()
        }
        XCTAssertTrue(app.staticTexts["Lesson complete!"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["You added ა  ბ  გ to your alphabet."].exists)
        screenshot(app, name: "Lesson completion")
        app.buttons["Back to Today"].tap()
        XCTAssertTrue(app.staticTexts["STREAK SECURED"].waitForExistence(timeout: 5))
        app.terminate()
        app = launch(reset: false, suite: suite)
        XCTAssertTrue(app.staticTexts["STREAK SECURED"].exists)
        app.buttons["Continue lesson"].tap()
        XCTAssertTrue(app.buttons["Close lesson"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["დ"].exists)
        app.buttons["Close lesson"].tap()
    }

    func testLargeTextLessonActionsRemainReachable() {
        let app = launch(largeText: true)
        app.buttons["Continue lesson"].tap()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Continue"].isHittable)
        screenshot(app, name: "Large text discovery")
        app.buttons["Continue"].tap()
        let answer = app.buttons["ა"]
        reveal(answer, in: app)
        answer.tap()
        XCTAssertTrue(app.buttons["Check answer"].isHittable)
        app.buttons["Check answer"].tap()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
        let feedback = app.staticTexts["Brilliant! That’s ani."]
        reveal(feedback, in: app)
        XCTAssertTrue(app.buttons["Continue"].isHittable)
        screenshot(app, name: "Large text quiz")
    }

    func testUnlockedPracticeAndProfileNavigation() {
        let app = launch(unlocked: true, largeText: true)
        app.buttons["Build your first words"].tap()
        let build = app.buttons["Build this word"]
        XCTAssertTrue(build.waitForExistence(timeout: 5))
        XCTAssertTrue(build.isHittable)
        build.tap()
        XCTAssertTrue(app.buttons["Show word again"].exists)
        app.buttons["Show word again"].tap()
        XCTAssertTrue(build.isHittable)
        app.buttons["End word practice"].tap()
        XCTAssertTrue(app.buttons["Finish for now"].isHittable)
        app.buttons["Finish for now"].tap()
        app.tabBars.buttons["Alphabet"].tap()
        let endless = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Keep the letters flowing")).firstMatch
        reveal(endless, in: app)
        endless.tap()
        XCTAssertTrue(app.buttons["End endless practice"].waitForExistence(timeout: 5))
        let check = app.buttons["Check answer"]
        XCTAssertTrue(check.isHittable)
        XCTAssertFalse(check.isEnabled)
        screenshot(app, name: "Large text endless practice")
        app.buttons["End endless practice"].tap()
        XCTAssertTrue(app.buttons["Finish for now"].isHittable)
        app.buttons["Finish for now"].tap()
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.buttons["Choose profile avatar"].waitForExistence(timeout: 5))
        app.buttons["Choose profile avatar"].tap()
        XCTAssertTrue(app.navigationBars["Choose avatar"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
    }
}
