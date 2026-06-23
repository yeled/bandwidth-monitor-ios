import WidgetKit

struct TrafficWidgetProvider: TimelineProvider {
    private let chartWindow: TimeInterval = 60 * 60
    private let maxPoints = 60
    private let refreshInterval: TimeInterval = 15 * 60

    func placeholder(in context: Context) -> TrafficWidgetEntry {
        TrafficWidgetEntry(date: Date(), interfaceName: "eth0", points: Self.samplePoints(), errorMessage: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TrafficWidgetEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task {
            completion(await currentEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TrafficWidgetEntry>) -> Void) {
        Task {
            let entry = await currentEntry()
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(refreshInterval)))
            completion(timeline)
        }
    }

    private func currentEntry() async -> TrafficWidgetEntry {
        let defaults = AppGroup.defaults
        guard let serverURL = defaults.string(forKey: SettingsKey.serverURL), !serverURL.isEmpty else {
            return TrafficWidgetEntry(date: Date(), interfaceName: nil, points: [], errorMessage: "No server configured")
        }
        guard let client = APIClient(baseURLString: serverURL) else {
            return TrafficWidgetEntry(date: Date(), interfaceName: nil, points: [], errorMessage: "Invalid server URL")
        }

        do {
            let history = try await client.fetchHistory()
            let preferred = defaults.string(forKey: SettingsKey.selectedInterface)
            let name = preferred.flatMap { history[$0] != nil ? $0 : nil } ?? history.keys.sorted().first
            guard let name, let points = history[name] else {
                return TrafficWidgetEntry(date: Date(), interfaceName: name, points: [], errorMessage: "No data yet")
            }
            let cutoff = Date().addingTimeInterval(-chartWindow)
            let windowed = points.filter { $0.date >= cutoff }
            return TrafficWidgetEntry(date: Date(), interfaceName: name, points: Self.downsample(windowed, maxPoints: maxPoints), errorMessage: nil)
        } catch {
            return TrafficWidgetEntry(date: Date(), interfaceName: nil, points: [], errorMessage: error.localizedDescription)
        }
    }

    private static func downsample(_ points: [HistoryPoint], maxPoints: Int) -> [HistoryPoint] {
        guard points.count > maxPoints else { return points }
        let stride = Swift.max(1, points.count / maxPoints)
        return Swift.stride(from: 0, to: points.count, by: stride).map { points[$0] }
    }

    private static func samplePoints() -> [HistoryPoint] {
        let now = Date().timeIntervalSince1970
        return (0..<30).map { i in
            let t = now - Double(30 - i) * 60
            let rx = 200_000 + 150_000 * sin(Double(i) / 4)
            let tx = 50_000 + 30_000 * cos(Double(i) / 5)
            return HistoryPoint(timestamp: Int64(t * 1000), rxRate: max(0, rx), txRate: max(0, tx))
        }
    }
}
