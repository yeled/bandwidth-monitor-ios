import Foundation

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
final class TrafficViewModel: ObservableObject {
    @Published var interfaces: [InterfaceStat] = []
    @Published var history: InterfaceHistory = [:]
    @Published var selectedInterface: String?
    @Published var timeRange: TimeRange = .oneHour
    @Published var errorMessage: String?
    @Published var isLoading = false

    private var refreshTask: Task<Void, Never>?
    private let liveInterval: Duration = .seconds(2)
    private let historyRefreshEveryNTicks = 8 // ~every 16s, since live polls every 2s
    private var tickCount = 0

    /// Caps points handed to the chart so a 24h-at-1Hz series doesn't render tens of thousands of marks.
    private let maxChartPoints = 360

    func start(baseURLString: String) {
        stop()
        refreshTask = Task {
            await refreshLoop(baseURLString: baseURLString)
        }
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
                selectedInterface = interfaces.first(where: { $0.wan == true })?.name ?? interfaces.first?.name
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Points for the selected interface within the selected time range, downsampled for chart rendering.
    var chartPoints: [HistoryPoint] {
        guard let name = selectedInterface, let points = history[name] else { return [] }
        let cutoff = Date().addingTimeInterval(-timeRange.seconds)
        let windowed = points.filter { $0.date >= cutoff }
        guard windowed.count > maxChartPoints else { return windowed }

        let stride = Swift.max(1, windowed.count / maxChartPoints)
        return Swift.stride(from: 0, to: windowed.count, by: stride).map { windowed[$0] }
    }

    var selectedStat: InterfaceStat? {
        interfaces.first { $0.name == selectedInterface }
    }
}
