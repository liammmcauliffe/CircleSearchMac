import Cocoa

enum SelectionMode: String, CaseIterable {
    case lasso = "Lasso (freeform)"
    case rectangle = "Rectangle"
}

enum SearchEngine: String, CaseIterable {
    case googleLens = "Google Lens"
    case yandex = "Yandex"
    case bing = "Bing Visual Search"
    
    func url(for imageURL: String) -> String {
        let encoded = imageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? imageURL
        switch self {
        case .googleLens:
            return "https://lens.google.com/uploadbyurl?url=\(encoded)"
        case .yandex:
            return "https://yandex.com/images/search?rpt=imageview&url=\(encoded)"
        case .bing:
            return "https://www.bing.com/images/search?view=detailv2&iss=sbi&form=SBIVSP&sbisrc=UrlPaste&q=imgurl:\(encoded)"
        }
    }
}

class Preferences {
    
    static let shared = Preferences()
    
    private let keyCodeKey = "hotkey.keyCode"
    private let modifiersKey = "hotkey.modifiers"
    private let engineKey = "search.engine"
    private let selectionModeKey = "selection.mode"
    
    // Default: Cmd + Control + S
    var keyCode: Int {
        get { UserDefaults.standard.object(forKey: keyCodeKey) as? Int ?? 1 } // 1 = S
        set { UserDefaults.standard.set(newValue, forKey: keyCodeKey) }
    }
    
    var modifiers: UInt64 {
        get { UserDefaults.standard.object(forKey: modifiersKey) as? UInt64 ?? (CGEventFlags.maskCommand.rawValue | CGEventFlags.maskControl.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: modifiersKey) }
    }
    
    var searchEngine: SearchEngine {
        get {
            let raw = UserDefaults.standard.string(forKey: engineKey) ?? SearchEngine.googleLens.rawValue
            return SearchEngine(rawValue: raw) ?? .googleLens
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: engineKey)
        }
    }
    
    var selectionMode: SelectionMode {
        get {
            let raw = UserDefaults.standard.string(forKey: selectionModeKey) ?? SelectionMode.lasso.rawValue
            return SelectionMode(rawValue: raw) ?? .lasso
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: selectionModeKey) }
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