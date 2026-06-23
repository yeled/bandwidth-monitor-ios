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
}

enum TrafficWidgetKind {
    static let id = "TrafficWidget"
}
