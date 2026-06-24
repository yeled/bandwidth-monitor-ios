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
            VStack(alignment: .leading, spacing: 1) {
                header
                sparkline
            }
        }
    }

    /// Peak rates for the window, similar to a stock widget's change line above its sparkline —
    /// the squiggle alone is too small to make a spike's actual size legible at a glance.
    private var header: some View {
        HStack(spacing: 6) {
            Text(entry.interfaceName ?? "")
                .lineLimit(1)
            Spacer(minLength: 0)
            Text("↓\(BitRateFormatter.string(fromBytesPerSecond: entry.peakRxRate))")
            Text("↑\(BitRateFormatter.string(fromBytesPerSecond: entry.peakTxRate))")
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 11, weight: .medium))
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }

    /// RX filled above the zero line, TX filled below it — one shape, no color, just direction.
    /// Linear (not smoothed) interpolation keeps brief spikes looking like spikes rather than bumps.
    private var sparkline: some View {
        Chart {
            ForEach(entry.points, id: \.timestamp) { point in
                AreaMark(
                    x: .value("Time", point.date),
                    yStart: .value("Zero", 0),
                    yEnd: .value("Down", point.rxRate)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(.primary.opacity(0.2))
            }
            // Explicit `series:` so the download and upload lines aren't merged into one series,
            // which would draw a stray line connecting the two halves across the chart.
            ForEach(entry.points, id: \.timestamp) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Down", point.rxRate),
                    series: .value("Direction", "Download")
                )
                .interpolationMethod(.linear)
                .lineStyle(StrokeStyle(lineWidth: 1.3))
                .foregroundStyle(.primary)
            }

            ForEach(entry.points, id: \.timestamp) { point in
                AreaMark(
                    x: .value("Time", point.date),
                    yStart: .value("Zero", 0),
                    yEnd: .value("Up", -point.txRate)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(.secondary.opacity(0.2))
            }
            ForEach(entry.points, id: \.timestamp) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Up", -point.txRate),
                    series: .value("Direction", "Upload")
                )
                .interpolationMethod(.linear)
                .lineStyle(StrokeStyle(lineWidth: 1.3))
                .foregroundStyle(.secondary)
            }

            RuleMark(y: .value("Zero", 0))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .widgetAccentable()
    }
}
