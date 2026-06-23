import Foundation

/// Mirrors `collector.HistoryPoint` from `/api/interfaces/history`.
/// The server keeps up to 24h of these per interface, sampled roughly once per second.
struct HistoryPoint: Decodable {
    let timestamp: Int64
    let rxRate: Double
    let txRate: Double

    enum CodingKeys: String, CodingKey {
        case timestamp = "t"
        case rxRate = "rx"
        case txRate = "tx"
    }

    var date: Date { Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000) }
}

/// `/api/interfaces/history` returns a map of interface name -> points.
typealias InterfaceHistory = [String: [HistoryPoint]]
