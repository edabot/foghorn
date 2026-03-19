import SwiftUI
import AppKit

func showAlertWindow(for reminder: Reminder, use24hr: Bool, onDismiss: @escaping () -> Void) {
    let screen = NSScreen.main ?? NSScreen.screens[0]
    let window = AlertNSWindow(
        contentRect: screen.frame,
        styleMask: [.borderless],
        backing: .buffered,
        defer: false,
        screen: screen
    )
    window.dismissCallback = onDismiss
    window.level = .screenSaver
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    window.isOpaque = true
    window.backgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1)

    let hostingView = NSHostingView(rootView: AlertView(reminder: reminder, use24hr: use24hr) {
        window.closeAlert()
    })
    hostingView.frame = screen.frame
    window.contentView = hostingView

    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}

class AlertNSWindow: NSWindow {
    var dismissCallback: (() -> Void)?

    func closeAlert() {
        dismissCallback?()
        orderOut(nil)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
