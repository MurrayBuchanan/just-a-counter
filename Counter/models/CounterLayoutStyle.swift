import Foundation

enum CounterLayoutStyle: String, CaseIterable, Identifiable, Codable {
    case standard
    case compact
    case wide
    case minimal

    var id: String { rawValue }
}
