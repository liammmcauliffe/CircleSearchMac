import Cocoa

class Preferences {
    
    static let shared = Preferences()
    
    private let keyCodeKey = "hotkey.keyCode"
    private let modifiersKey = "hotkey.modifiers"
    
    // Default: Cmd + Control + S
    var keyCode: Int {
        get { UserDefaults.standard.object(forKey: keyCodeKey) as? Int ?? 1 } // 1 = S
        set { UserDefaults.standard.set(newValue, forKey: keyCodeKey) }
    }
    
    var modifiers: UInt64 {
        get { UserDefaults.standard.object(forKey: modifiersKey) as? UInt64 ?? (CGEventFlags.maskCommand.rawValue | CGEventFlags.maskControl.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: modifiersKey) }
    }
    
    // Human-readable shortcut for display
    var shortcutString: String {
        var parts: [String] = []
        let flags = CGEventFlags(rawValue: modifiers)
        if flags.contains(.maskControl) { parts.append("⌃") }
        if flags.contains(.maskAlternate) { parts.append("⌥") }
        if flags.contains(.maskShift) { parts.append("⇧") }
        if flags.contains(.maskCommand) { parts.append("⌘") }
        parts.append(keyCodeToString(keyCode))
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
}