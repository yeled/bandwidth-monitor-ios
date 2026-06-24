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
        let preferredInterface = defaults.string(forKey: SettingsKey.selectedInterface)

        // The host app caches a small slice of the selected interface's last hour every time it
        // refreshes. Prefer that — it's instant and avoids the widget extension making its own
        // network call against an endpoint that returns a multi-megabyte 24h history blob, which
        // risks running past the extension's execution budget.
        if let cached = AppGroup.loadWidgetSnapshot(),
           preferredInterface == nil || cached.interfaceName == preferredInterface {
            return TrafficWidgetEntry(date: Date(), interfaceName: cached.interfaceName, points: cached.points, errorMessage: nil)
        }

        guard let serverURL = defaults.string(forKey: SettingsKey.serverURL), !serverURL.isEmpty else {
            return TrafficWidgetEntry(date: Date(), interfaceName: nil, points: [], errorMessage: "No server configured")
        }
        guard let client = APIClient(baseURLString: serverURL, timeout: 8) else {
            return TrafficWidgetEntry(date: Date(), interfaceName: nil, points: [], errorMessage: "Invalid server URL")
        }

        do {
            let history = try await client.fetchHistory()
            let name = preferredInterface.flatMap { history[$0] != nil ? $0 : nil } ?? history.keys.sorted().first
            guard let name, let points = history[name] else {
                return TrafficWidgetEntry(date: Date(), interfaceName: name, points: [], errorMessage: "No data yet")
            }
            let cutoff = Date().addingTimeInterval(-chartWindow)
            let windowed = points.filter { $0.date >= cutoff }
            return TrafficWidgetEntry(date: Date(), interfaceName: name, points: windowed.downsampledPreservingPeaks(maxPoints: maxPoints), errorMessage: nil)
        } catch {
            return TrafficWidgetEntry(date: Date(), interfaceName: nil, points: [], errorMessage: error.localizedDescription)
        }
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
