import WidgetKit
import SwiftUI

struct TrafficWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: TrafficWidgetKind.id, provider: TrafficWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                TrafficWidgetView(entry: entry)
                    .containerBackground(for: .widget) { Color.clear }
            } else {
                TrafficWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Traffic")
        .description("RX above the line, TX below, for your selected interface.")
        .supportedFamilies([.accessoryRectangular])
    }
}
