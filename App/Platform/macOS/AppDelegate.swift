import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!

    /// `NSApplication.delegate` is a weak reference, so the delegate — and the window it
    /// owns — needs an owner that outlives `main()`.
    private static var retained: AppDelegate?

    /// AppKit's default `main()` only calls `NSApplicationMain`, which wires the delegate
    /// through a nib or storyboard. There is none here, so the delegate is set by hand.
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        retained = delegate
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = MacGameViewController()
        window = NSWindow(contentViewController: controller)
        window.title = "Barrel Climb"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.contentAspectRatio = NSSize(width: 7, height: 8)
        window.setContentSize(NSSize(width: 448, height: 512))
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(controller.view)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        installMenu()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func installMenu() {
        let menu = NSMenu()
        let app = NSMenuItem(); menu.addItem(app)
        let sub = NSMenu()
        sub.addItem(withTitle: "Quit Barrel Climb", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        app.submenu = sub
        NSApp.mainMenu = menu
    }
}
