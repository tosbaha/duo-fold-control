import XCTest

final class DuoFoldUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        DuoFold.set(.closed)   // start every test from a known state
        app.launch()
    }

    func testSwitchingFoldStatesDuringTest() {
        let display = app.staticTexts["displayName"]

        waitFor(display, label: "Cover display")
        let coverSize = app.staticTexts["windowSize"].label
        attachScreenshot("1-closed", of: .cover)

        DuoFold.set(.flat)
        waitFor(display, label: "Inner display")
        XCTAssertNotEqual(app.staticTexts["windowSize"].label, coverSize)
        attachScreenshot("2-flat", of: .inner)

        DuoFold.set(.half)
        waitFor(display, label: "Inner display")   // half open keeps the inner display
        attachScreenshot("3-half", of: .inner)

        DuoFold.set(.closed)
        waitFor(display, label: "Cover display")
        XCTAssertEqual(app.staticTexts["windowSize"].label, coverSize)
        attachScreenshot("4-closed-again", of: .cover)
    }

    private func waitFor(_ element: XCUIElement, label: String,
                         timeout: TimeInterval = 10, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "label == %@", label)
        let result = XCTWaiter().wait(for: [expectation(for: predicate, evaluatedWith: element)], timeout: timeout)
        XCTAssertEqual(result, .completed, "Expected '\(label)', got '\(element.label)'", file: file, line: line)
    }
}
