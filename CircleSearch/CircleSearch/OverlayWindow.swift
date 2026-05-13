import Cocoa

func cursorScreen() -> NSScreen {
    let loc = NSEvent.mouseLocation
    return NSScreen.screens.first(where: { NSPointInRect(loc, $0.frame) })
        ?? NSScreen.main
        ?? NSScreen.screens[0]
}

class OverlayWindow: NSWindow {

    static let shared = OverlayWindow()

    private var didPushCursor = false

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
        // Position on the screen the cursor is on (handles multi-monitor)
        let screen = cursorScreen()
        self.setFrame(screen.frame, display: false)
        if let view = self.contentView as? SelectionView {
            view.frame = NSRect(origin: .zero, size: screen.frame.size)
            view.reset()
        }

        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        if let view = self.contentView {
            self.makeFirstResponder(view)
        }

        if !didPushCursor {
            NSCursor.crosshair.push()
            didPushCursor = true
        }
    }

    func hide() {
        if didPushCursor {
            NSCursor.pop()
            didPushCursor = false
        }
        self.orderOut(nil)
    }
}

class LoadingIndicatorWindow: NSWindow {

    static let shared = LoadingIndicatorWindow()

    private var progressIndicator: NSProgressIndicator!

    private init() {
        let size = NSSize(width: 180, height: 60)
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let visualEffect = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true

        progressIndicator = NSProgressIndicator(frame: NSRect(x: 16, y: 20, width: 20, height: 20))
        progressIndicator.style = .spinning
        progressIndicator.controlSize = .small
        progressIndicator.isIndeterminate = true
        visualEffect.addSubview(progressIndicator)

        let label = NSTextField(labelWithString: "Searching…")
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .labelColor
        label.frame = NSRect(x: 46, y: 19, width: 120, height: 18)
        visualEffect.addSubview(label)

        self.contentView = visualEffect
    }

    func show(on screen: NSScreen) {
        let frame = screen.frame
        let size = self.frame.size
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.midY - size.height / 2
        )
        self.setFrameOrigin(origin)
        progressIndicator.startAnimation(nil)
        self.orderFront(nil)
    }

    func hide() {
        progressIndicator.stopAnimation(nil)
        self.orderOut(nil)
    }
}
