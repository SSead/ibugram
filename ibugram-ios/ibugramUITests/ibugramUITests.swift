import XCTest

@MainActor
final class SignInUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSignInScreenOffersTheOneTimeCodeFlow() {
        let app = XCUIApplication()
        app.launch()

        let emailField = app.textFields["University email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 10))

        let sendCode = app.buttons["Send me a code"]
        XCTAssertTrue(sendCode.exists)
        XCTAssertFalse(sendCode.isEnabled)

        emailField.tap()
        emailField.typeText("amina.hodzic@stu.ibu.edu.ba")
        XCTAssertTrue(sendCode.isEnabled)
    }

    func testEnteringAUniversityEmailAdvancesToTheCodeScreen() {
        let app = XCUIApplication()
        app.launchArguments += ["-ibugram-mock-api", "YES"]
        app.launch()

        let emailField = app.textFields["University email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 10))
        emailField.tap()
        emailField.typeText("amina.hodzic@stu.ibu.edu.ba")
        app.buttons["Send me a code"].tap()

        XCTAssertTrue(app.staticTexts["Check your inbox"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Verify and continue"].exists)
    }

    func testSignInScreenRejectsANonUniversityDomain() {
        let app = XCUIApplication()
        app.launch()

        let emailField = app.textFields["University email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 10))
        emailField.tap()
        emailField.typeText("someone@gmail.com")

        XCTAssertFalse(app.buttons["Send me a code"].isEnabled)
    }
}
