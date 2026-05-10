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

    guard interceptor.isEnabled else {
        return Unmanaged.passUnretained(event)
    }

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = interceptor.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    // Check if reverse is enabled for any device
    let senderID = Int64(event.getIntegerValueField(CGEventField(rawValue: 87)!))
    let isReversed = interceptor.settings.isReversedForDevice(senderID)

    guard isReversed else {
        return Unmanaged.passUnretained(event)
    }

    // Flip all vertical scroll deltas
    let lineDelta = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
    event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -lineDelta)

    let pointDelta = event.getDoubleValueField(CGEventField(rawValue: 11)!)
    event.setDoubleValueField(CGEventField(rawValue: 11)!, value: -pointDelta)

    let fixedDelta = event.getIntegerValueField(CGEventField(rawValue: 93)!)
    event.setIntegerValueField(CGEventField(rawValue: 93)!, value: -fixedDelta)

    return Unmanaged.passUnretained(event)
}
