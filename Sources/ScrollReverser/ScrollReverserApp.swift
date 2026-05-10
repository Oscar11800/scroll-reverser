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

                Window("ScrollReverser Settings", id: "settings") {
                        SettingsView()
                }
        }
}

struct SettingsView: View {
        var body: some View {
                Text("Settings here")
                    .frame(width: 400, height: 300)
                    .padding()
        }
}

