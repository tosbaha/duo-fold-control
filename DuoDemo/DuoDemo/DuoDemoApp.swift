import SwiftUI

@main
struct DuoDemoApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

/// Shows the size of the app's window so UI tests can tell which display
/// (cover or inner) the app is on after a fold-state change.
struct ContentView: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            VStack(spacing: 12) {
                Text(size.width > 600 ? "Inner display" : "Cover display")
                    .font(.largeTitle)
                    .accessibilityIdentifier("displayName")
                Text("\(Int(size.width.rounded()))x\(Int(size.height.rounded()))")
                    .font(.title2.monospacedDigit())
                    .accessibilityIdentifier("windowSize")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }
}
