# Changelog

Notes for releases of the Bandwidth Monitor iOS app. The "What's New" block under each version is
written to be pasted straight into App Store Connect.

## 0.9.0

First release — a SwiftUI client for [awlx/bandwidth-monitor](https://github.com/awlx/bandwidth-monitor).

**What's New (App Store):**

> Bandwidth Monitor shows your router's live traffic at a glance.
>
> • Live per-interface download/upload, in Mbps
> • Traffic graph with 1-hour and 24-hour ranges, mirrored around zero — download above the line, upload below
> • Lock Screen widget with a sparkline for your chosen interface
> • Live view: a Lock Screen and Dynamic Island Live Activity that updates live, with the latest reading clearly marked
> • Tidy "updating" indicator so the graph never silently rewrites the last hour under you

Requires iOS 17. iPhone, portrait.

### TestFlight build history

- **build 3** — Live Activity ("Go Live"): live Lock Screen / Dynamic Island view of the selected
  interface, with the latest sample marked (a "now" rule on the x-axis plus dots on the latest
  RX/TX points). Updates are local (while the app runs); server push is a planned follow-up.
- **build 2** — Reconciling indicator: the chart redacts with an "Updating…" pill while cached
  history is being replaced after launch/foreground, instead of silently swapping.
- **build 1** — Initial: live rates, 1H/24H mirrored traffic graph in Mbps, Lock Screen widget,
  app icon, export-compliance exemption; iPhone-only, portrait.
