import ActivityKit
import Foundation

/// Starts, updates, and ends the bandwidth Live Activity.
///
/// The activity is requested with a push token, so a server can drive updates via ActivityKit /
/// APNs while the app is suspended (see `scripts/live_activity_push.py`). The local `update(_:)`
/// path still runs while the app is foregrounded, so it works with or without a push sender.
@MainActor
final class LiveActivityController {
    private var activity: Activity<BandwidthActivityAttributes>?
    private var pushTokenTask: Task<Void, Never>?

    var isRunning: Bool { activity != nil }
    var areActivitiesEnabled: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    /// Hex APNs push token for the running activity, once iOS issues one. Hand this to the pusher.
    private(set) var pushToken: String?

    func start(_ state: BandwidthActivityAttributes.ContentState, onPushToken: @escaping (String) -> Void) {
        guard areActivitiesEnabled, activity == nil else { return }
        do {
            let activity = try Activity.request(
                attributes: BandwidthActivityAttributes(title: "Bandwidth"),
                content: .init(state: state, staleDate: Date().addingTimeInterval(120)),
                pushType: .token
            )
            self.activity = activity
            observePushToken(of: activity, onPushToken: onPushToken)
        } catch {
            activity = nil
        }
    }

    func update(_ state: BandwidthActivityAttributes.ContentState) async {
        guard let activity else { return }
        await activity.update(.init(state: state, staleDate: Date().addingTimeInterval(120)))
    }

    func stop() async {
        pushTokenTask?.cancel()
        pushTokenTask = nil
        await activity?.end(nil, dismissalPolicy: .immediate)
        activity = nil
        pushToken = nil
    }

    /// Re-attach to an activity still running from a previous launch, so the toggle reflects reality.
    func adopt(onPushToken: @escaping (String) -> Void) {
        guard let existing = Activity<BandwidthActivityAttributes>.activities.first else { return }
        activity = existing
        observePushToken(of: existing, onPushToken: onPushToken)
    }

    private func observePushToken(of activity: Activity<BandwidthActivityAttributes>,
                                  onPushToken: @escaping (String) -> Void) {
        pushTokenTask?.cancel()
        pushTokenTask = Task { [weak self] in
            for await tokenData in activity.pushTokenUpdates {
                let hex = tokenData.map { String(format: "%02x", $0) }.joined()
                self?.pushToken = hex
                onPushToken(hex)
            }
        }
    }
}
