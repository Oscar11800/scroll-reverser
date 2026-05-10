import SwiftUI

struct SettingsView: View {
    @StateObject private var deviceManager = DeviceManager()
    @ObservedObject var settings: ScrollSettings
    @State private var launchAtLogin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connected Mice")
                .font(.headline)

            if deviceManager.connectedMice.isEmpty {
                Text("No mice connected")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(deviceManager.connectedMice) { mouse in
                            MouseSettingsRow(mouse: mouse, settings: settings)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()

            HStack {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        LoginItemManager.setEnabled(newValue)
                    }
                Spacer()
            }
        }
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
        .padding()
        .onAppear {
            launchAtLogin = LoginItemManager.isEnabled
        }
    }
}

struct MouseSettingsRow: View {
    let mouse: MouseDevice
    @ObservedObject var settings: ScrollSettings
    @State private var isEditingLabel = false
    @State private var editText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if isEditingLabel {
                    TextField("Device name", text: $editText, onCommit: {
                        settings.setCustomLabel(editText.isEmpty ? nil : editText, for: mouse)
                        isEditingLabel = false
                    })
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
                } else {
                    Text(settings.customLabel(for: mouse) ?? mouse.productName)
                        .font(.headline)
                    Button(action: {
                        editText = settings.customLabel(for: mouse) ?? mouse.productName
                        isEditingLabel = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }

            Toggle("Reverse Vertical Scroll", isOn: settings.reverseBinding(for: mouse))
        }
        .padding(.vertical, 8)
    }
}
