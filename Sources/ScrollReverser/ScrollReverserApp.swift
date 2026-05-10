import SwiftUI 

@main
struct ScrollReverserApp: App {
        @State private var isEnabled = true 

        var body: some Scene {
                MenuBarExtra("ScrollReverser", systemImage: "arrow.up.arrow.down") {
                        Toggle("Enabled", isOn: $isEnabled)
                        Divider()
                        Button("Open Settings") {
                                // TODO: 
                        }
                        Divider()
                        Button("Quit") {
                                NSApplication.shared.terminate(nil)
                            }
                    }
            }
    }
