import WidgetKit
import SwiftUI

struct TrafficWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: TrafficWidgetKind.id, provider: TrafficWidgetProvider()) { entry in
            TrafficWidgetView(entry: entry)
        }
        .configurationDisplayName("Traffic")
        .description("RX above the line, TX below, for your selected interface.")
        .supportedFamilies([.accessoryRectangular])
    }
}
