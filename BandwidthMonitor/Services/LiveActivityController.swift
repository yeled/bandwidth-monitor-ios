import ActivityKit
import Foundation

/// Starts, updates, and ends the bandwidth Live Activity.
///
/// Note: updates here are *local* — they only land while the app is running (foreground, or briefly
/// in the background). Keeping the Lock Screen genuinely live when the app is fully suspended would
/// need ActivityKit push updates (APNs) driven from the server. See the branch notes.
@MainActor
final class LiveActivityController {
    private var activity: Activity<BandwidthActivityAttributes>?

    var isRunning: Bool { activity != nil }

    /// Whether the user has Live Activities enabled for the app in Settings.
    var areActivitiesEnabled: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func start(_ state: BandwidthActivityAttributes.ContentState) {
        guard areActivitiesEnabled, activity == nil else { return }
        do {
            activity = try Activity.request(
                attributes: BandwidthActivityAttributes(title: "Bandwidth"),
                content: .init(state: state, staleDate: Date().addingTimeInterval(120))
            )
        } catch {
            activity = nil
        }
    }

    func update(_ state: BandwidthActivityAttributes.ContentState) async {
        guard let activity else { return }
        await activity.update(.init(state: state, staleDate: Date().addingTimeInterval(120)))
    }

    func stop() async {
        await activity?.end(nil, dismissalPolicy: .immediate)
        activity = nil
    }

    /// Re-attach to an activity already running from a previous launch, so the toggle reflects reality.
    func adopt() {
        activity = Activity<BandwidthActivityAttributes>.activities.first
    }
}
