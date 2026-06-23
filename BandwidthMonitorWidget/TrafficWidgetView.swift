import SwiftUI
import Charts
import WidgetKit

struct TrafficWidgetView: View {
    let entry: TrafficWidgetEntry

    var body: some View {
        if entry.points.isEmpty {
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.interfaceName ?? "Bandwidth")
                    .font(.caption2)
                    .lineLimit(1)
                Text(entry.errorMessage ?? "No data")
                    .font(.caption2)
                    .opacity(0.7)
                    .lineLimit(1)
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text(entry.interfaceName ?? "")
                    .font(.caption2)
                    .lineLimit(1)
                sparkline
            }
        }
    }

    /// RX plotted above the zero line, TX plotted below it — one line, no color, just direction.
    private var sparkline: some View {
        Chart {
            RuleMark(y: .value("Zero", 0))
                .lineStyle(StrokeStyle(lineWidth: 0.5))

            ForEach(entry.points, id: \.timestamp) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Down", point.rxRate)
                )
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .foregroundStyle(.primary)
            }

            ForEach(entry.points, id: \.timestamp) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Up", -point.txRate)
                )
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .foregroundStyle(.secondary)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .widgetAccentable()
    }
}
