import WidgetKit

struct TrafficWidgetEntry: TimelineEntry {
    let date: Date
    let interfaceName: String?
    let points: [HistoryPoint]
    let errorMessage: String?
}
