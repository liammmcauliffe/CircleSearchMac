import Cocoa

class PreferencesWindow: NSWindowController {
    
    static let shared = PreferencesWindow()
    
    private var shortcutButton: NSButton!
    private var statusLabel: NSTextField!
    private var isRecording = false
    private var monitor: Any?
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "CircleSearch Preferences"
        window.center()
        
        self.init(window: window)
        setupUI()
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        let titleLabel = NSTextField(labelWithString: "Activation shortcut")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.frame = NSRect(x: 20, y: 130, width: 320, height: 20)
        contentView.addSubview(titleLabel)
        
        shortcutButton = NSButton(title: Preferences.shared.shortcutString, target: self, action: #selector(toggleRecording))
        shortcutButton.bezelStyle = .rounded
        shortcutButton.frame = NSRect(x: 20, y: 90, width: 320, height: 32)
        contentView.addSubview(shortcutButton)
        
        statusLabel = NSTextField(labelWithString: "Click the button, then press your desired key combo.")
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.frame = NSRect(x: 20, y: 60, width: 320, height: 16)
        contentView.addSubview(statusLabel)
    }
    
    @objc private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        HotkeyManager.shared.isPaused = true   // ← add this
        shortcutButton.title = "Press a key combination..."
        statusLabel.stringValue = "Press any key with at least one modifier (⌘ ⌃ ⌥ ⇧)"
        
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil // swallow the event
        }
    }
    
    private func stopRecording() {
        isRecording = false
        HotkeyManager.shared.isPaused = false   // ← add this
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        shortcutButton.title = Preferences.shared.shortcutString
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        let modifiers = event.modifierFlags
        var cgFlags: UInt64 = 0
        if modifiers.contains(.command)   { cgFlags |= CGEventFlags.maskCommand.rawValue }
        if modifiers.contains(.control)   { cgFlags |= CGEventFlags.maskControl.rawValue }
        if modifiers.contains(.option)    { cgFlags |= CGEventFlags.maskAlternate.rawValue }
        if modifiers.contains(.shift)     { cgFlags |= CGEventFlags.maskShift.rawValue }
        
        // Require at least one modifier so we don't trap normal typing
        guard cgFlags != 0 else {
            statusLabel.stringValue = "Need at least one modifier key (⌘ ⌃ ⌥ ⇧)"
            return
        }
        
        Preferences.shared.keyCode = Int(event.keyCode)
        Preferences.shared.modifiers = cgFlags
        statusLabel.stringValue = "Saved! New shortcut: \(Preferences.shared.shortcutString)"
        stopRecording()
    }
    
    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}