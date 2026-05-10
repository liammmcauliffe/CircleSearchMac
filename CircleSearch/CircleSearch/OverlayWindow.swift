import Cocoa

class OverlayWindow: NSWindow {
    
    static let shared = OverlayWindow()
    
    private init() {
        let screen = NSScreen.main!.frame
        super.init(
            contentRect: screen,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        self.level = .screenSaver
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let selectionView = SelectionView(frame: screen)
        self.contentView = selectionView
    }
    
    // Allow this borderless window to become key (so it receives keyboard events)
    override var canBecomeKey: Bool { true }
    
    func show() {
        // Reposition to current main screen each time
        if let screen = NSScreen.main {
            self.setFrame(screen.frame, display: false)
            if let view = self.contentView as? SelectionView {
                view.frame = NSRect(origin: .zero, size: screen.frame.size)
                view.reset()
            }
        }
        
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        if let view = self.contentView {
            self.makeFirstResponder(view)
        }
    }
    
    func hide() {
        self.orderOut(nil)
    }
}