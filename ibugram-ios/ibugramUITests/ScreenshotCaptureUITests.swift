import XCTest

private struct ShotNames {
    let feed: String
    let messages: String
    let space: String
    let event: String
    let map: String
    let postDetail: String
    let search: String
    let activity: String
    let profile: String
}

@MainActor
final class ScreenshotCaptureUITests: XCTestCase {
    private let outputDirectory = URL(fileURLWithPath: "/Users/sead/Dev/sdp/docs/screenshots")

    override func setUpWithError() throws {
        continueAfterFailure = true
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    }

    func testCaptureLightScreens() throws {
        captureMainScreens(appearance: .light, names: lightNames)
    }

    func testCaptureDarkScreens() throws {
        captureMainScreens(appearance: .dark, names: darkNames)
    }

    func testCaptureComposerLight() throws {
        captureComposer(appearance: .light, name: "11-composer-light")
    }

    func testCaptureComposerDark() throws {
        captureComposer(appearance: .dark, name: "12-composer-dark")
    }

    func testCaptureOTPDark() throws {
        captureOTP(appearance: .dark, name: "04-otp-verification-dark")
    }

    func testCaptureOnboardingDark() throws {
        captureOnboarding(appearance: .dark, name: "06-onboarding-dark")
    }

    private let lightNames = ShotNames(
        feed: "09-feed-light",
        messages: "21-messages-light",
        space: "23-space-light",
        event: "25-event-light",
        map: "27-map-light",
        postDetail: "13-post-detail-light",
        search: "17-search-idle-light",
        activity: "19-activity-light",
        profile: "15-profile-light"
    )

    private let darkNames = ShotNames(
        feed: "10-feed-dark",
        messages: "22-messages-dark",
        space: "24-space-dark",
        event: "26-event-dark",
        map: "28-map-dark",
        postDetail: "14-post-detail-dark",
        search: "18-search-idle-dark",
        activity: "20-activity-dark",
        profile: "16-profile-dark"
    )

    private func captureMainScreens(appearance: XCUIDevice.Appearance, names: ShotNames) {
        XCUIDevice.shared.appearance = appearance
        let app = launchedApp()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15))
        let feedReady = app.buttons["Space, IBU Robotics"].waitForExistence(timeout: 12)
            || app.buttons["IBU Robotics"].waitForExistence(timeout: 2)
            || app.buttons["Comment"].waitForExistence(timeout: 2)
            || app.buttons["Event, Robotics open lab"].waitForExistence(timeout: 2)
        XCTAssertTrue(feedReady, app.debugDescription)
        save(app, name: names.feed)

        capturePushedScreen(
            app,
            button: "Direct messages",
            ready: { $0.navigationBars["Messages"].waitForExistence(timeout: 12) },
            name: names.messages
        )
        capturePushedScreen(
            app,
            button: "Space, IBU Robotics",
            ready: {
                $0.navigationBars["IBU Robotics"].waitForExistence(timeout: 12)
                    || $0.staticTexts["IBU Robotics"].waitForExistence(timeout: 2)
            },
            name: names.space
        )
        capturePushedScreen(
            app,
            button: "Event, Robotics open lab",
            ready: {
                $0.navigationBars["Robotics open lab"].waitForExistence(timeout: 12)
                    || $0.staticTexts["Robotics open lab"].waitForExistence(timeout: 2)
            },
            name: names.event
        )
        capturePushedScreen(
            app,
            button: "Location, Campus lawn",
            ready: { $0.navigationBars["Campus map"].waitForExistence(timeout: 12) },
            name: names.map
        )

        let comment = app.buttons["Comment"].firstMatch
        XCTAssertTrue(comment.waitForExistence(timeout: 5))
        comment.tap()
        XCTAssertTrue(app.navigationBars["Post"].waitForExistence(timeout: 12))
        for _ in 0..<3 { app.swipeUp() }
        let commentsVisible = app.staticTexts["Beautiful light on the lawn today."].waitForExistence(timeout: 6)
            || app.staticTexts["Comments"].waitForExistence(timeout: 2)
            || app.staticTexts["Come sit with us next time!"].waitForExistence(timeout: 2)
        XCTAssertTrue(commentsVisible, "Expected comments on post detail")
        save(app, name: names.postDetail)
        popIfPossible(app)

        tapTab(app, "Search")
        XCTAssertTrue(app.staticTexts["Trending hashtags"].waitForExistence(timeout: 12))
        save(app, name: names.search)

        tapTab(app, "Activity")
        XCTAssertTrue(
            app.staticTexts["Leila Marković and 4 others liked your post"].waitForExistence(timeout: 12)
                || app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'liked your post'")).firstMatch.waitForExistence(timeout: 4)
        )
        save(app, name: names.activity)

        tapTab(app, "Profile")
        XCTAssertTrue(app.staticTexts["Amina Hodžić"].waitForExistence(timeout: 12))
        save(app, name: names.profile)

        app.terminate()
    }

    private func captureComposer(appearance: XCUIDevice.Appearance, name: String) {
        XCUIDevice.shared.appearance = appearance
        let app = launchedApp(openComposer: true)
        XCTAssertTrue(app.navigationBars["New post"].waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertTrue(
            app.staticTexts["Caption"].waitForExistence(timeout: 6)
                || app.textViews["Caption"].waitForExistence(timeout: 2)
                || app.buttons["Add photos"].waitForExistence(timeout: 2)
        )
        save(app, name: name)
        app.terminate()
    }

    private func captureOTP(appearance: XCUIDevice.Appearance, name: String) {
        XCUIDevice.shared.appearance = appearance
        let app = XCUIApplication()
        app.launchArguments += ["-ibugram-mock-api", "YES", "-ibugram-auth-state", "signed-out"]
        app.launch()

        let email = app.textFields["University email"]
        XCTAssertTrue(email.waitForExistence(timeout: 15), app.debugDescription)
        email.tap()
        email.typeText("amina.hodzic@stu.ibu.edu.ba")
        app.buttons["Send me a code"].tap()

        let code = app.otherElements["Six digit verification code"]
        XCTAssertTrue(code.waitForExistence(timeout: 12), app.debugDescription)
        code.tap()
        code.typeText("4829")
        XCTAssertTrue(app.buttons["Use development code 482913"].waitForExistence(timeout: 4))
        save(app, name: name)
        app.terminate()
    }

    private func captureOnboarding(appearance: XCUIDevice.Appearance, name: String) {
        XCUIDevice.shared.appearance = appearance
        let app = XCUIApplication()
        app.launchArguments += ["-ibugram-mock-api", "YES", "-ibugram-auth-state", "onboarding"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Set up your profile"].waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Add a photo"].waitForExistence(timeout: 6))
        save(app, name: name)
        app.terminate()
    }

    private func launchedApp(openComposer: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-ibugram-mock-api", "YES",
            "-ibugram-auth-state", "signed-in",
        ]
        if openComposer {
            app.launchArguments += ["-ibugram-open-composer", "YES"]
        }
        app.launch()
        return app
    }

    private func capturePushedScreen(
        _ app: XCUIApplication,
        button label: String,
        ready: (XCUIApplication) -> Bool,
        name: String
    ) {
        let control = app.buttons[label].firstMatch
        guard control.waitForExistence(timeout: 6) else { return }
        control.tap()
        XCTAssertTrue(ready(app), "Expected \(name) after tapping \(label)")
        save(app, name: name)
        popIfPossible(app)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 6))
    }

    private func tapTab(_ app: XCUIApplication, _ title: String) {
        let tab = app.tabBars.buttons[title]
        if tab.waitForExistence(timeout: 4) {
            tab.tap()
            return
        }
        app.buttons[title].firstMatch.tap()
    }

    private func popIfPossible(_ app: XCUIApplication) {
        let back = app.navigationBars.buttons.firstMatch
        if back.waitForExistence(timeout: 2) {
            back.tap()
        }
    }

    private func save(_ app: XCUIApplication, name: String) {
        let url = outputDirectory.appendingPathComponent("\(name).png")
        try? app.screenshot().pngRepresentation.write(to: url)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
