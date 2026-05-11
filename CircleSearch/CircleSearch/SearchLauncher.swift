import Cocoa

class SearchLauncher {
    static func search(imageURL: String) {
        let engine = Preferences.shared.searchEngine
        let urlString = engine.url(for: imageURL)
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
            print("Opened \(engine.displayName)")
        }
    }
}