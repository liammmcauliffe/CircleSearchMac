import Cocoa

class PreferencesWindow: NSWindowController {
    
    static let shared = PreferencesWindow()
    
    private var shortcutButton: NSButton!
    private var statusLabel: NSTextField!
    private var enginePopup: NSPopUpButton!
    private var modePopup: NSPopUpButton!
    private var isRecording = false
    private var monitor: Any?
    
    private var pendingKeyCode: Int = 0
    private var pendingModifiers: UInt64 = 0
    private var pendingEngine: SearchEngine = .googleLens
    private var pendingMode: SelectionMode = .lasso
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 370),
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
        
        // Shortcut section
        let shortcutTitle = NSTextField(labelWithString: "Activation shortcut")
        shortcutTitle.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        shortcutTitle.frame = NSRect(x: 20, y: 330, width: 320, height: 20)
        contentView.addSubview(shortcutTitle)
        
        shortcutButton = NSButton(title: Preferences.shared.shortcutString, target: self, action: #selector(toggleRecording))
        shortcutButton.bezelStyle = .rounded
        shortcutButton.frame = NSRect(x: 20, y: 290, width: 320, height: 32)
        contentView.addSubview(shortcutButton)
        
        statusLabel = NSTextField(labelWithString: "Click the button, then press your desired key combo.")
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.frame = NSRect(x: 20, y: 260, width: 320, height: 16)
        contentView.addSubview(statusLabel)
        
        let divider1 = NSBox(frame: NSRect(x: 20, y: 240, width: 320, height: 1))
        divider1.boxType = .separator
        contentView.addSubview(divider1)
        
        // Selection mode section
        let modeTitle = NSTextField(labelWithString: "Selection mode")
        modeTitle.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        modeTitle.frame = NSRect(x: 20, y: 205, width: 320, height: 20)
        contentView.addSubview(modeTitle)
        
        modePopup = NSPopUpButton(frame: NSRect(x: 20, y: 165, width: 320, height: 28))
        modePopup.addItems(withTitles: SelectionMode.allCases.map { $0.rawValue })
        modePopup.selectItem(withTitle: Preferences.shared.selectionMode.rawValue)
        modePopup.target = self
        modePopup.action = #selector(modeChanged)
        contentView.addSubview(modePopup)
        
        let divider2 = NSBox(frame: NSRect(x: 20, y: 145, width: 320, height: 1))
        divider2.boxType = .separator
        contentView.addSubview(divider2)
        
        // Engine section
        let engineTitle = NSTextField(labelWithString: "Search engine")
        engineTitle.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        engineTitle.frame = NSRect(x: 20, y: 110, width: 320, height: 20)
        contentView.addSubview(engineTitle)
        
        enginePopup = NSPopUpButton(frame: NSRect(x: 20, y: 70, width: 320, height: 28))
        enginePopup.addItems(withTitles: SearchEngine.allCases.map { $0.rawValue })
        enginePopup.selectItem(withTitle: Preferences.shared.searchEngine.rawValue)
        enginePopup.target = self
        enginePopup.action = #selector(engineChanged)
        contentView.addSubview(enginePopup)
        
        // Buttons
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked))
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1B}"
        cancelButton.frame = NSRect(x: 170, y: 20, width: 80, height: 32)
        contentView.addSubview(cancelButton)
        
        let applyButton = NSButton(title: "Apply", target: self, action: #selector(applyClicked))
        applyButton.bezelStyle = .rounded
        applyButton.keyEquivalent = "\r"
        applyButton.frame = NSRect(x: 260, y: 20, width: 80, height: 32)
        contentView.addSubview(applyButton)
    }
    
    @objc private func toggleRecording() {
        if isRecording { stopRecording() } else { startRecording() }
    }
    
    private func startRecording() {
        isRecording = true
        HotkeyManager.shared.isPaused = true
        shortcutButton.title = "Press a key combination..."
        statusLabel.stringValue = "Press any key with at least one modifier (⌘ ⌃ ⌥ ⇧)"
        
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil
        }
    }
    
    private func stopRecording() {
        isRecording = false
        HotkeyManager.shared.isPaused = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        shortcutButton.title = pendingShortcutString()
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        let modifiers = event.modifierFlags
        var cgFlags: UInt64 = 0
        if modifiers.contains(.command)   { cgFlags |= CGEventFlags.maskCommand.rawValue }
        if modifiers.contains(.control)   { cgFlags |= CGEventFlags.maskControl.rawValue }
        if modifiers.contains(.option)    { cgFlags |= CGEventFlags.maskAlternate.rawValue }
        if modifiers.contains(.shift)     { cgFlags |= CGEventFlags.maskShift.rawValue }
        
        guard cgFlags != 0 else {
            statusLabel.stringValue = "Need at least one modifier key (⌘ ⌃ ⌥ ⇧)"
            return
        }
        
        pendingKeyCode = Int(event.keyCode)
        pendingModifiers = cgFlags
        statusLabel.stringValue = "Pending — click Apply to save"
        stopRecording()
    }
    
    @objc private func engineChanged() {
        guard let title = enginePopup.titleOfSelectedItem,
              let engine = SearchEngine.allCases.first(where: { $0.rawValue == title }) else { return }
        pendingEngine = engine
        statusLabel.stringValue = "Pending — click Apply to save"
    }
    
    @objc private func modeChanged() {
        guard let title = modePopup.titleOfSelectedItem,
              let mode = SelectionMode.allCases.first(where: { $0.rawValue == title }) else { return }
        pendingMode = mode
        statusLabel.stringValue = "Pending — click Apply to save"
    }
    
    @objc private func applyClicked() {
        Preferences.shared.keyCode = pendingKeyCode
        Preferences.shared.modifiers = pendingModifiers
        Preferences.shared.searchEngine = pendingEngine
        Preferences.shared.selectionMode = pendingMode
        print("Preferences applied")
        window?.close()
    }
    
    @objc private func cancelClicked() {
        if isRecording { stopRecording() }
        window?.close()
    }
    
    private func pendingShortcutString() -> String {
        var parts: [String] = []
        let flags = CGEventFlags(rawValue: pendingModifiers)
        if flags.contains(.maskControl) { parts.append("⌃") }
        if flags.contains(.maskAlternate) { parts.append("⌥") }
        if flags.contains(.maskShift) { parts.append("⇧") }
        if flags.contains(.maskCommand) { parts.append("⌘") }
        parts.append(keyCodeToString(pendingKeyCode))
        return parts.joined()
    }
    
    private func keyCodeToString(_ code: Int) -> String {
        let map: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
            38: "J", 40: "K", 45: "N", 46: "M",
            18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
            25: "9", 26: "7", 28: "8", 29: "0",
            49: "Space"
        ]
        return map[code] ?? "?"
    }
    
    func showWindow() {
        pendingKeyCode = Preferences.shared.keyCode
        pendingModifiers = Preferences.shared.modifiers
        pendingEngine = Preferences.shared.searchEngine
        pendingMode = Preferences.shared.selectionMode
        
        shortcutButton.title = Preferences.shared.shortcutString
        enginePopup.selectItem(withTitle: Preferences.shared.searchEngine.rawValue)
        modePopup.selectItem(withTitle: Preferences.shared.selectionMode.rawValue)
        statusLabel.stringValue = "Click the button, then press your desired key combo."
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}