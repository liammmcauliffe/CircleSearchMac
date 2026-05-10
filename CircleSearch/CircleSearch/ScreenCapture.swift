import Cocoa
import ScreenCaptureKit

class ScreenCapture {
    
    static func capture(rect: NSRect, on screen: NSScreen) async -> NSImage? {
        do {
            let content = try await SCShareableContent.current
            
            // Find the SCDisplay matching this NSScreen by display ID
            let screenID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
            
            guard let display = content.displays.first(where: { $0.displayID == screenID })
                            ?? content.displays.first else {
                print("No display found")
                return nil
            }
            
            let filter = SCContentFilter(display: display, excludingWindows: [])
            
            let config = SCStreamConfiguration()
            config.width = Int(display.width)
            config.height = Int(display.height)
            config.showsCursor = false
            
            let cgImage = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            
            // Compute true scale from captured pixels vs screen points
            // This handles all scaling modes (including fractional / "More Space" displays)
            let scaleX = CGFloat(cgImage.width) / screen.frame.width
            let scaleY = CGFloat(cgImage.height) / screen.frame.height
            let imageHeight = CGFloat(cgImage.height)
            
            // Convert view coords (points, bottom-left) → image coords (pixels, top-left)
            var cropRect = CGRect(
                x: rect.origin.x * scaleX,
                y: imageHeight - (rect.origin.y * scaleY) - (rect.height * scaleY),
                width: rect.width * scaleX,
                height: rect.height * scaleY
            )
            
            // Clamp to image bounds — prevents "Failed to crop" when rect rounds outside
            let imageBounds = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
            cropRect = cropRect.intersection(imageBounds)
            
            guard !cropRect.isNull, !cropRect.isEmpty else {
                print("Crop rect outside image bounds")
                return nil
            }
            
            guard let cropped = cgImage.cropping(to: cropRect) else {
                print("Failed to crop. Rect: \(cropRect), image: \(cgImage.width)×\(cgImage.height)")
                return nil
            }
            
            let outputSize = NSSize(width: cropRect.width / scaleX, height: cropRect.height / scaleY)
            return NSImage(cgImage: cropped, size: outputSize)
            
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