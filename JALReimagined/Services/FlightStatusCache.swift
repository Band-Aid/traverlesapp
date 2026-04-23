import Foundation

/// Offline-first cache. Each lookup is persisted by normalized flight number
/// so opening the app with no network still shows the last known state and
/// lets the countdown UI tick from `lastFetched`.
final class FlightStatusCache {
    static let shared = FlightStatusCache()

    private let defaults: UserDefaults
    private let key = "flight_status_cache.v1"
    private let historyKey = "flight_status_history.v1"
    private let queue = DispatchQueue(label: "FlightStatusCache", attributes: .concurrent)

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ status: FlightLiveStatus) {
        queue.async(flags: .barrier) {
            var map = self.loadMap()
            map[status.flightNumber] = status
            self.writeMap(map)

            var history = self.defaults.stringArray(forKey: self.historyKey) ?? []
            history.removeAll(where: { $0 == status.flightNumber })
            history.insert(status.flightNumber, at: 0)
            if history.count > 20 { history = Array(history.prefix(20)) }
            self.defaults.set(history, forKey: self.historyKey)
        }
    }

    func load(flightNumber: String) -> FlightLiveStatus? {
        queue.sync { loadMap()[flightNumber] }
    }

    func loadAll() -> [FlightLiveStatus] {
        queue.sync { Array(loadMap().values) }
    }

    func remove(flightNumber: String) {
        queue.async(flags: .barrier) {
            var map = self.loadMap()
            map.removeValue(forKey: flightNumber)
            self.writeMap(map)

            var history = self.defaults.stringArray(forKey: self.historyKey) ?? []
            history.removeAll(where: { $0 == flightNumber })
            self.defaults.set(history, forKey: self.historyKey)
        }
    }

    func recentFlightNumbers(limit: Int = 10) -> [String] {
        Array((defaults.stringArray(forKey: historyKey) ?? []).prefix(limit))
    }

    func clear() {
        queue.async(flags: .barrier) {
            self.defaults.removeObject(forKey: self.key)
            self.defaults.removeObject(forKey: self.historyKey)
        }
    }

    // MARK: - Storage

    private func loadMap() -> [String: FlightLiveStatus] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([String: FlightLiveStatus].self, from: data)) ?? [:]
    }

    private func writeMap(_ map: [String: FlightLiveStatus]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(map) {
            defaults.set(data, forKey: key)
        }
    }
}
