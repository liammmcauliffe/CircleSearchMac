import Cocoa
import ServiceManagement

class LaunchAtLogin {
    
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled {
                    print("Launch at login already enabled")
                    return
                }
                try SMAppService.mainApp.register()
                print("Launch at login enabled")
            } else {
                try SMAppService.mainApp.unregister()
                print("Launch at login disabled")
            }
        } catch {
            print("Launch at login error: \(error)")
        }
    }
}