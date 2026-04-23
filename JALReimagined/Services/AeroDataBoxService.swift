import Foundation

/// Real flight status via AeroDataBox (RapidAPI).
/// Endpoint: https://aerodatabox.p.rapidapi.com/flights/number/{number}/{YYYY-MM-DD}
///
/// To enable: add `AeroDataBoxAPIKey` to Info.plist (string). The app falls
/// back to MockFlightStatusService if the key is missing.
struct AeroDataBoxService: FlightStatusService {
    let apiKey: String
    var session: URLSession = .shared

    func fetch(flightNumber: String, date: Date) async throws -> FlightLiveStatus {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(identifier: "UTC")
        let dateString = df.string(from: date)

        var components = URLComponents(string:
            "https://aerodatabox.p.rapidapi.com/flights/number/\(flightNumber)/\(dateString)")!
        components.queryItems = [
            URLQueryItem(name: "withAircraftImage", value: "false"),
            URLQueryItem(name: "withLocation",      value: "false")
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("aerodatabox.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey,                    forHTTPHeaderField: "x-rapidapi-key")
        request.timeoutInterval = 12

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw FlightStatusError.network(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw FlightStatusError.network(URLError(.badServerResponse))
        }
        if http.statusCode == 204 || http.statusCode == 404 {
            throw FlightStatusError.notFound
        }
        guard (200..<300).contains(http.statusCode) else {
            throw FlightStatusError.network(URLError(.init(rawValue: http.statusCode)))
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let raw = try decoder.decode([AeroFlight].self, from: data)
            guard let first = raw.first else { throw FlightStatusError.notFound }
            return first.toLiveStatus(flightNumber: flightNumber, fetchedAt: Date())
        } catch let e as FlightStatusError {
            throw e
        } catch {
            throw FlightStatusError.decoding(error)
        }
    }
}

// MARK: - AeroDataBox wire format (subset)

private struct AeroFlight: Decodable {
    let number: String?
    let status: String?
    let departure: Movement
    let arrival: Movement
    let aircraft: Aircraft?
    let airline: Airline?

    struct Movement: Decodable {
        let airport: AirportInfo
        let scheduledTime: TimePair?
        let revisedTime: TimePair?
        let runwayTime: TimePair?
        let actualTime: TimePair?
        let terminal: String?
        let gate: String?
        let baggageBelt: String?
    }
    struct TimePair: Decodable { let utc: String?; let local: String? }
    struct AirportInfo: Decodable {
        let iata: String?
        let name: String?
        let timeZone: String?
        let location: Location?
        struct Location: Decodable { let lat: Double; let lon: Double }
    }
    struct Aircraft: Decodable { let reg: String?; let model: String? }
    struct Airline: Decodable { let iata: String?; let name: String? }

    func toLiveStatus(flightNumber: String, fetchedAt: Date) -> FlightLiveStatus {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        func parse(_ t: TimePair?) -> Date? {
            guard let utc = t?.utc else { return nil }
            // AeroDataBox format: "2026-04-13 00:05Z" — not strict ISO. Normalize.
            let cleaned = utc.replacingOccurrences(of: " ", with: "T")
            return iso.date(from: cleaned)
        }

        let schedDep = parse(departure.scheduledTime) ?? Date()
        let schedArr = parse(arrival.scheduledTime)   ?? schedDep.addingTimeInterval(3600)

        let liveStatus: LiveStatus = {
            switch status?.lowercased() {
            case "expected": return .scheduled
            case "checkin":  return .checkIn
            case "boarding": return .boarding
            case "gateclosed": return .gateClosed
            case "departed": return .departed
            case "enroute":  return .enRoute
            case "approaching": return .approaching
            case "landed":   return .landed
            case "arrived":  return .arrived
            case "delayed":  return .delayed
            case "canceled", "cancelled": return .cancelled
            case "diverted": return .diverted
            default:         return .unknown
            }
        }()

        return FlightLiveStatus(
            flightNumber: flightNumber,
            airlineIATA: airline?.iata ?? "JL",
            originIATA: departure.airport.iata ?? "???",
            originCity: departure.airport.name ?? "—",
            originTimezone: departure.airport.timeZone ?? "UTC",
            originLat: departure.airport.location?.lat ?? 0,
            originLon: departure.airport.location?.lon ?? 0,
            destinationIATA: arrival.airport.iata ?? "???",
            destinationCity: arrival.airport.name ?? "—",
            destinationTimezone: arrival.airport.timeZone ?? "UTC",
            destinationLat: arrival.airport.location?.lat ?? 0,
            destinationLon: arrival.airport.location?.lon ?? 0,
            scheduledDeparture: schedDep,
            estimatedDeparture: parse(departure.revisedTime),
            actualDeparture: parse(departure.actualTime) ?? parse(departure.runwayTime),
            scheduledArrival: schedArr,
            estimatedArrival: parse(arrival.revisedTime),
            actualArrival: parse(arrival.actualTime) ?? parse(arrival.runwayTime),
            departureGate: departure.gate,
            departureTerminal: departure.terminal,
            arrivalGate: arrival.gate,
            arrivalTerminal: arrival.terminal,
            baggageBelt: arrival.baggageBelt,
            aircraftModel: aircraft?.model,
            aircraftReg: aircraft?.reg,
            status: liveStatus,
            lastFetched: fetchedAt
        )
    }
}
