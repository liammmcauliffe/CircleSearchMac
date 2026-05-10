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
        
        // Fullscreen, transparent, on top of everything
        self.level = .screenSaver
        self.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        self.isOpaque = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Add the drawing view
        let selectionView = SelectionView(frame: screen)
        self.contentView = selectionView
    }
    
    func show() {
        if let view = self.contentView as? SelectionView {
            view.reset()
        }
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hide() {
        self.orderOut(nil)
    }
}