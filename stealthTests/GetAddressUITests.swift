import XCTest

final class GetAddressUITests: XCTestCase {
    func testGetAddress() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        // Welcome / onboarding: skip carousel pages if present, then create.
        let nextButton = app.buttons["Next"]
        while nextButton.exists && nextButton.isHittable {
            nextButton.tap()
            sleep(1)
        }

        let create = app.buttons["Create Wallet"].exists
            ? app.buttons["Create Wallet"]
            : app.buttons["CREATE WALLET"]
        XCTAssertTrue(create.waitForExistence(timeout: 10), "Create Wallet button missing")
        create.tap()
        sleep(12) // Wait for wallet generation

        let receive = app.buttons["Receive"]
        XCTAssertTrue(receive.waitForExistence(timeout: 30), "Receive tab missing after create")
        receive.tap()
        sleep(2)

        // Testnet DarkFi addresses are base58 and typically start with 'f'.
        let addressText = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH 'f' AND length > 40")
        ).firstMatch
        XCTAssertTrue(addressText.waitForExistence(timeout: 15), "Deposit address not shown")
        print("IOS_WALLET_ADDRESS: \(addressText.label)")
    }
}
