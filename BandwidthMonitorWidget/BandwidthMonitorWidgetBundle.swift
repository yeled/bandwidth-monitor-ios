import WidgetKit
import SwiftUI

@main
struct BandwidthMonitorWidgetBundle: WidgetBundle {
    var body: some Widget {
        TrafficWidget()
        BandwidthLiveActivity()
    }
}
