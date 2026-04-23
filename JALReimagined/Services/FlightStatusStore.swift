import Foundation
import Observation
import SwiftUI

/// Cache-first flight status store. The UI binds to `current` (the actively
/// searched flight in the Status tab), `tracked` (every flight the user is
/// following — persisted across launches), and reads `isOffline` / `lastError`
/// to render stale-data badges. Kicks off a 15-min foreground refresh timer
/// whenever a flight is being tracked, and exposes `backgroundRefresh()` for
/// SwiftUI's `.backgroundTask(.appRefresh:)`.
@Observable
final class FlightStatusStore {
    var current: FlightLiveStatus?
    var tracked: [FlightLiveStatus] = []
    var recent: [String] = []
    var isLoading: Bool = false
    var lastError: String?
    var isOffline: Bool = false

    private let service: FlightStatusService
    private let fallback: FlightStatusService
    private let cache: FlightStatusCache

    private var refreshTask: Task<Void, Never>?
    static let refreshInterval: TimeInterval = 15 * 60  // 15 minutes

    init(service: FlightStatusService,
         fallback: FlightStatusService = MockFlightStatusService(),
         cache: FlightStatusCache = .shared) {
        self.service = service
        self.fallback = fallback
        self.cache = cache
        self.recent = cache.recentFlightNumbers()
        self.tracked = Self.sorted(cache.loadAll())
    }

    /// Primary user-initiated lookup: normalize, show cached result instantly,
    /// then refresh from network in the background.
    @MainActor
    func lookup(_ rawFlightNumber: String) async {
        guard let number = FlightNumberParser.normalize(rawFlightNumber) else {
            lastError = FlightStatusError.invalidFlightNumber.errorDescription
            return
        }
        lastError = nil

        // 1) Show cached state immediately (offline-first).
        if let cached = cache.load(flightNumber: number) {
            current = cached
            isOffline = true  // treat as stale until network confirms
        }

        // 2) Network refresh.
        isLoading = true
        defer { isLoading = false }
        do {
            let fresh = try await service.fetch(flightNumber: number, date: Date())
            persist(fresh, setCurrent: true)
            isOffline = false
            scheduleAutoRefresh(for: number)
        } catch FlightStatusError.notConfigured {
            // No real API key — fall through to the mock provider so the
            // app still feels live.
            do {
                let mocked = try await fallback.fetch(flightNumber: number, date: Date())
                persist(mocked, setCurrent: true)
                isOffline = false
                scheduleAutoRefresh(for: number)
            } catch {
                handleFailure(error, hadCache: current != nil)
            }
        } catch {
            handleFailure(error, hadCache: current != nil)
        }
    }

    /// Silent refresh driven by the 15-min timer or background task. Doesn't
    /// touch `isLoading` so it never flashes a spinner.
    @MainActor
    func silentRefresh() async {
        guard let number = current?.flightNumber ?? tracked.first?.flightNumber else { return }
        do {
            let fresh = try await service.fetch(flightNumber: number, date: Date())
            persist(fresh, setCurrent: current?.flightNumber == number)
            isOffline = false
        } catch FlightStatusError.notConfigured {
            if let mocked = try? await fallback.fetch(flightNumber: number, date: Date()) {
                persist(mocked, setCurrent: current?.flightNumber == number)
                isOffline = false
            }
        } catch {
            isOffline = true
        }
    }

    /// Called from SwiftUI `.backgroundTask(.appRefresh:)`. Refreshes every
    /// tracked flight number in the cache.
    func backgroundRefresh() async {
        let numbers = await MainActor.run { self.tracked.map(\.flightNumber) }
        for number in numbers {
            do {
                let fresh = try await service.fetch(flightNumber: number, date: Date())
                await MainActor.run {
                    self.persist(fresh, setCurrent: self.current?.flightNumber == number)
                }
            } catch {
                continue
            }
        }
    }

    /// Stops tracking this flight and drops the cached entry.
    @MainActor
    func untrack(_ flightNumber: String) {
        cache.remove(flightNumber: flightNumber)
        tracked.removeAll { $0.flightNumber == flightNumber }
        recent.removeAll { $0 == flightNumber }
        if current?.flightNumber == flightNumber { current = nil }
        if tracked.isEmpty { stopAutoRefresh() }
    }

    /// Returns the most recently cached state for a given flight number.
    func status(for flightNumber: String) -> FlightLiveStatus? {
        tracked.first { $0.flightNumber == flightNumber }
    }

    /// The most imminent upcoming (not-yet-arrived) tracked flight.
    var nextUpcoming: FlightLiveStatus? {
        tracked
            .filter { $0.actualArrival == nil }
            .min { Self.departure($0) < Self.departure($1) }
    }

    // MARK: - Private

    @MainActor
    private func persist(_ status: FlightLiveStatus, setCurrent: Bool) {
        cache.save(status)
        var list = tracked.filter { $0.flightNumber != status.flightNumber }
        list.append(status)
        tracked = Self.sorted(list)
        recent = cache.recentFlightNumbers()
        if setCurrent { current = status }
    }

    @MainActor
    private func handleFailure(_ error: Error, hadCache: Bool) {
        if hadCache {
            isOffline = true
            lastError = nil
        } else {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private static func sorted(_ statuses: [FlightLiveStatus]) -> [FlightLiveStatus] {
        statuses.sorted { departure($0) < departure($1) }
    }

    private static func departure(_ status: FlightLiveStatus) -> Date {
        status.estimatedDeparture ?? status.scheduledDeparture
    }

    // MARK: - Foreground auto-refresh

    @MainActor
    func scheduleAutoRefresh(for flightNumber: String) {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.refreshInterval))
                guard let self, !Task.isCancelled else { return }
                await self.silentRefresh()
            }
        }
    }

    @MainActor
    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}

// MARK: - Factory

extension FlightStatusStore {
    /// Builds the default store: reads an API key from Info.plist under
    /// `AeroDataBoxAPIKey` and uses `AeroDataBoxService` if present, otherwise
    /// falls back to the mock.
    static func makeDefault() -> FlightStatusStore {
        let key = Bundle.main.object(forInfoDictionaryKey: "AeroDataBoxAPIKey") as? String
        if let key, !key.isEmpty {
            return FlightStatusStore(service: AeroDataBoxService(apiKey: key))
        }
        return FlightStatusStore(service: MockFlightStatusService())
    }
}
