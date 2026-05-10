import SwiftUI
import ApplicationServices

@main
struct ScrollReverserApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("ScrollReverser", systemImage: "arrow.up.arrow.down") {
            MenuBarView(appState: appState)
        }

        Window("ScrollReverser Settings", id: "settings") {
            SettingsView()
        }
    }
}

class AppState: ObservableObject {
    @Published var isEnabled = true {
        didSet {
            interceptor.setEnabled(isEnabled)
        }
    }

    let settings = ScrollSettings()
    let interceptor: ScrollInterceptor
    @Published private(set) var tapActive = false

    init() {
        interceptor = ScrollInterceptor(settings: settings)
        tapActive = interceptor.start()

        if !tapActive {
            showAccessibilityPrompt()
        }
    }

    func showAccessibilityPrompt() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "ScrollReverser needs Accessibility access to intercept and modify scroll events. Please enable it in System Settings, then relaunch the app."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            }
        }
    }

    func retryEventTap() {
        tapActive = interceptor.start()
    }
}

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Toggle("Enabled", isOn: $appState.isEnabled)
        Divider()
        if !appState.tapActive {
            Button("⚠ Grant Accessibility Access") {
                appState.showAccessibilityPrompt()
            }
            Button("Retry") {
                appState.retryEventTap()
            }
            Divider()
        }
        Button("Open Settings") {
            NSApp.setActivationPolicy(.regular)
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
