import Foundation

/// Mirrors `collector.InterfaceStat` from bandwidth-monitor's `/api/interfaces` response.
struct InterfaceStat: Decodable, Identifiable {
    var id: String { name }

    let name: String
    let ifaceType: String
    let operState: String
    let addrs: [String]?
    let wan: Bool?
    let vpnRouting: Bool
    let vpnTracked: Bool
    let speed: Int?
    let rxBytes: UInt64
    let txBytes: UInt64
    let rxPackets: UInt64
    let txPackets: UInt64
    let rxErrors: UInt64
    let txErrors: UInt64
    let rxDropped: UInt64
    let txDropped: UInt64
    let rxRate: Double
    let txRate: Double
    let rxPPS: Double
    let txPPS: Double
    let timestamp: Int64

    enum CodingKeys: String, CodingKey {
        case name
        case ifaceType = "iface_type"
        case operState = "oper_state"
        case addrs
        case wan
        case vpnRouting = "vpn_routing"
        case vpnTracked = "vpn_tracked"
        case speed
        case rxBytes = "rx_bytes"
        case txBytes = "tx_bytes"
        case rxPackets = "rx_packets"
        case txPackets = "tx_packets"
        case rxErrors = "rx_errors"
        case txErrors = "tx_errors"
        case rxDropped = "rx_dropped"
        case txDropped = "tx_dropped"
        case rxRate = "rx_rate"
        case txRate = "tx_rate"
        case rxPPS = "rx_pps"
        case txPPS = "tx_pps"
        case timestamp
    }
}
