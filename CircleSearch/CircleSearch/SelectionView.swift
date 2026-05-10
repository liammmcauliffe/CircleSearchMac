import Cocoa

class SelectionView: NSView {
    
    // Lasso state
    private var points: [NSPoint] = []
    
    // Rectangle state
    private var startPoint: NSPoint?
    private var currentRect: NSRect?
    
    // Phase state
    private var isDrawing = false
    private var isConfirming = false
    private var capturedRect: NSRect?
    private var confirmTask: Task<Void, Never>?
    
    private var mode: SelectionMode { Preferences.shared.selectionMode }
    
    override func mouseDown(with event: NSEvent) {
        // Ignore clicks during the confirmation phase
        if isConfirming { return }
        
        let point = convert(event.locationInWindow, from: nil)
        
        switch mode {
        case .lasso:
            points = [point]
        case .rectangle:
            startPoint = point
            currentRect = nil
        }
        
        isDrawing = true
        needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isDrawing else { return }
        let point = convert(event.locationInWindow, from: nil)
        
        switch mode {
        case .lasso:
            points.append(point)
        case .rectangle:
            guard let start = startPoint else { return }
            currentRect = NSRect(
                x: min(start.x, point.x),
                y: min(start.y, point.y),
                width: abs(point.x - start.x),
                height: abs(point.y - start.y)
            )
        }
        
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        // If we're not drawing (e.g. user pressed Escape mid-draw), do nothing
        guard isDrawing else { return }
        isDrawing = false
        
        // Compute the bounding box for the chosen mode
        var rect: NSRect = .zero
        switch mode {
        case .lasso:
            guard points.count > 5 else {
                OverlayWindow.shared.hide()
                return
            }
            rect = boundingBox(of: points)
        case .rectangle:
            guard let r = currentRect else {
                OverlayWindow.shared.hide()
                return
            }
            rect = r
        }
        
        // Reject tiny accidental selections
        guard rect.width > 10, rect.height > 10 else {
            OverlayWindow.shared.hide()
            return
        }
        
        let screen = self.window?.screen ?? NSScreen.main!
        
        if mode == .rectangle {
            // Rectangle mode: capture immediately, no preview needed
            proceedWithCapture(rect: rect, on: screen)
        } else {
            // Lasso mode: show bounding box preview, then capture
            capturedRect = rect
            isConfirming = true
            needsDisplay = true
            
            confirmTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 700_000_000)
                if Task.isCancelled { return }
                await MainActor.run {
                    self?.proceedWithCapture(rect: rect, on: screen)
                }
            }
        }
    }
    
    private func proceedWithCapture(rect: NSRect, on screen: NSScreen) {
        OverlayWindow.shared.hide()
        
        Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            
            guard let image = await ScreenCapture.capture(rect: rect, on: screen) else { return }
            
            if let imageURL = await ImageUploader.upload(image) {
                SearchLauncher.search(imageURL: imageURL)
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Build the cutout shape (or nil if there's nothing to cut yet)
        let cutout: NSBezierPath? = makeCutoutPath()
        
        // Paint the dim layer everywhere EXCEPT inside the cutout
        let dimPath = NSBezierPath(rect: bounds)
        if let hole = cutout {
            dimPath.append(hole)
            dimPath.windingRule = .evenOdd
        }
        NSColor.black.withAlphaComponent(0.4).setFill()
        dimPath.fill()
        
        // Confirmation phase: draw corner brackets around the bounding box (lasso only)
        if isConfirming, let rect = capturedRect {
            if mode == .lasso {
                drawCornerBrackets(for: rect)
            }
            return
        }
        
        // Active drawing — draw the outline on top of the cutout
        switch mode {
        case .lasso: drawLassoStroke()
        case .rectangle: drawRectangleStroke()
        }
    }
    
    private func makeCutoutPath() -> NSBezierPath? {
        if isConfirming, let rect = capturedRect, mode == .lasso {
            return NSBezierPath(rect: rect)
        }
        
        switch mode {
        case .lasso:
            guard points.count > 2 else { return nil }
            let path = NSBezierPath()
            path.move(to: points[0])
            for i in 1..<points.count {
                path.line(to: points[i])
            }
            path.close()
            return path
        case .rectangle:
            guard let rect = currentRect else { return nil }
            return NSBezierPath(rect: rect)
        }
    }
    
    private func drawLassoStroke() {
        guard points.count > 1 else { return }
        
        let path = NSBezierPath()
        path.move(to: points[0])
        for i in 1..<points.count {
            path.line(to: points[i])
        }
        if !isDrawing { path.close() }
        
        NSColor.white.setStroke()
        path.lineWidth = 2.5
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
        path.stroke()
    }
    
    private func drawRectangleStroke() {
        guard let rect = currentRect else { return }
        drawCornerBrackets(for: rect)
    }
    
    private func drawCornerBrackets(for rect: NSRect) {
        let bracketLength: CGFloat = min(rect.width, rect.height) * 0.15
        let clampedLength = max(12, min(bracketLength, 30))  // 12px min, 30px max
        let lineWidth: CGFloat = 4
        let cornerRadius: CGFloat = 6
        
        NSColor.white.setStroke()
        
        let path = NSBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        
        // Top-left corner
        path.move(to: NSPoint(x: rect.minX, y: rect.maxY - clampedLength))
        path.line(to: NSPoint(x: rect.minX, y: rect.maxY - cornerRadius))
        path.appendArc(
            withCenter: NSPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: 180,
            endAngle: 90,
            clockwise: true
        )
        path.line(to: NSPoint(x: rect.minX + clampedLength, y: rect.maxY))
        
        // Top-right corner
        path.move(to: NSPoint(x: rect.maxX - clampedLength, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX - cornerRadius, y: rect.maxY))
        path.appendArc(
            withCenter: NSPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: 90,
            endAngle: 0,
            clockwise: true
        )
        path.line(to: NSPoint(x: rect.maxX, y: rect.maxY - clampedLength))
        
        // Bottom-right corner
        path.move(to: NSPoint(x: rect.maxX, y: rect.minY + clampedLength))
        path.line(to: NSPoint(x: rect.maxX, y: rect.minY + cornerRadius))
        path.appendArc(
            withCenter: NSPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: 0,
            endAngle: -90,
            clockwise: true
        )
        path.line(to: NSPoint(x: rect.maxX - clampedLength, y: rect.minY))
        
        // Bottom-left corner
        path.move(to: NSPoint(x: rect.minX + clampedLength, y: rect.minY))
        path.line(to: NSPoint(x: rect.minX + cornerRadius, y: rect.minY))
        path.appendArc(
            withCenter: NSPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: -90,
            endAngle: -180,
            clockwise: true
        )
        path.line(to: NSPoint(x: rect.minX, y: rect.minY + clampedLength))
        
        path.stroke()
    }
    
    private func boundingBox(of points: [NSPoint]) -> NSRect {
        guard !points.isEmpty else { return .zero }
        var minX = points[0].x, maxX = points[0].x
        var minY = points[0].y, maxY = points[0].y
        for p in points {
            minX = min(minX, p.x); maxX = max(maxX, p.x)
            minY = min(minY, p.y); maxY = max(maxY, p.y)
        }
        return NSRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    func reset() {
        points = []
        startPoint = nil
        currentRect = nil
        capturedRect = nil
        isDrawing = false
        isConfirming = false
        confirmTask?.cancel()
        confirmTask = nil
        needsDisplay = true
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            // Cancel any pending capture and reset everything
            reset()
            OverlayWindow.shared.hide()
        }
    }
    
    override var acceptsFirstResponder: Bool { true }
}