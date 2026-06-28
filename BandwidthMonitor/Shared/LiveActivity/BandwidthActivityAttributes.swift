import ActivityKit
import Foundation

/// Drives the Lock Screen / Dynamic Island Live Activity. Shared between the app (which starts and
/// updates the activity) and the widget extension (which renders it).
struct BandwidthActivityAttributes: ActivityAttributes {
    /// The bits that change over the life of the activity — kept small, since ActivityKit caps the
    /// content-state size (especially for push updates).
    struct ContentState: Codable, Hashable {
        var interfaceName: String
        var rxRate: Double  // bytes/sec, latest sample
        var txRate: Double
        /// Recent window for the sparkline, oldest → newest; the last element is "now".
        var points: [HistoryPoint]
        /// Epoch seconds. A plain number (not Date) so the push sender can build the content-state
        /// JSON without worrying about ActivityKit's date-decoding strategy.
        var updatedAt: Double
    }

    /// Static for the activity's lifetime.
    var title: String
}
