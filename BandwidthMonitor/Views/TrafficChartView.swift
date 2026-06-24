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
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No History Yet",
            systemImage: "chart.line.uptrend.xyaxis",
            description: Text("Waiting for traffic samples from the server.")
        )
    }
}
