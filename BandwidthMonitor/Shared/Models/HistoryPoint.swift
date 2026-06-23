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

extension Array where Element == HistoryPoint {
    /// Downsamples to roughly `maxPoints`, keeping the highest-rate point in each bucket
    /// instead of a fixed stride, so a brief spike between sampled indices isn't silently
    /// dropped from the chart.
    func downsampledPreservingPeaks(maxPoints: Int) -> [HistoryPoint] {
        guard maxPoints > 0, count > maxPoints else { return self }

        let bucketSize = Double(count) / Double(maxPoints)
        var result: [HistoryPoint] = []
        result.reserveCapacity(maxPoints)

        var bucketStart = 0
        for bucket in 0..<maxPoints {
            let bucketEnd = bucket == maxPoints - 1 ? count : Int((Double(bucket + 1) * bucketSize).rounded())
            guard bucketStart < bucketEnd else { continue }
            let peak = self[bucketStart..<bucketEnd].max { Swift.max($0.rxRate, $0.txRate) < Swift.max($1.rxRate, $1.txRate) }
            if let peak {
                result.append(peak)
            }
            bucketStart = bucketEnd
        }
        return result
    }
}
