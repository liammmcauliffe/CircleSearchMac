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
        self.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        self.isOpaque = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let selectionView = SelectionView(frame: screen)
        self.contentView = selectionView
    }
    
    // Allow this borderless window to become key (so it receives keyboard events)
    override var canBecomeKey: Bool { true }
    
    func show() {
        if let view = self.contentView as? SelectionView {
            view.reset()
        }
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Make the selection view the first responder so it gets key events
        if let view = self.contentView {
            self.makeFirstResponder(view)
        }
    }
    
    func hide() {
        self.orderOut(nil)
    }
}