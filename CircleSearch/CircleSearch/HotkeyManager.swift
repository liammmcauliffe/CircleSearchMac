import Cocoa

class HotkeyManager {
    
    static let shared = HotkeyManager()
    var onActivated: (() -> Void)?
    
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
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Combo: Cmd + Control + S
        let isCmd = flags.contains(.maskCommand)
        let isControl = flags.contains(.maskControl)
        
        if keyCode == 1 && isCmd && isControl { // keyCode 1 = S
            DispatchQueue.main.async {
                self.onActivated?()
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
}