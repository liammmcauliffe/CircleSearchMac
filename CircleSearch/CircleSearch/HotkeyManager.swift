import Cocoa

class HotkeyManager {
    
    static let shared = HotkeyManager()
    var onActivated: (() -> Void)?
    var isPaused = false 
    
    private var eventTap: CFMachPort?
    
    func start() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon!).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap — check Accessibility permissions")
            return
        }
        
        self.eventTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("Hotkey listener running")
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Re-enable the tap if macOS disabled it (timeout or other reasons)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                print("Event tap was disabled — re-enabled")
            }
            return Unmanaged.passUnretained(event)
        }
        
        if isPaused { return Unmanaged.passUnretained(event) }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags.rawValue
        
        let savedKeyCode = Preferences.shared.keyCode
        let savedModifiers = Preferences.shared.modifiers
        
        let relevantMask: UInt64 = CGEventFlags.maskCommand.rawValue | CGEventFlags.maskControl.rawValue | CGEventFlags.maskShift.rawValue | CGEventFlags.maskAlternate.rawValue
        
        if Int(keyCode) == savedKeyCode && (flags & relevantMask) == savedModifiers {
            DispatchQueue.main.async {
                self.onActivated?()
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
}