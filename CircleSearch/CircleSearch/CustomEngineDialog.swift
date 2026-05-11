import Cocoa

class CustomEngineDialog: NSWindowController {
    
    var onSave: ((CustomEngine) -> Void)?
    
    private var nameField: NSTextField!
    private var urlField: NSTextField!
    private var errorLabel: NSTextField!
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 240),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Add Custom Search Engine"
        window.center()
        
        self.init(window: window)
        setupUI()
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        let nameLabel = NSTextField(labelWithString: "Name")
        nameLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        nameLabel.frame = NSRect(x: 20, y: 200, width: 380, height: 18)
        contentView.addSubview(nameLabel)
        
        nameField = NSTextField(frame: NSRect(x: 20, y: 170, width: 380, height: 24))
        nameField.placeholderString = "TinEye"
        nameField.isEditable = true
        nameField.isSelectable = true
        nameField.allowsEditingTextAttributes = false
        nameField.usesSingleLineMode = true
        contentView.addSubview(nameField)
        
        let urlLabel = NSTextField(labelWithString: "URL template")
        urlLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        urlLabel.frame = NSRect(x: 20, y: 135, width: 380, height: 18)
        contentView.addSubview(urlLabel)
        
        urlField = NSTextField(frame: NSRect(x: 20, y: 105, width: 380, height: 24))
        urlField.placeholderString = "https://www.tineye.com/search?url={url}"
        urlField.isEditable = true
        urlField.isSelectable = true
        urlField.allowsEditingTextAttributes = false
        urlField.usesSingleLineMode = true
        contentView.addSubview(urlField)
        
        let hint = NSTextField(labelWithString: "Use {url} where the image URL should appear.")
        hint.font = NSFont.systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        hint.frame = NSRect(x: 20, y: 80, width: 380, height: 16)
        contentView.addSubview(hint)
        
        errorLabel = NSTextField(labelWithString: "")
        errorLabel.font = NSFont.systemFont(ofSize: 11)
        errorLabel.textColor = .systemRed
        errorLabel.frame = NSRect(x: 20, y: 60, width: 380, height: 16)
        contentView.addSubview(errorLabel)
        
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked))
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1B}"
        cancelButton.frame = NSRect(x: 230, y: 20, width: 80, height: 32)
        contentView.addSubview(cancelButton)
        
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveClicked))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        saveButton.frame = NSRect(x: 320, y: 20, width: 80, height: 32)
        contentView.addSubview(saveButton)
    }
    
    @objc private func saveClicked() {
        let name = nameField.stringValue.trimmingCharacters(in: .whitespaces)
        let template = urlField.stringValue.trimmingCharacters(in: .whitespaces)
        
        guard !name.isEmpty else {
            errorLabel.stringValue = "Please enter a name."
            return
        }
        guard !template.isEmpty else {
            errorLabel.stringValue = "Please enter a URL template."
            return
        }
        guard template.contains("{url}") else {
            errorLabel.stringValue = "URL template must contain {url}."
            return
        }
        guard template.hasPrefix("https://") || template.hasPrefix("http://") else {
            errorLabel.stringValue = "URL must start with http:// or https://"
            return
        }
        
        let engine = CustomEngine(id: UUID().uuidString, name: name, urlTemplate: template)
        onSave?(engine)
        window?.close()
    }
    
    @objc private func cancelClicked() {
        window?.close()
    }
    
    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}