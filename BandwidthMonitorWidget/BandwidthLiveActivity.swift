import ActivityKit
import WidgetKit
import SwiftUI
import Charts

/// Live Activity: a live bandwidth view on the Lock Screen and in the Dynamic Island.
struct BandwidthLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BandwidthActivityAttributes.self) { context in
            LiveActivityLockScreenView(state: context.state)
                .padding(12)
                .activityBackgroundTint(Color.black.opacity(0.45))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    rateLabel("arrow.down", context.state.rxRate, .blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    rateLabel("arrow.up", context.state.txRate, .orange)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveSparkline(points: context.state.points)
                        .frame(height: 40)
                }
            } compactLeading: {
                Image(systemName: "chart.line.uptrend.xyaxis")
            } compactTrailing: {
                Text(BitRateFormatter.string(fromBytesPerSecond: context.state.rxRate))
                    .font(.caption2)
            } minimal: {
                Image(systemName: "chart.line.uptrend.xyaxis")
            }
        }
    }

    private func rateLabel(_ symbol: String, _ value: Double, _ color: Color) -> some View {
        Label {
            Text(BitRateFormatter.string(fromBytesPerSecond: value)).font(.caption2)
        } icon: {
            Image(systemName: symbol).foregroundStyle(color)
        }
    }
}

struct LiveActivityLockScreenView: View {
    let state: BandwidthActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(state.interfaceName, systemImage: "network")
                    .font(.caption).bold()
                Spacer()
                HStack(spacing: 12) {
                    rate("arrow.down", state.rxRate, .blue)
                    rate("arrow.up", state.txRate, .orange)
                }
                .font(.caption2)
            }
            LiveSparkline(points: state.points)
                .frame(height: 46)
        }
        .foregroundStyle(.white)
    }

    private func rate(_ symbol: String, _ value: Double, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol).foregroundStyle(color)
            Text(BitRateFormatter.string(fromBytesPerSecond: value))
        }
    }
}

/// Mirrored sparkline (download above zero, upload below) with the **latest** sample clearly
/// marked: a dashed vertical "now" rule on the x-axis plus an emphasised dot on each of the
/// latest RX/TX points.
struct LiveSparkline: View {
    let points: [HistoryPoint]

    var body: some View {
        Chart {
            ForEach(points, id: \.timestamp) { p in
                AreaMark(x: .value("t", p.date), yStart: .value("r", 0), yEnd: .value("r", p.rxRate))
                    .foregroundStyle(by: .value("dir", "Download"))
                    .interpolationMethod(.monotone)
                    .opacity(0.18)
            }
            ForEach(points, id: \.timestamp) { p in
                AreaMark(x: .value("t", p.date), yStart: .value("r", 0), yEnd: .value("r", -p.txRate))
                    .foregroundStyle(by: .value("dir", "Upload"))
                    .interpolationMethod(.monotone)
                    .opacity(0.18)
            }
            ForEach(points, id: \.timestamp) { p in
                LineMark(x: .value("t", p.date), y: .value("r", p.rxRate), series: .value("dir", "Download"))
                    .foregroundStyle(by: .value("dir", "Download"))
                    .interpolationMethod(.monotone)
            }
            ForEach(points, id: \.timestamp) { p in
                LineMark(x: .value("t", p.date), y: .value("r", -p.txRate), series: .value("dir", "Upload"))
                    .foregroundStyle(by: .value("dir", "Upload"))
                    .interpolationMethod(.monotone)
            }

            RuleMark(y: .value("r", 0))
                .lineStyle(StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(.white.opacity(0.4))

            if let last = points.last {
                // Mark "now" on the x-axis…
                RuleMark(x: .value("now", last.date))
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    .foregroundStyle(.white.opacity(0.5))
                // …and emphasise the latest stat point itself.
                PointMark(x: .value("now", last.date), y: .value("r", last.rxRate))
                    .symbolSize(45)
                    .foregroundStyle(by: .value("dir", "Download"))
                PointMark(x: .value("now", last.date), y: .value("r", -last.txRate))
                    .symbolSize(45)
                    .foregroundStyle(by: .value("dir", "Upload"))
            }
        }
        .chartForegroundStyleScale(["Download": Color.blue, "Upload": Color.orange])
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
    }
}
