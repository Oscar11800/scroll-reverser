import Foundation
import IOKit
import IOKit.hid

struct MouseDevice: Identifiable, Hashable {
    let id: Int64
    let productName: String
    let vendorID: Int
    let productID: Int
}

class DeviceManager: ObservableObject {
    @Published var connectedMice: [MouseDevice] = []
    private var hidManager: IOHIDManager?

    init() {
        setupHIDManager()
    }

    private func setupHIDManager() {
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let manager = hidManager else { return }

        // Filter for mice only
        let matchingDict: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Mouse
        ]
        IOHIDManagerSetDeviceMatching(manager, matchingDict as CFDictionary)

        // Register connect/disconnect callbacks
        let context = Unmanaged.passUnretained(self).toOpaque()

        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, _, _, device in
            guard let context = context else { return }
            let this = Unmanaged<DeviceManager>.fromOpaque(context).takeUnretainedValue()
            this.deviceConnected(device)
        }, context)

        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, device in
            guard let context = context else { return }
            let this = Unmanaged<DeviceManager>.fromOpaque(context).takeUnretainedValue()
            this.deviceDisconnected(device)
        }, context)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    private func deviceConnected(_ device: IOHIDDevice) {
        guard let mouse = mouseFromDevice(device) else { return }
        DispatchQueue.main.async {
            if !self.connectedMice.contains(where: { $0.id == mouse.id }) {
                self.connectedMice.append(mouse)
            }
        }
    }

    private func deviceDisconnected(_ device: IOHIDDevice) {
        guard let mouse = mouseFromDevice(device) else { return }
        DispatchQueue.main.async {
            self.connectedMice.removeAll(where: { $0.id == mouse.id })
        }
    }

    private func mouseFromDevice(_ device: IOHIDDevice) -> MouseDevice? {
        let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Unknown Mouse"
        let vendorID = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        let productID = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0

        // Filter out non-mouse devices
        let lowercaseName = name.lowercased()
        let excludedKeywords = ["trackpad", "touchpad", "keyboard"]
        if excludedKeywords.contains(where: { lowercaseName.contains($0) }) {
            return nil
        }

        // Filter out Apple internal devices (vendor ID 0x05AC = Apple)
        let appleVendorID = 0x05AC
        if vendorID == appleVendorID {
            return nil
        }

        // Create a unique ID from vendor + product + location
        let locationID = IOHIDDeviceGetProperty(device, kIOHIDLocationIDKey as CFString) as? Int ?? 0
        let uniqueID = Int64(vendorID) << 32 | Int64(productID) << 16 | Int64(locationID & 0xFFFF)

        return MouseDevice(id: uniqueID, productName: name, vendorID: vendorID, productID: productID)
    }

    deinit {
        if let manager = hidManager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }
    }
}
