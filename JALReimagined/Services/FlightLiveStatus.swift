import Foundation

/// Live status for a single flight, unified across real and mock providers.
struct FlightLiveStatus: Codable, Equatable, Hashable, Identifiable {
    let flightNumber: String        // "JL2"
    let airlineIATA: String         // "JL"
    let originIATA: String          // "HND"
    let originCity: String
    let originTimezone: String      // "Asia/Tokyo"
    let originLat: Double
    let originLon: Double
    let destinationIATA: String     // "SFO"
    let destinationCity: String
    let destinationTimezone: String
    let destinationLat: Double
    let destinationLon: Double

    let scheduledDeparture: Date
    let estimatedDeparture: Date?
    let actualDeparture: Date?
    let scheduledArrival: Date
    let estimatedArrival: Date?
    let actualArrival: Date?

    let departureGate: String?
    let departureTerminal: String?
    let arrivalGate: String?
    let arrivalTerminal: String?
    let baggageBelt: String?

    let aircraftModel: String?
    let aircraftReg: String?

    let status: LiveStatus

    /// When this record was fetched from the source. The countdown uses this
    /// to answer "how long since last known state" even with no network.
    let lastFetched: Date

    var id: String { "\(flightNumber)|\(scheduledDeparture.timeIntervalSince1970)" }
}

enum LiveStatus: String, Codable {
    case scheduled   = "Scheduled"
    case checkIn     = "Check-in"
    case boarding    = "Boarding"
    case gateClosed  = "Gate closed"
    case departed    = "Departed"
    case enRoute     = "En route"
    case approaching = "Approaching"
    case landed      = "Landed"
    case arrived     = "Arrived"
    case delayed     = "Delayed"
    case cancelled   = "Cancelled"
    case diverted    = "Diverted"
    case unknown     = "Unknown"
}

enum FlightStatusError: LocalizedError {
    case notFound
    case notConfigured
    case network(Error)
    case decoding(Error)
    case invalidFlightNumber

    var errorDescription: String? {
        switch self {
        case .notFound:           return "No flight with that number today."
        case .notConfigured:      return "Flight provider not configured."
        case .network(let e):     return "Network error: \(e.localizedDescription)"
        case .decoding:           return "Couldn't read the flight data."
        case .invalidFlightNumber: return "Enter a valid flight number (e.g. JL2)."
        }
    }
}

/// Canonicalizes "jl 2", "JAL002", " JL2 " → "JL2".
enum FlightNumberParser {
    static func normalize(_ raw: String) -> String? {
        let trimmed = raw.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        guard !trimmed.isEmpty else { return nil }

        // Accept "JAL" prefix as alias for "JL"
        let s = trimmed.hasPrefix("JAL") ? "JL" + trimmed.dropFirst(3) : trimmed

        // Must be 2 letters + 1-4 digits
        let pattern = #"^([A-Z]{2})(\d{1,4})$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              match.numberOfRanges == 3,
              let airlineRange = Range(match.range(at: 1), in: s),
              let numberRange = Range(match.range(at: 2), in: s)
        else { return nil }

        let airline = String(s[airlineRange])
        // Drop leading zeros from the digit part ("0002" → "2")
        let num = Int(s[numberRange]) ?? 0
        return "\(airline)\(num)"
    }
}

protocol FlightStatusService {
    func fetch(flightNumber: String, date: Date) async throws -> FlightLiveStatus
}
