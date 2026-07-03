// LaunchAtLoginService.swift — start Hyperfocus at login via SMAppService (macOS 13+, canon #41).
// The setting (hf.launchAtLogin) is the intent; this reflects it into the real login-item registry.

import ServiceManagement

enum LaunchAtLoginService {
    /// True if the app is currently registered as a login item.
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    /// Register/unregister the main app. Errors are logged, not fatal (e.g. the user revoked it
    /// in System Settings → General → Login Items, which we must not fight).
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
            } else {
                if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            }
            return true
        } catch {
            NSLog("Hyperfocus: launch-at-login \(enabled ? "register" : "unregister") failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Reconcile the OS state with the saved preference at launch (the user may have toggled the
    /// login item in System Settings while the app was closed).
    static func syncToPreference(_ enabled: Bool) {
        if enabled != isEnabled { setEnabled(enabled) }
    }
}
