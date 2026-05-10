import SwiftUI

class ScrollSettings: ObservableObject {
    @Published private var deviceSettings: [Int64: DeviceSettings] = [:]

    struct DeviceSettings: Codable {
        var reverseVertical: Bool = false
        var customLabel: String?
    }

    init() {
        load()
    }

    func isReversed(for mouse: MouseDevice) -> Bool {
        deviceSettings[mouse.id]?.reverseVertical ?? false
    }

    func customLabel(for mouse: MouseDevice) -> String? {
        deviceSettings[mouse.id]?.customLabel
    }

    func setCustomLabel(_ label: String?, for mouse: MouseDevice) {
        ensureSettings(for: mouse)
        deviceSettings[mouse.id]?.customLabel = label
        save()
    }

    func reverseBinding(for mouse: MouseDevice) -> Binding<Bool> {
        Binding(
            get: { self.isReversed(for: mouse) },
            set: { newValue in
                self.ensureSettings(for: mouse)
                self.deviceSettings[mouse.id]?.reverseVertical = newValue
                self.save()
            }
        )
    }

    // Used by ScrollInterceptor
    func isReversedForDevice(_ deviceID: Int64) -> Bool {
        for (_, settings) in deviceSettings {
            if settings.reverseVertical { return true }
        }
        return false
    }

    private func ensureSettings(for mouse: MouseDevice) {
        if deviceSettings[mouse.id] == nil {
            deviceSettings[mouse.id] = DeviceSettings()
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        let stringKeyed = Dictionary(uniqueKeysWithValues: deviceSettings.map { (String($0.key), $0.value) })
        if let data = try? encoder.encode(stringKeyed) {
            UserDefaults.standard.set(data, forKey: "deviceSettings")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: "deviceSettings"),
              let stringKeyed = try? JSONDecoder().decode([String: DeviceSettings].self, from: data) else { return }
        deviceSettings = Dictionary(uniqueKeysWithValues: stringKeyed.compactMap { key, value in
            guard let intKey = Int64(key) else { return nil }
            return (intKey, value)
        })
    }
}
