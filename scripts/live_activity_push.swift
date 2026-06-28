#!/usr/bin/env swift
//
// live_activity_push.swift — drive the Bandwidth Monitor Live Activity via ActivityKit/APNs so the
// Lock Screen view keeps updating while the app is suspended.
//
// It polls a bandwidth-monitor server, builds the Live Activity content-state, and POSTs it to APNs
// for one activity push token. Dependency-free: CryptoKit signs the ES256 JWT, URLSession speaks
// HTTP/2.
//
// Usage:
//   swift scripts/live_activity_push.swift \
//     --key ~/.appstoreconnect/private_keys/AuthKey_XXENABLED.p8 \
//     --key-id <APNS_KEY_ID> --team-id SA2SS4242K \
//     --bundle-id com.evilforbeginners.BandwidthMonitor \
//     --token <hex push token from the app's Settings> \
//     --server http://192.168.1.1:8080 [--interface eth0] [--interval 5] [--sandbox]
//
//   Add --dry-run to print the JWT + payload from synthetic data without contacting the server or
//   APNs (handy for checking the key + encoding).
//
// The APNs key is an "Apple Push Notification service" key created in the Apple Developer portal
// (Certificates, Identifiers & Profiles → Keys) — NOT the App Store Connect API key.
import Foundation
import CryptoKit

// MARK: - args

func arg(_ name: String) -> String? {
    let a = CommandLine.arguments
    guard let i = a.firstIndex(of: "--\(name)"), i + 1 < a.count else { return nil }
    return a[i + 1]
}
func flag(_ name: String) -> Bool { CommandLine.arguments.contains("--\(name)") }
func die(_ msg: String) -> Never { FileHandle.standardError.write(Data("error: \(msg)\n".utf8)); exit(1) }
func require<T>(_ value: T?, _ msg: String) -> T {
    guard let value else { die(msg) }
    return value
}

let dryRun = flag("dry-run")
let keyID = require(arg("key-id"), "missing --key-id")
let teamID = require(arg("team-id"), "missing --team-id")
let bundleID = require(arg("bundle-id"), "missing --bundle-id")
let token = dryRun ? (arg("token") ?? "DRYRUNTOKEN") : require(arg("token"), "missing --token")
let interval = Double(arg("interval") ?? "5") ?? 5
let preferredInterface = arg("interface")
let apnsHost = flag("sandbox") ? "https://api.sandbox.push.apple.com" : "https://api.push.apple.com"

// MARK: - signing key (.p8 PKCS#8 EC private key)

let signingKey: P256.Signing.PrivateKey = {
    guard let path = arg("key") else { die("missing --key (path to AuthKey_*.p8)") }
    guard let pem = try? String(contentsOfFile: (path as NSString).expandingTildeInPath, encoding: .utf8) else {
        die("can't read key at \(path)")
    }
    do { return try P256.Signing.PrivateKey(pemRepresentation: pem) }
    catch { die("not a valid P-256 .p8 key: \(error)") }
}()

func base64url(_ data: Data) -> String {
    data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

/// APNs provider JWT (ES256). Apple wants it refreshed at most hourly; we regenerate every ~50 min.
var cachedJWT: (token: String, issuedAt: Date)?
func providerToken() -> String {
    if let c = cachedJWT, Date().timeIntervalSince(c.issuedAt) < 50 * 60 { return c.token }
    let header = #"{"alg":"ES256","kid":"\#(keyID)"}"#
    let claims = #"{"iss":"\#(teamID)","iat":\#(Int(Date().timeIntervalSince1970))}"#
    let input = base64url(Data(header.utf8)) + "." + base64url(Data(claims.utf8))
    let sig = try! signingKey.signature(for: Data(input.utf8))
    let jwt = input + "." + base64url(sig.rawRepresentation)
    cachedJWT = (jwt, Date())
    return jwt
}

// MARK: - content-state (must match BandwidthActivityAttributes.ContentState)

struct Point: Codable { let t: Int64; let rx: Double; let tx: Double }
struct ContentState: Codable {
    let interfaceName: String
    let rxRate: Double
    let txRate: Double
    let points: [Point]
    let updatedAt: Double
}

// MARK: - server polling

func fetchJSON(_ url: URL) -> Any? {
    let sem = DispatchSemaphore(value: 0)
    var result: Any?
    URLSession.shared.dataTask(with: url) { data, _, _ in
        if let data { result = try? JSONSerialization.jsonObject(with: data) }
        sem.signal()
    }.resume()
    sem.wait()
    return result
}

func currentState(server: String) -> ContentState? {
    guard let base = URL(string: server) else { return nil }
    let ifaces = fetchJSON(base.appendingPathComponent("/api/interfaces")) as? [[String: Any]] ?? []
    let history = fetchJSON(base.appendingPathComponent("/api/interfaces/history")) as? [String: [[String: Any]]] ?? [:]

    let name = preferredInterface
        ?? (ifaces.first { ($0["wan"] as? Bool) == true }?["name"] as? String)
        ?? ifaces.first?["name"] as? String
        ?? history.keys.sorted().first
    guard let name else { return nil }

    let stat = ifaces.first { $0["name"] as? String == name }
    let rx = stat?["rx_rate"] as? Double ?? 0
    let tx = stat?["tx_rate"] as? Double ?? 0

    let cutoff = (Date().timeIntervalSince1970 - 3600) * 1000
    var pts = (history[name] ?? [])
        .compactMap { p -> Point? in
            guard let t = p["t"] as? Double else { return nil }
            return Point(t: Int64(t), rx: p["rx"] as? Double ?? 0, tx: p["tx"] as? Double ?? 0)
        }
        .filter { Double($0.t) >= cutoff }
    // thin to ~38 points, keeping the last
    if pts.count > 38 {
        let stride = max(1, pts.count / 38)
        pts = Swift.stride(from: 0, to: pts.count, by: stride).map { pts[$0] }
    }
    pts.append(Point(t: Int64(Date().timeIntervalSince1970 * 1000), rx: rx, tx: tx))
    return ContentState(interfaceName: name, rxRate: rx, txRate: tx, points: pts, updatedAt: Date().timeIntervalSince1970)
}

func syntheticState() -> ContentState {
    let now = Date().timeIntervalSince1970
    let pts = (0..<10).map { i in Point(t: Int64((now - Double(10 - i) * 60) * 1000), rx: 3_000_000, tx: 600_000) }
    return ContentState(interfaceName: preferredInterface ?? "eth0", rxRate: 6_500_000, txRate: 920_000, points: pts, updatedAt: now)
}

// MARK: - APNs send

func push(_ state: ContentState) {
    let encoder = JSONEncoder()
    let stateJSON = (try? encoder.encode(state)).flatMap { try? JSONSerialization.jsonObject(with: $0) } ?? [:]
    let now = Int(Date().timeIntervalSince1970)
    let payload: [String: Any] = ["aps": [
        "timestamp": now,
        "event": "update",
        "content-state": stateJSON,
        "stale-date": now + 120,
    ]]
    let body = try! JSONSerialization.data(withJSONObject: payload)

    if dryRun {
        print("JWT: \(providerToken())")
        print("POST \(apnsHost)/3/device/\(token)")
        print(String(data: body, encoding: .utf8) ?? "")
        return
    }

    var req = URLRequest(url: URL(string: "\(apnsHost)/3/device/\(token)")!)
    req.httpMethod = "POST"
    req.httpBody = body
    req.setValue("bearer \(providerToken())", forHTTPHeaderField: "authorization")
    req.setValue("\(bundleID).push-type.liveactivity", forHTTPHeaderField: "apns-topic")
    req.setValue("liveactivity", forHTTPHeaderField: "apns-push-type")
    req.setValue("10", forHTTPHeaderField: "apns-priority")

    let sem = DispatchSemaphore(value: 0)
    URLSession.shared.dataTask(with: req) { data, resp, err in
        defer { sem.signal() }
        if let err { print("send error: \(err)"); return }
        let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
        let reason = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let stamp = ISO8601DateFormatter().string(from: Date())
        print("[\(stamp)] \(state.interfaceName) ↓\(Int(state.rxRate * 8 / 1_000_000))Mbps ↑\(Int(state.txRate * 8 / 1_000_000))Mbps → APNs \(code) \(reason)")
    }.resume()
    sem.wait()
}

// MARK: - run

if dryRun {
    push(syntheticState())
    exit(0)
}
guard let server = arg("server") else { die("missing --server") }
print("Pushing \(bundleID) Live Activity every \(interval)s via \(apnsHost). Ctrl-C to stop.")
while true {
    if let state = currentState(server: server) { push(state) }
    else { print("no data from \(server) yet") }
    Thread.sleep(forTimeInterval: interval)
}
