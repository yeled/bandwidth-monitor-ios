import Foundation

enum APIError: Error, LocalizedError {
    case invalidBaseURL
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Set a valid server URL in Settings, e.g. http://192.168.1.1:8080"
        case .badStatus(let code):
            return "Server returned status \(code)"
        }
    }
}

/// Talks to a bandwidth-monitor instance (github.com/awlx/bandwidth-monitor).
/// See its README's "API Endpoints" section for the full surface; this client
/// only uses the two traffic endpoints needed for the live/1h/24h graphs.
struct APIClient {
    var baseURL: URL

    init?(baseURLString: String) {
        var s = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if !s.contains("://") { s = "http://" + s }
        guard let url = URL(string: s) else { return nil }
        self.baseURL = url
    }

    func fetchInterfaces() async throws -> [InterfaceStat] {
        try await get([InterfaceStat].self, path: "/api/interfaces")
    }

    func fetchHistory() async throws -> InterfaceHistory {
        try await get(InterfaceHistory.self, path: "/api/interfaces/history")
    }

    private func get<T: Decodable>(_ type: T.Type, path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.badStatus(http.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
