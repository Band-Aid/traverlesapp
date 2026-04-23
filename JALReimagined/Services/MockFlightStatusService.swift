import Foundation

/// Believable mock that returns dynamic times relative to `now`, so the
/// countdown / "last updated" UI always feels alive. Used when no real
/// provider API key is configured.
struct MockFlightStatusService: FlightStatusService {

    func fetch(flightNumber: String, date: Date) async throws -> FlightLiveStatus {
        // Simulate a network round trip so the UI spinner is visible.
        try? await Task.sleep(for: .milliseconds(380))

        guard let template = Template.match(flightNumber) else {
            throw FlightStatusError.notFound
        }
        return template.materialize(now: Date())
    }

    // MARK: - Templates

    private struct Template {
        let number: String
        let airline: String
        let origin: AirportLite
        let destination: AirportLite
        let departureOffsetHours: Double   // relative to now
        let durationHours: Double
        let gate: String
        let terminal: String
        let aircraft: String
        let reg: String
        let status: LiveStatus

        static let all: [Template] = [
            Template(number: "JL1", airline: "JL",
                     origin: .hnd, destination: .jfk,
                     departureOffsetHours: 11.2, durationHours: 12.8,
                     gate: "141", terminal: "3",
                     aircraft: "Boeing 777-300ER", reg: "JA743J", status: .scheduled),

            Template(number: "JL2", airline: "JL",
                     origin: .jfk, destination: .hnd,
                     departureOffsetHours: 4.7, durationHours: 14.0,
                     gate: "7", terminal: "1",
                     aircraft: "Boeing 777-300ER", reg: "JA738J", status: .checkIn),

            Template(number: "JL5", airline: "JL",
                     origin: .hnd, destination: .jfk,
                     departureOffsetHours: 2.4, durationHours: 12.5,
                     gate: "148", terminal: "3",
                     aircraft: "Boeing 777-300ER", reg: "JA734J", status: .boarding),

            Template(number: "JL6", airline: "JL",
                     origin: .jfk, destination: .hnd,
                     departureOffsetHours: -3.0, durationHours: 14.0,
                     gate: "7", terminal: "1",
                     aircraft: "Boeing 777-300ER", reg: "JA738J", status: .enRoute),

            Template(number: "JL60", airline: "JL",
                     origin: .sfo, destination: .hnd,
                     departureOffsetHours: -2.5, durationHours: 11.0,
                     gate: "A6", terminal: "I",
                     aircraft: "Boeing 787-9", reg: "JA873J", status: .enRoute),

            Template(number: "JL61", airline: "JL",
                     origin: .hnd, destination: .lax,
                     departureOffsetHours: 6.8, durationHours: 10.2,
                     gate: "144", terminal: "3",
                     aircraft: "Boeing 787-9", reg: "JA869J", status: .scheduled),

            Template(number: "JL505", airline: "JL",
                     origin: .hnd, destination: .cts,
                     departureOffsetHours: 1.3, durationHours: 1.6,
                     gate: "62", terminal: "1",
                     aircraft: "Airbus A350-900", reg: "JA08XJ", status: .boarding),

            Template(number: "JL107", airline: "JL",
                     origin: .hnd, destination: .itm,
                     departureOffsetHours: 0.3, durationHours: 1.1,
                     gate: "19", terminal: "1",
                     aircraft: "Boeing 767-300ER", reg: "JA8397", status: .gateClosed)
        ]

        static func match(_ flightNumber: String) -> Template? {
            if let exact = all.first(where: { $0.number == flightNumber }) {
                return exact
            }
            // Synthesize a plausible HND→HND long-haul response for any unknown
            // JL flight so the demo never feels like a wall.
            guard flightNumber.hasPrefix("JL") else { return nil }
            return Template(number: flightNumber, airline: "JL",
                            origin: .hnd, destination: .lax,
                            departureOffsetHours: 5.5, durationHours: 10.2,
                            gate: "144", terminal: "3",
                            aircraft: "Boeing 787-9", reg: "JA870J",
                            status: .scheduled)
        }

        func materialize(now: Date) -> FlightLiveStatus {
            let scheduledDep = now.addingTimeInterval(departureOffsetHours * 3600)
            let scheduledArr = scheduledDep.addingTimeInterval(durationHours * 3600)
            // Random-ish small delay to make things feel real
            let delaySec = Int((abs(scheduledDep.timeIntervalSince1970).truncatingRemainder(dividingBy: 8)) * 60)
            let estDep = scheduledDep.addingTimeInterval(Double(delaySec))
            let estArr = scheduledArr.addingTimeInterval(Double(delaySec))

            let actualDep: Date? = status == .enRoute || status == .landed ? estDep : nil
            let actualArr: Date? = status == .landed ? estArr : nil

            return FlightLiveStatus(
                flightNumber: number,
                airlineIATA: airline,
                originIATA: origin.code,
                originCity: origin.city,
                originTimezone: origin.tz,
                originLat: origin.lat, originLon: origin.lon,
                destinationIATA: destination.code,
                destinationCity: destination.city,
                destinationTimezone: destination.tz,
                destinationLat: destination.lat, destinationLon: destination.lon,
                scheduledDeparture: scheduledDep,
                estimatedDeparture: estDep,
                actualDeparture: actualDep,
                scheduledArrival: scheduledArr,
                estimatedArrival: estArr,
                actualArrival: actualArr,
                departureGate: gate,
                departureTerminal: terminal,
                arrivalGate: nil,
                arrivalTerminal: nil,
                baggageBelt: nil,
                aircraftModel: aircraft,
                aircraftReg: reg,
                status: status,
                lastFetched: now
            )
        }
    }

    // MARK: - Airport directory

    private struct AirportLite {
        let code: String, city: String, tz: String, lat: Double, lon: Double

        static let hnd = AirportLite(code: "HND", city: "Tokyo",
                                     tz: "Asia/Tokyo", lat: 35.5494, lon: 139.7798)
        static let nrt = AirportLite(code: "NRT", city: "Tokyo",
                                     tz: "Asia/Tokyo", lat: 35.7720, lon: 140.3929)
        static let sfo = AirportLite(code: "SFO", city: "San Francisco",
                                     tz: "America/Los_Angeles", lat: 37.6213, lon: -122.3790)
        static let lax = AirportLite(code: "LAX", city: "Los Angeles",
                                     tz: "America/Los_Angeles", lat: 33.9416, lon: -118.4085)
        static let jfk = AirportLite(code: "JFK", city: "New York",
                                     tz: "America/New_York", lat: 40.6413, lon: -73.7781)
        static let itm = AirportLite(code: "ITM", city: "Osaka",
                                     tz: "Asia/Tokyo", lat: 34.7855, lon: 135.4382)
        static let cts = AirportLite(code: "CTS", city: "Sapporo",
                                     tz: "Asia/Tokyo", lat: 42.7752, lon: 141.6923)
    }
}
