import Cocoa

class SearchLauncher {
    static func openGoogleLens(imageURL: String) {
        let encoded = imageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? imageURL
        let lensURL = "https://lens.google.com/uploadbyurl?url=\(encoded)"
        
        if let url = URL(string: lensURL) {
            NSWorkspace.shared.open(url)
        }
    }
}