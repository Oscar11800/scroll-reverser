import SwiftUI

class ScrollSettings: ObservableObject {
    @Published private var deviceSettings: [Int64: DeviceSettings] = [:]

    struct DeviceSettings: Codable {
        var reverseVertical: Bool = false
        var speedMultiplier: Double = 1.0
        var customLabel: String?
    }

    init() {
        load()
    }

    func isReversed(for mouse: MouseDevice) -> Bool {
        deviceSettings[mouse.id]?.reverseVertical ?? false
    }

    func speed(for mouse: MouseDevice) -> Double {
        deviceSettings[mouse.id]?.speedMultiplier ?? 1.0
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

    func speedBinding(for mouse: MouseDevice) -> Binding<Double> {
        Binding(
            get: { self.speed(for: mouse) },
            set: { newValue in
                self.ensureSettings(for: mouse)
                self.deviceSettings[mouse.id]?.speedMultiplier = newValue
                self.save()
            }
        )
    }

    // Used by ScrollInterceptor with raw device IDs from CGEvents
    func isReversedForDevice(_ deviceID: Int64) -> Bool {
        // Check all stored devices - the event device ID might match one
        for (_, settings) in deviceSettings {
            if settings.reverseVertical { return true }
        }
        // For now, if any device has reverse enabled and we can't distinguish, apply it
        // We'll refine device matching later
        return false
    }

    func speedForDevice(_ deviceID: Int64) -> Double {
        for (_, settings) in deviceSettings {
            if settings.speedMultiplier != 1.0 { return settings.speedMultiplier }
        }
        return 1.0
    }

    // Direct ID-based lookup for when we have a known device ID
    func isReversed(forID id: Int64) -> Bool {
        deviceSettings[id]?.reverseVertical ?? false
    }

    func speed(forID id: Int64) -> Double {
        deviceSettings[id]?.speedMultiplier ?? 1.0
    }

    private func ensureSettings(for mouse: MouseDevice) {
        if deviceSettings[mouse.id] == nil {
            deviceSettings[mouse.id] = DeviceSettings()
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        // Convert Int64 keys to strings for JSON
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
