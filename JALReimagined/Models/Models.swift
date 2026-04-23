import Foundation
import SwiftUI

// MARK: - Airport

struct Airport: Hashable, Codable {
    let code: String        // "HND"
    let city: String        // "Tokyo"
    let name: String        // "Haneda"
    let country: String
    let timezone: String    // "Asia/Tokyo"
    let latitude: Double
    let longitude: Double
}

// MARK: - Status

enum FlightStatus: String, Codable {
    case scheduled, checkInOpen, boarding, departed, inAir, landed, delayed, cancelled

    var label: String {
        switch self {
        case .scheduled:   return "Scheduled"
        case .checkInOpen: return "Check-in open"
        case .boarding:    return "Boarding"
        case .departed:    return "Departed"
        case .inAir:       return "In the air"
        case .landed:      return "Landed"
        case .delayed:     return "Delayed"
        case .cancelled:   return "Cancelled"
        }
    }

    var color: Color {
        switch self {
        case .delayed, .cancelled: return JALTheme.warning
        case .inAir, .boarding:    return JALTheme.success
        default:                   return JALTheme.inkSoft
        }
    }
}

// MARK: - Flight

struct Flight: Identifiable, Codable, Hashable {
    let id: String
    let number: String              // "JL1"
    let origin: Airport
    let destination: Airport
    let scheduledDeparture: Date
    let scheduledArrival: Date
    let actualDeparture: Date?
    let actualArrival: Date?
    let aircraft: String            // "Boeing 777-300ER"
    let aircraftReg: String         // "JA743J"
    let gate: String?
    let terminal: String?
    let seat: String                // "7K"
    let cabin: String               // "Business · SKY SUITE"
    let bookingClass: String        // "J"
    let status: FlightStatus
    let distanceKm: Int
    let onTimeProbability: Double   // 0...1
    let baggageClaim: String?
    let mealService: [String]
    let entertainmentHours: Int

    var durationMinutes: Int {
        Int(scheduledArrival.timeIntervalSince(scheduledDeparture) / 60)
    }
}

// MARK: - Trip

struct Trip: Identifiable, Codable, Hashable {
    let id: String
    let confirmationCode: String   // "JL-X92K7P"
    let passengerName: String
    let flights: [Flight]

    var primary: Flight { flights[0] }
    var isInternational: Bool { primary.origin.country != primary.destination.country }
}

// MARK: - Boarding pass

struct BoardingPass: Identifiable, Hashable {
    let id: String
    let flight: Flight
    let passengerName: String
    let sequence: String   // "027"
    let group: String      // "1"
    let ffNumber: String?
    let tsa: String?       // "TSA Pre ✓"
    let qrPayload: String
}

// MARK: - JMB

struct JMBProfile: Codable {
    let name: String
    let memberNumber: String
    let tier: String       // "JMB Diamond"
    let miles: Int         // Lifetime redeemable miles
    let flyOnPoints: Int?  // This year's FOP — the currency that drives status
    let flightsYTD: Int
    let segmentsYTD: Int
    let nextTier: String?
    let milesToNextTier: Int?
}
