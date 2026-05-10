import Cocoa
import ScreenCaptureKit

class ScreenCapture {
    
    static func capture(rect: NSRect) async -> NSImage? {
        do {
            // Get the available content (displays, windows)
            let content = try await SCShareableContent.current
            
            guard let display = content.displays.first else {
                print("No display found")
                return nil
            }
            
            // Configure what to capture
            let filter = SCContentFilter(display: display, excludingWindows: [])
            
            let config = SCStreamConfiguration()
            config.width = Int(display.width)
            config.height = Int(display.height)
            config.showsCursor = false
            
            // Capture a single frame
            let cgImage = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            
            // Crop to the selected rect
            // Convert view coords (bottom-left) to image coords (top-left)
            let screenHeight = CGFloat(display.height)
            let cropRect = CGRect(
                x: rect.origin.x,
                y: screenHeight - rect.origin.y - rect.height,
                width: rect.width,
                height: rect.height
            )
            
            guard let cropped = cgImage.cropping(to: cropRect) else {
                print("Failed to crop image")
                return nil
            }
            
            return NSImage(cgImage: cropped, size: rect.size)
            
        } catch {
            print("Capture failed: \(error)")
            return nil
        }
    }
    
    static func saveToDesktop(_ image: NSImage, name: String = "circlesearch_capture.png") -> URL? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let url = desktop.appendingPathComponent(name)
        
        do {
            try pngData.write(to: url)
            print("Saved to: \(url.path)")
            return url
        } catch {
            print("Save failed: \(error)")
            return nil
        }
    }
}