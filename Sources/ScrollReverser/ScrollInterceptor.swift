import Foundation
import CoreGraphics

class ScrollInterceptor {
    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    fileprivate let settings: ScrollSettings
    var isEnabled: Bool = true

    init(settings: ScrollSettings) {
        self.settings = settings
    }

    func start() -> Bool {
        let eventMask = (1 << CGEventType.scrollWheel.rawValue)

        // Create the event tap
        // We pass `self` as userInfo so the callback can access our instance
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: scrollCallback,
            userInfo: selfPtr
        )

        guard let eventTap = eventTap else {
            // This fails if Accessibility permission is not granted
            return false
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        return true
    }

    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: enabled)
        }
    }
}

// This must be a free function (not a method) because it's a C callback
private func scrollCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let interceptor = Unmanaged<ScrollInterceptor>.fromOpaque(userInfo).takeUnretainedValue()

    // If globally disabled, pass through unchanged
    guard interceptor.isEnabled else {
        return Unmanaged.passUnretained(event)
    }

    // If the tap was disabled by the system (e.g., timeout), re-enable it
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = interceptor.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    // Get the source device ID from the event
    // Field 87 is the HID device sender ID
    let senderID = Int64(event.getIntegerValueField(CGEventField(rawValue: 87)!))

    // Get settings for this device
    let isReversed = interceptor.settings.isReversedForDevice(senderID)
    let speed = interceptor.settings.speedForDevice(senderID)

    // Only modify if there's something to change
    if !isReversed && speed == 1.0 {
        return Unmanaged.passUnretained(event)
    }

    // Get current scroll deltas
    let scrollDeltaY = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
    let scrollPointDeltaY = event.getDoubleValueField(CGEventField(rawValue: 11)!) // scrollWheelEventPointDeltaAxis1

    // Apply reverse
    let reverseFactor: Int64 = isReversed ? -1 : 1

    // Apply speed and reverse to the scroll values
    let newDeltaY = scrollDeltaY * reverseFactor * Int64(speed)
    let newPointDeltaY = scrollPointDeltaY * Double(reverseFactor) * speed

    event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: newDeltaY)
    event.setDoubleValueField(CGEventField(rawValue: 11)!, value: newPointDeltaY)

    return Unmanaged.passUnretained(event)
}
