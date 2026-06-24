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
            Text(BitRateFormatter.string(fromBytesPerSecond: value))
        }
    }
}
