import SwiftUI

struct InterfaceRowView: View {
    let stat: InterfaceStat

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(stat.name)
                    .font(.headline)
                if stat.wan == true {
                    Text("WAN")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(Color.blue)
                        .clipShape(Capsule())
                }
                Spacer()
                Text(stat.operState)
                    .font(.caption)
                    .foregroundStyle(stat.operState.lowercased() == "up" ? .green : .secondary)
            }
            HStack(spacing: 16) {
                rateLabel(systemImage: "arrow.down", value: stat.rxRate, color: .blue)
                rateLabel(systemImage: "arrow.up", value: stat.txRate, color: .orange)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func rateLabel(systemImage: String, value: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
            Text(ByteFormatter.rate(value))
        }
    }
}

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
