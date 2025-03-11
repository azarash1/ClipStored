import SwiftUI
import KeyboardShortcuts

@main
struct ClipStoredApp: App {
    @StateObject private var clipboardManager = ClipboardManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover?
    private var settingsWindow: NSWindow?
    private var settingsDelegate: WindowDelegate?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipStored")
            createStatusMenu()
        }
        
        // Setup keyboard shortcuts
        if KeyboardShortcuts.getShortcut(for: .toggleClipboardHistory) == nil {
            KeyboardShortcuts.setShortcut(.init(.v, modifiers: [.command, .shift]), for: .toggleClipboardHistory)
        }
        
        // Setup keyboard shortcut handler
        KeyboardShortcuts.onKeyDown(for: .toggleClipboardHistory) { [weak self] in
            self?.togglePopover()
        }
        
        // Create window delegate
        settingsDelegate = WindowDelegate(identifier: "settings-window")
        
        // Create popover
        setupPopover()
    }
    
    private func createStatusMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Show Clipboard History", action: #selector(togglePopover), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(toggleSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: ClipboardHistoryView()
                .environmentObject(ClipboardManager.shared)
        )
    }
    
    @objc func togglePopover() {
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                showPopover()
            }
        }
    }
    
    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        // Ensure popover is key window and can receive keyboard events
        if let window = popover?.contentViewController?.view.window {
            window.makeKey()
        }
    }
    
    @objc func toggleSettings() {
        if let settingsWindow = settingsWindow {
            if settingsWindow.isVisible {
                settingsWindow.orderOut(nil)
            } else {
                settingsWindow.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ClipStored Settings"
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.delegate = settingsDelegate
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        
        settingsWindow = window
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// Simple window delegate to prevent app termination when window is closed
class WindowDelegate: NSObject, NSWindowDelegate {
    private let windowIdentifier: String
    
    init(identifier: String) {
        self.windowIdentifier = identifier
        super.init()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
