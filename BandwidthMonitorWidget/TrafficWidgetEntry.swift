import WidgetKit

struct TrafficWidgetEntry: TimelineEntry {
    let date: Date
    let interfaceName: String?
    let points: [HistoryPoint]
    let errorMessage: String?

    /// Peak rates within `points`, so the label above the sparkline can call out
    /// the window's high point rather than just whatever the latest sample happens to be.
    var peakRxRate: Double { points.map(\.rxRate).max() ?? 0 }
    var peakTxRate: Double { points.map(\.txRate).max() ?? 0 }
}
