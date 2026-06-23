import SwiftUI
import Charts

struct TrafficChartView: View {
    let points: [HistoryPoint]

    var body: some View {
        if points.isEmpty {
            emptyStateView
                .frame(height: 220)
        } else {
            Chart {
                ForEach(points, id: \.timestamp) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Download", point.rxRate)
                    )
                    .foregroundStyle(by: .value("Direction", "Download"))
                    .interpolationMethod(.monotone)
                }
                ForEach(points, id: \.timestamp) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Upload", point.txRate)
                    )
                    .foregroundStyle(by: .value("Direction", "Upload"))
                    .interpolationMethod(.monotone)
                }
            }
            .chartForegroundStyleScale([
                "Download": Color.blue,
                "Upload": Color.orange,
            ])
            .chartYAxisLabel("bytes/sec")
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .frame(height: 220)
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        if #available(iOS 17.0, *) {
            ContentUnavailableView(
                "No History Yet",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("Waiting for traffic samples from the server.")
            )
        } else {
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("No History Yet")
                    .font(.headline)
                
                Text("Waiting for traffic samples from the server.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
