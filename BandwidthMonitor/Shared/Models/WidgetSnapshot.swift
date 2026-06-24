import Foundation

/// A small, pre-downsampled slice the host app writes into the App Group whenever it has fresh
/// history, so the widget extension can render instantly without making its own network call —
/// fetching the full multi-day history blob itself risks the widget's tight execution budget.
struct WidgetSnapshot: Codable {
    let interfaceName: String
    let points: [HistoryPoint]
    let cachedAt: Date
}
