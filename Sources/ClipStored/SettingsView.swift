import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @ObservedObject private var clipboardManager = ClipboardManager.shared
    
    // Settings
    @AppStorage("maxHistorySize") private var maxHistorySize = 50
    @AppStorage("displayLimit") private var displayLimit = 20
    @AppStorage("startAtLogin") private var startAtLogin = false
    @AppStorage("playSound") private var playSound = true
    @AppStorage("autoCloseAfterCopy") private var autoCloseAfterCopy = true
    @AppStorage("keepInDock") private var keepInDock = false
    
    var body: some View {
        TabView {
            // General Settings
            VStack(spacing: 20) {
                Form {
                    Section("History") {
                        Stepper("Maximum history size: \(maxHistorySize)", value: $maxHistorySize, in: 10...200, step: 10)
                            .help("The maximum number of items to keep in history")
                        
                        Stepper("Display limit: \(displayLimit)", value: $displayLimit, in: 5...50, step: 5)
                            .help("The number of items to show in the clipboard history view")
                    }
                    
                    Section("Behavior") {
                        Toggle("Start at login", isOn: $startAtLogin)
                            .onChange(of: startAtLogin) { newValue in
                                // In a real implementation, we would use SMAppService
                                print("Start at login: \(newValue)")
                            }
                        
                        Toggle("Play sound when copying", isOn: $playSound)
                        
                        Toggle("Auto-close window after copy", isOn: $autoCloseAfterCopy)
                            .help("Automatically close the history window after selecting an item")
                            
                        Toggle("Keep in Dock", isOn: $keepInDock)
                            .onChange(of: keepInDock) { newValue in
                                // Update activation policy based on preference
                                DispatchQueue.main.async {
                                    if newValue {
                                        // Regular app - appears in Dock
                                        NSApp.setActivationPolicy(.regular)
                                    } else {
                                        // Accessory app - no Dock icon, just menu bar
                                        NSApp.setActivationPolicy(.accessory)
                                    }
                                }
                            }
                            .help("Show the app in the Dock even when all windows are closed")
                    }
                    
                    Section("Keyboard Shortcuts") {
                        KeyboardShortcuts.Recorder("Show clipboard history:", name: .toggleClipboardHistory)
                            .padding(.vertical, 5)
                    }
                    
                    Section("Management") {
                        HStack {
                            Text("Current items: \(clipboardManager.clipboardHistory.count)")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Clear History") {
                                print("Clearing clipboard history from settings")
                                NotificationCenter.default.post(name: .clearClipboardHistory, object: nil)
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            // About
            VStack(spacing: 20) {
                Image(systemName: "clipboard")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("ClipSync")
                    .font(.title)
                    .bold()
                
                Text("Version 1.0")
                    .foregroundColor(.secondary)
                
                Text("A simple clipboard manager for macOS.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Link("GitHub", destination: URL(string: "https://github.com/yourusername/clipsync")!)
                        .buttonStyle(.bordered)
                    
                    Button("Close") {
                        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "settings-window" }) {
                            window.close()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .padding()
        .frame(width: 400, height: 400)
        .onAppear {
            print("Settings view appeared")
        }
        .onDisappear {
            print("Settings view disappeared")
            // Save any additional settings if needed
        }
    }
}

// Notification name for clearing history
extension Notification.Name {
    static let clearClipboardHistory = Notification.Name("clearClipboardHistory")
}

#Preview {
    SettingsView()
} 