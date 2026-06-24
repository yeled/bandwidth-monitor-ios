import Foundation

/// The server reports rates in bytes/sec, but network engineers think in decimal (SI) bits/sec —
/// kbps/Mbps/Gbps as powers of 1000, not the binary KB/MB/GB-style powers of 1024.
enum BitRateFormatter {
    static func string(fromBytesPerSecond bytesPerSecond: Double) -> String {
        let units = ["bps", "kbps", "Mbps", "Gbps", "Tbps"]
        var value = bytesPerSecond * 8
        var unitIndex = 0
        while value >= 1000, unitIndex < units.count - 1 {
            value /= 1000
            unitIndex += 1
        }
        return String(format: "%.1f %@", value, units[unitIndex])
    }

    /// For chart axes, which want a fixed unit (Mbps) rather than one that adapts per value.
    static func mbps(fromBytesPerSecond bytesPerSecond: Double) -> Double {
        bytesPerSecond * 8 / 1_000_000
    }
}
