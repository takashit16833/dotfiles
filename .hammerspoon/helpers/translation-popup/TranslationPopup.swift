import AppKit
import SwiftUI
import Translation

private struct TranslationAnchorView: View {
    let text: String
    @State private var isPresented = false

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .translationPresentation(
                isPresented: $isPresented,
                text: text,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .top
            )
            .onAppear {
                // Wait until the hosting view belongs to a visible key window before
                // asking SwiftUI to present the system translation popover.
                DispatchQueue.main.async {
                    isPresented = true
                }
            }
            .onChange(of: isPresented) { _, value in
                // translationPresentation toggles the binding back to false when
                // the popover is dismissed. The helper has no other UI, so exit.
                if !value {
                    NSApp.terminate(nil)
                }
            }
    }
}

// A borderless window normally cannot become the key window. This invisible
// anchor must be key before translationPresentation opens its popover so the
// popover starts active instead of requiring an initial click.
private final class FocusableAnchorPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let text: String
    private var anchorWindow: NSPanel?

    init(text: String) {
        self.text = text
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let mouseLocation = NSEvent.mouseLocation

        let panel = FocusableAnchorPanel(
            contentRect: NSRect(
                x: mouseLocation.x,
                y: mouseLocation.y,
                width: 1,
                height: 1
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: TranslationAnchorView(text: text))

        // Keep the invisible anchor window alive for as long as the translation
        // popover is visible and place it at the current mouse position.
        anchorWindow = panel

        // translationPresentation inherits activation from its host window.
        // Make the helper active and the invisible anchor key up front so the
        // system popover can be dismissed by clicking elsewhere immediately.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }
}

@main
private struct TranslationPopupMain {
    private static var appDelegate: AppDelegate?

    static func main() {
        let text = CommandLine.arguments.dropFirst().joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            fputs("TranslationPopup: text argument is required\n", stderr)
            exit(2)
        }

        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        let delegate = AppDelegate(text: text)
        appDelegate = delegate
        app.delegate = delegate
        app.run()
    }
}
