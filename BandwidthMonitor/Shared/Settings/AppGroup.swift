import Foundation

/// Backs the settings the widget extension needs to read without the host app running.
enum AppGroup {
    static let id = "group.com.evilforbeginners.BandwidthMonitor"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: id) ?? .standard
    }
}

enum SettingsKey {
    static let serverURL = "serverURL"
    static let selectedInterface = "selectedInterface"
    static let widgetSnapshot = "widgetSnapshot"
    static let liveActivityPushToken = "liveActivityPushToken"
}

extension AppGroup {
    static func saveWidgetSnapshot(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: SettingsKey.widgetSnapshot)
    }

    static func loadWidgetSnapshot() -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: SettingsKey.widgetSnapshot) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}

enum TrafficWidgetKind {
    static let id = "TrafficWidget"
}
