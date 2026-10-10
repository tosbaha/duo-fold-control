import Foundation
import XCTest

/// Changes the iPhone Duo simulator's fold state from a UI test.
///
/// The test runner runs inside the simulator and can't change the hinge itself, so it
/// calls `tools/duo-hinge-server.py` on the Mac (the simulator shares the host network),
/// which runs `tools/duo-hinge` against this simulator.
enum DuoFold: String {
    case closed   // 0°   - folded, cover display
    case half     // 130° - half unfolded
    case flat     // 180° - fully unfolded, inner display

    static var serverPort = 8765

    static func set(_ state: DuoFold, file: StaticString = #filePath, line: UInt = #line) {
        setAngle(state.rawValue, file: file, line: line)
    }

    /// Any angle from 0 to 180 degrees.
    static func set(degrees: Double, file: StaticString = #filePath, line: UInt = #line) {
        setAngle(String(degrees), file: file, line: line)
    }

    private static func setAngle(_ value: String, file: StaticString, line: UInt) {
        let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? "booted"
        var components = URLComponents(string: "http://127.0.0.1:\(serverPort)/hinge")!
        components.queryItems = [.init(name: "state", value: value), .init(name: "udid", value: udid)]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 15
        let done = DispatchSemaphore(value: 0)
        var failure: String?
        URLSession.shared.dataTask(with: request) { data, response, error in
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            if let error {
                failure = "duo-hinge-server not reachable (is it running?): \(error.localizedDescription)"
            } else if (response as? HTTPURLResponse)?.statusCode != 200 {
                failure = "duo-hinge failed: \(body)"
            }
            done.signal()
        }.resume()
        done.wait()
        if let failure { XCTFail(failure, file: file, line: line) }
    }
}

/// The two screens of the iPhone Duo.
///
/// Only one is on at a time: the cover display when folded (`closed`), the inner display
/// when unfolded (`half`, `flat`). A screenshot of the display that's off is all black.
enum DuoDisplay: CaseIterable {
    case cover   // outside screen, 1398 × 2034 px
    case inner   // inside screen,  2006 × 2852 px

    /// Takes a screenshot of this display.
    func screenshot() -> XCUIScreenshot {
        // XCUIScreen.main is always the cover display; tell the screens apart by size.
        let shots = XCUIScreen.screens.map { $0.screenshot() }
            .sorted { $0.image.size.width * $0.image.size.height < $1.image.size.width * $1.image.size.height }
        return self == .cover ? shots.first! : shots.last!
    }
}

extension XCTestCase {
    /// Attaches a screenshot of `display` to the test result under `name`.
    /// Attachments are kept even when the test passes, unless you pass another `lifetime`.
    func attachScreenshot(_ name: String, of display: DuoDisplay,
                          lifetime: XCTAttachment.Lifetime = .keepAlways) {
        let attachment = XCTAttachment(screenshot: display.screenshot())
        attachment.name = name
        attachment.lifetime = lifetime
        add(attachment)
    }
}
