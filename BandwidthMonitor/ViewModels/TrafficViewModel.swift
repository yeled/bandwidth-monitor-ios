import Foundation
import Observation
import WidgetKit

enum TimeRange: String, CaseIterable, Identifiable {
    case oneHour = "1H"
    case twentyFourHours = "24H"

    var id: String { rawValue }

    var seconds: TimeInterval {
        switch self {
        case .oneHour: return 60 * 60
        case .twentyFourHours: return 24 * 60 * 60
        }
    }
}

@MainActor
@Observable
final class TrafficViewModel {
    var interfaces: [InterfaceStat] = []
    var history: InterfaceHistory = [:]
    var selectedInterface: String? {
        didSet {
            guard selectedInterface != oldValue else { return }
            AppGroup.defaults.set(selectedInterface, forKey: SettingsKey.selectedInterface)
            cacheWidgetSnapshot()
            WidgetCenter.shared.reloadTimelines(ofKind: TrafficWidgetKind.id)
        }
    }
    var timeRange: TimeRange = .oneHour
    var errorMessage: String?
    var isLoading = false

    /// True while the history on screen may be stale and a fresh full load is in flight (just after
    /// launch or returning to foreground). Lets the chart show it's reconciling rather than
    /// silently swapping the last hour out from under you.
    var isReconcilingHistory = false

    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    private let liveInterval: Duration = .seconds(2)
    private let historyRefreshEveryNTicks = 8 // ~every 16s, since live polls every 2s
    @ObservationIgnored private var tickCount = 0

    /// Caps points handed to the chart so a 24h-at-1Hz series doesn't render tens of thousands of marks.
    private let maxChartPoints = 360

    private let widgetSnapshotWindow: TimeInterval = 60 * 60
    private let widgetSnapshotMaxPoints = 60

    func start(baseURLString: String) {
        stop()
        beginReconcile()
        refreshTask = Task {
            await refreshLoop(baseURLString: baseURLString)
        }
    }

    /// Flag the on-screen history as stale-pending-refresh — but only if there's actually data
    /// showing. A cold launch has none and shows the empty state instead, which needs no redaction.
    /// Call when (re)starting or returning to the foreground; cleared by the next history load.
    func beginReconcile() {
        isReconcilingHistory = !history.isEmpty
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// One-shot refresh for pull-to-refresh; the polling loop continues independently.
    func refreshNow(baseURLString: String) async {
        guard let client = APIClient(baseURLString: baseURLString) else {
            errorMessage = APIError.invalidBaseURL.localizedDescription
            return
        }
        await refreshLive(client: client)
        await refreshHistory(client: client)
    }

    private func refreshLoop(baseURLString: String) async {
        guard let client = APIClient(baseURLString: baseURLString) else {
            errorMessage = APIError.invalidBaseURL.localizedDescription
            return
        }
        while !Task.isCancelled {
            await refreshLive(client: client)
            if tickCount % historyRefreshEveryNTicks == 0 {
                await refreshHistory(client: client)
            }
            tickCount += 1
            try? await Task.sleep(for: liveInterval)
        }
    }

    private func refreshLive(client: APIClient) async {
        isLoading = interfaces.isEmpty
        defer { isLoading = false }
        do {
            let stats = try await client.fetchInterfaces()
            interfaces = stats.sorted { $0.name < $1.name }
            if selectedInterface == nil {
                let saved = AppGroup.defaults.string(forKey: SettingsKey.selectedInterface)
                let savedStillPresent = saved.flatMap { name in interfaces.contains { $0.name == name } ? name : nil }
                selectedInterface = savedStillPresent
                    ?? interfaces.first(where: { $0.wan == true })?.name
                    ?? interfaces.first?.name
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshHistory(client: APIClient) async {
        do {
            history = try await client.fetchHistory()
            errorMessage = nil
            isReconcilingHistory = false
            cacheWidgetSnapshot()
            WidgetCenter.shared.reloadTimelines(ofKind: TrafficWidgetKind.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Writes a small, already-downsampled slice of the selected interface's last hour into the
    /// App Group so the widget can render without making its own (budget-constrained) network call.
    private func cacheWidgetSnapshot() {
        guard let name = selectedInterface, let points = history[name] else { return }
        let cutoff = Date().addingTimeInterval(-widgetSnapshotWindow)
        let windowed = points.filter { $0.date >= cutoff }
        let downsampled = windowed.downsampledPreservingPeaks(maxPoints: widgetSnapshotMaxPoints)
        AppGroup.saveWidgetSnapshot(WidgetSnapshot(interfaceName: name, points: downsampled, cachedAt: Date()))
    }

    /// Points for the selected interface within the selected time range, downsampled for chart rendering.
    var chartPoints: [HistoryPoint] {
        guard let name = selectedInterface, let points = history[name] else { return [] }
        let cutoff = Date().addingTimeInterval(-timeRange.seconds)
        let windowed = points.filter { $0.date >= cutoff }
        return windowed.downsampledPreservingPeaks(maxPoints: maxChartPoints)
    }

    var selectedStat: InterfaceStat? {
        interfaces.first { $0.name == selectedInterface }
    }
}
