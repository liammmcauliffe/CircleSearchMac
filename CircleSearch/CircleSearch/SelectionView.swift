import Cocoa

class SelectionView: NSView {
    
    private var startPoint: NSPoint?
    private var currentRect: NSRect?
    
    override func mouseDown(with event: NSEvent) {
    startPoint = convert(event.locationInWindow, from: nil)
    currentRect = nil
    needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)
        
        currentRect = NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        
        needsDisplay = true // triggers draw()
    }
    
    override func mouseUp(with event: NSEvent) {
        guard let rect = currentRect, rect.width > 5, rect.height > 5 else {
            OverlayWindow.shared.hide()
            return
        }
        
        OverlayWindow.shared.hide()
        
        Task {
            // Small delay so the overlay is fully hidden before capture
            try? await Task.sleep(nanoseconds: 150_000_000)
            
            if let image = await ScreenCapture.capture(rect: rect) {
                _ = ScreenCapture.saveToDesktop(image)
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw the selection rectangle
        if let rect = currentRect {
            NSColor.white.withAlphaComponent(0.3).setFill()
            NSBezierPath(rect: rect).fill()
            
            NSColor.white.setStroke()
            let path = NSBezierPath(rect: rect)
            path.lineWidth = 2
            path.stroke()
        }
    }
    
    // Press Escape to cancel
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            OverlayWindow.shared.hide()
        }
    }
    
    func reset() {
        startPoint = nil
        currentRect = nil
        needsDisplay = true
    }
    
    override var acceptsFirstResponder: Bool { true }
}