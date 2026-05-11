import Cocoa

class ImageUploader {
    
    static func upload(_ image: NSImage) async -> String? {
        var rect = NSRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
            print("Could not get CGImage")
            return nil
        }
        
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("Could not encode PNG")
            return nil
        }
        
        guard let url = URL(string: "https://uguu.se/upload") else { return nil }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("CircleSearch/1.0", forHTTPHeaderField: "User-Agent")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files[]\"; filename=\"capture.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(pngData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let files = json["files"] as? [[String: Any]],
               let firstURL = files.first?["url"] as? String {
                print("Uploaded: \(firstURL)")
                return firstURL
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
