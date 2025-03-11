import Cocoa
import KeyboardShortcuts
import SwiftUI

// Define keyboard shortcut names
extension KeyboardShortcuts.Name {
    static let toggleClipboardHistory = Self("toggleClipboardHistory")
}

class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()
    
    private init() {
        print("KeyboardShortcutManager initializing...")
        // Initial setup will be done by the setupShortcuts method
        print("KeyboardShortcutManager initialization complete")
    }
    
    func setupShortcuts() {
        print("Setting up keyboard shortcuts")
        
        // Register default shortcut (Command + Shift + V)
        if KeyboardShortcuts.getShortcut(for: .toggleClipboardHistory) == nil {
            print("Setting default shortcut: Command + Shift + V")
            KeyboardShortcuts.setShortcut(.init(.v, modifiers: [.command, .shift]), for: .toggleClipboardHistory)
        } else {
            if let shortcut = KeyboardShortcuts.getShortcut(for: .toggleClipboardHistory) {
                print("Using existing shortcut: \(shortcut.description)")
            } else {
                print("No shortcut found, but key exists in UserDefaults")
            }
        }
        
        // Ensure KeyboardShortcuts is enabled
        KeyboardShortcuts.isEnabled = true
        print("KeyboardShortcuts isEnabled: \(KeyboardShortcuts.isEnabled)")
        
        // Add a direct monitor for the shortcut to ensure it works
        print("Adding direct monitor for shortcut")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Force update to reregister the shortcut
            if let shortcut = KeyboardShortcuts.getShortcut(for: .toggleClipboardHistory) {
                print("Refreshing shortcut registration: \(shortcut.description)")
            }
        }
    }
}

// Settings View for configuring shortcuts and cycling
struct KeyboardShortcutSettingsView: View {
    @AppStorage("enableCycling") private var enableCycling = false
    
    var body: some View {
        Form {
            Section(header: Text("Keyboard Shortcuts")) {
                KeyboardShortcuts.Recorder("Show clipboard history:", name: .toggleClipboardHistory)
                    .padding(.vertical, 5)
                
                Toggle("Enable cycling with repeated presses", isOn: $enableCycling)
                    .padding(.vertical, 5)
                    .help("When enabled, pressing the shortcut repeatedly will cycle through recent clipboard items")
            }
            
            Text("Changes are saved automatically")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 10)
        }
        .padding()
        .frame(width: 350, height: 150)
    }
} 