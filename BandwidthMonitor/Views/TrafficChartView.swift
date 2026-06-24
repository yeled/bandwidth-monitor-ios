import SwiftUI
import Charts

struct TrafficChartView: View {
    let points: [HistoryPoint]

    var body: some View {
        if points.isEmpty {
            emptyStateView
                .frame(height: 220)
        } else {
            VStack(spacing: 8) {
                chart
                HStack(spacing: 16) {
                    legendItem(color: .blue, label: "Download")
                    legendItem(color: .orange, label: "Upload")
                }
                .font(.caption2)
            }
        }
    }

    private var chart: some View {
        Chart {
                // Mirrored around zero like the Lock Screen widget: download above the line,
                // upload below it. Plotted in Mbps (decimal bits) to match the rest of the UI.
                // Each line gets an explicit `series:` so Charts doesn't merge them into one
                // series — which would both connect them with a stray line and paint them one colour.
                ForEach(points, id: \.timestamp) { point in
                    AreaMark(
                        x: .value("Time", point.date),
                        yStart: .value("Zero", 0),
                        yEnd: .value("Mbps", BitRateFormatter.mbps(fromBytesPerSecond: point.rxRate))
                    )
                    .foregroundStyle(Color.blue.opacity(0.15))
                    .interpolationMethod(.monotone)
                }
                ForEach(points, id: \.timestamp) { point in
                    AreaMark(
                        x: .value("Time", point.date),
                        yStart: .value("Zero", 0),
                        yEnd: .value("Mbps", -BitRateFormatter.mbps(fromBytesPerSecond: point.txRate))
                    )
                    .foregroundStyle(Color.orange.opacity(0.15))
                    .interpolationMethod(.monotone)
                }
                ForEach(points, id: \.timestamp) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Mbps", BitRateFormatter.mbps(fromBytesPerSecond: point.rxRate)),
                        series: .value("Direction", "Download")
                    )
                    .foregroundStyle(Color.blue)
                    .interpolationMethod(.monotone)
                }
                ForEach(points, id: \.timestamp) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Mbps", -BitRateFormatter.mbps(fromBytesPerSecond: point.txRate)),
                        series: .value("Direction", "Upload")
                    )
                    .foregroundStyle(Color.orange)
                    .interpolationMethod(.monotone)
                }
                RuleMark(y: .value("Mbps", 0))
                    .lineStyle(StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary)
            }
            .chartYAxisLabel("Mbps")
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    // Upload sits below zero, but show its magnitude as a positive Mbps figure.
                    AxisValueLabel {
                        if let mbps = value.as(Double.self) {
                            Text(abs(mbps).formatted(.number.precision(.fractionLength(0...1))))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .chartLegend(.hidden)
            .frame(height: 220)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundStyle(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No History Yet",
            systemImage: "chart.line.uptrend.xyaxis",
            description: Text("Waiting for traffic samples from the server.")
        )
    }
}
