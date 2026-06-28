# Live Activity push (keep the Lock Screen view live)

By default the Live Activity only updates while the app is running. To keep it ticking while the app
is suspended, a server pushes updates to it via ActivityKit / APNs. `scripts/live_activity_push.swift`
is a small, dependency-free pusher for that (CryptoKit signs the JWT, URLSession speaks HTTP/2).

## One-time setup

1. **Create an APNs auth key.** [Apple Developer → Certificates, Identifiers & Profiles → Keys](https://developer.apple.com/account/resources/authkeys/list)
   → ➕ → enable **Apple Push Notification service (APNs)** → download the `.p8` (you can only
   download it once) and note the **Key ID**. This is *separate* from the App Store Connect API key.
   - Team ID is `SA2SS4242K`; bundle ID is `com.evilforbeginners.BandwidthMonitor`.
   - The app's App ID already has the Push Notifications capability (added via the `aps-environment`
     entitlement; automatic signing enabled it).

## Each time you want it live

2. **Get the device's push token.** Install the app (TestFlight or a local run), open it, tap
   **Go Live**, then open **Settings** in the app — the **Live Activity push token** row appears once
   iOS issues one. Tap to copy.
3. **Run the pusher** (on any Mac that can reach both the router and the internet):

   ```bash
   swift scripts/live_activity_push.swift \
     --key ~/path/AuthKey_<KEYID>.p8 --key-id <KEYID> --team-id SA2SS4242K \
     --bundle-id com.evilforbeginners.BandwidthMonitor \
     --token <token from the app> \
     --server http://192.168.1.1:8080 --interface eth0 --interval 5
   ```

   It prints one line per push with the APNs status (`200` = delivered).

## Development vs production APNs

The push token's environment must match the APNs host:

| App build | `aps-environment` | APNs host | Pusher flag |
|-----------|-------------------|-----------|-------------|
| Run from Xcode to device | development | `api.sandbox.push.apple.com` | `--sandbox` |
| TestFlight / App Store | production | `api.push.apple.com` | *(none — default)* |

If pushes return `400 BadDeviceToken`, you're pushing to the wrong host for that token — flip the
`--sandbox` flag.

## Notes / gotchas

- The push token is **per activity** — it changes if you stop/restart Go Live or reinstall. Grab a
  fresh one from Settings each time.
- The activity must already be running (you tapped **Go Live**) — push *updates* an activity, it
  can't start one.
- `--dry-run` builds and prints the JWT + payload from synthetic data without contacting the server
  or APNs — useful for checking the key and encoding.
- Keep updates modest (a few seconds apart); APNs throttles high-frequency Live Activity pushes.
