import Cocoa

class ImageUploader {
    
    static func upload(_ image: NSImage) async -> String? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("Could not convert image")
            return nil
        }
        
        guard let url = URL(string: "https://catbox.moe/user/api.php") else { return nil }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // reqtype field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"reqtype\"\r\n\r\n".data(using: .utf8)!)
        body.append("fileupload\r\n".data(using: .utf8)!)
        
        // file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"fileToUpload\"; filename=\"capture.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(pngData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let urlString = String(data: data, encoding: .utf8),
               urlString.hasPrefix("https://") {
                let cleaned = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
                print("Uploaded: \(cleaned)")
                return cleaned
            } else {
                print("Unexpected response: \(String(data: data, encoding: .utf8) ?? "")")
                return nil
            }
        } catch {
            print("Upload failed: \(error)")
            return nil
        }
    }
}
