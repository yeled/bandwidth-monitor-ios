import Foundation

enum ByteFormatter {
    static func rate(_ bytesPerSecond: Double) -> String {
        let formatted = bytes(bytesPerSecond)
        return "\(formatted)/s"
    }

    static func bytes(_ value: Double) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = value
        var unitIndex = 0
        while value >= 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        return String(format: "%.1f %@", value, units[unitIndex])
    }
}
