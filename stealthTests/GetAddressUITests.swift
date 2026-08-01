import XCTest

final class GetAddressUITests: XCTestCase {
    func testGetAddress() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)
        
        let nextButton = app.buttons["Next"]
        if nextButton.exists {
            nextButton.tap()
            sleep(1)
            app.buttons["Create new wallet"].tap()
            sleep(10) // Wait for wallet generation
            
            // Assuming we are on Home screen
            app.buttons["Receive"].tap()
            sleep(2)
            
            let addressText = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'fY'")).firstMatch
            if addressText.exists {
                print("IOS_WALLET_ADDRESS: \(addressText.label)")
            }
        }
    }
}
