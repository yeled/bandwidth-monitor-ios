# Live Activity push (keep the Lock Screen view live)

By default the Live Activity only updates while the app is running. To keep it ticking while the app
is suspended, the **bandwidth-monitor Go server pushes updates to it via ActivityKit / APNs**. The
server ([yeled/bandwidth-monitor](https://github.com/yeled/bandwidth-monitor)) already runs
continuously and has the data, so it's the whole "APN machine" — there's no separate pusher process.

How it fits together:

1. You tap **Go Live** in the app → iOS issues a push token → the app POSTs it to the server's
   `POST /api/liveactivity/register` (`{token, interface, environment}`). The `environment` is
   `sandbox` for a build run from Xcode and `production` for TestFlight/App Store.
2. The server's `liveactivity` package pushes the current content-state to APNs for each registered
   token every `APNS_PUSH_INTERVAL`.

## Server setup (one time)

1. **Create an APNs auth key.** [Apple Developer → Keys](https://developer.apple.com/account/resources/authkeys/list)
   → ➕ → enable **Apple Push Notification service** → download the `.p8` (once only), note the
   **Key ID**. Team ID is `SA2SS4242K`, bundle ID `com.evilforbeginners.BandwidthMonitor`.
2. **Put the `.p8` on the router** (chmod 0600) and set the APNs env vars (see `env.example`):

   ```sh
   APNS_KEY_FILE=/etc/bandwidth-monitor/AuthKey_XXXXXXXXXX.p8
   APNS_KEY_ID=XXXXXXXXXX
   APNS_TEAM_ID=SA2SS4242K
   APNS_BUNDLE_ID=com.evilforbeginners.BandwidthMonitor
   APNS_ENV=production      # or sandbox for Xcode dev builds
   APNS_PUSH_INTERVAL=10s
   ```

   The server needs outbound HTTPS to `api.push.apple.com:443` (or `api.sandbox.push.apple.com`).
   The feature is inert unless `APNS_KEY_FILE` is set.

## Using it

Open the app, tap **Go Live**, and lock the phone — the Lock Screen / Dynamic Island view now keeps
updating from the server even with the app closed. Switching the interface in the app re-registers,
so the server pushes the newly-selected interface.

## Dev vs production APNs

The push token's environment must match the APNs host, and the app sends the right one automatically
(`#if DEBUG` → `sandbox`, else `production`). On the server, set `APNS_ENV` to match the builds
you're testing. A `400 BadDeviceToken` in the server logs means the environments don't match.

## Notes

- The push token is **per activity** — it changes when you stop/restart Go Live or reinstall; the
  app re-registers automatically. Tokens are held in memory, so after a server restart, reopen the
  app (or toggle Go Live) to re-register.
- The token is also shown (copyable) in the app's **Settings** for debugging.
- APNs throttles high-frequency Live Activity pushes; keep `APNS_PUSH_INTERVAL` at a few seconds.
