import Foundation

enum Airports {
    static let HND = Airport(code: "HND", city: "Tokyo", name: "Haneda",
                             country: "Japan", timezone: "Asia/Tokyo",
                             latitude: 35.5494, longitude: 139.7798)
    static let NRT = Airport(code: "NRT", city: "Tokyo", name: "Narita",
                             country: "Japan", timezone: "Asia/Tokyo",
                             latitude: 35.7720, longitude: 140.3929)
    static let SFO = Airport(code: "SFO", city: "San Francisco", name: "SFO Intl",
                             country: "USA", timezone: "America/Los_Angeles",
                             latitude: 37.6213, longitude: -122.3790)
    static let JFK = Airport(code: "JFK", city: "New York", name: "JFK Intl",
                             country: "USA", timezone: "America/New_York",
                             latitude: 40.6413, longitude: -73.7781)
    static let ITM = Airport(code: "ITM", city: "Osaka", name: "Itami",
                             country: "Japan", timezone: "Asia/Tokyo",
                             latitude: 34.7855, longitude: 135.4382)
    static let CTS = Airport(code: "CTS", city: "Sapporo", name: "New Chitose",
                             country: "Japan", timezone: "Asia/Tokyo",
                             latitude: 42.7752, longitude: 141.6923)
}

enum MockData {

    private static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int, tz: String) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = h; c.minute = min
        c.timeZone = TimeZone(identifier: tz)
        return Calendar(identifier: .gregorian).date(from: c) ?? Date()
    }

    /// The hero flight — JL2, JFK → HND (real JAL routing).
    static let nextFlight: Flight = Flight(
        id: "f-jl2",
        number: "JL2",
        origin: Airports.JFK,
        destination: Airports.HND,
        scheduledDeparture: date(2026, 4, 13, 13, 25, tz: "America/New_York"),
        scheduledArrival:   date(2026, 4, 14, 17, 55, tz: "Asia/Tokyo"),
        actualDeparture: nil,
        actualArrival: nil,
        aircraft: "Boeing 777-300ER",
        aircraftReg: "JA738J",
        gate: "7",
        terminal: "1",
        seat: "7K",
        cabin: "Business · SKY SUITE III",
        bookingClass: "J",
        status: .checkInOpen,
        distanceKm: 8_277,
        onTimeProbability: 0.92,
        baggageClaim: nil,
        mealService: [
            "Welcome drink · Champagne",
            "Kaiseki dinner — sakizuke, owan, mukouzuke, yakimono",
            "Light meal before arrival — Yoshoku beef stew"
        ],
        entertainmentHours: 9
    )

    static let returnFlight: Flight = Flight(
        id: "f-jl1",
        number: "JL1",
        origin: Airports.HND,
        destination: Airports.JFK,
        scheduledDeparture: date(2026, 4, 20, 11, 5, tz: "Asia/Tokyo"),
        scheduledArrival:   date(2026, 4, 20, 10, 50, tz: "America/New_York"),
        actualDeparture: nil,
        actualArrival: nil,
        aircraft: "Boeing 777-300ER",
        aircraftReg: "JA743J",
        gate: "141",
        terminal: "3",
        seat: "4A",
        cabin: "Business · SKY SUITE",
        bookingClass: "J",
        status: .scheduled,
        distanceKm: 8_277,
        onTimeProbability: 0.88,
        baggageClaim: nil,
        mealService: [
            "Welcome drink · JAL original cocktail",
            "Washoku — kaiseki",
            "Bowl of Air Series · Beef Hayashi rice"
        ],
        entertainmentHours: 11
    )

    static let domesticFlight: Flight = Flight(
        id: "f-jl505",
        number: "JL505",
        origin: Airports.HND,
        destination: Airports.CTS,
        scheduledDeparture: date(2026, 5, 3, 8, 0, tz: "Asia/Tokyo"),
        scheduledArrival:   date(2026, 5, 3, 9, 35, tz: "Asia/Tokyo"),
        actualDeparture: nil, actualArrival: nil,
        aircraft: "Airbus A350-900",
        aircraftReg: "JA08XJ",
        gate: "62",
        terminal: "1",
        seat: "12A",
        cabin: "Class J",
        bookingClass: "C",
        status: .scheduled,
        distanceKm: 821,
        onTimeProbability: 0.95,
        baggageClaim: nil,
        mealService: ["Soup & beverage service"],
        entertainmentHours: 0
    )

    static let pastFlight: Flight = Flight(
        id: "f-jl60",
        number: "JL60",
        origin: Airports.SFO,
        destination: Airports.HND,
        scheduledDeparture: date(2026, 2, 14, 22, 10, tz: "America/Los_Angeles"),
        scheduledArrival:   date(2026, 2, 16, 5, 35, tz: "Asia/Tokyo"),
        actualDeparture:    date(2026, 2, 14, 22, 22, tz: "America/Los_Angeles"),
        actualArrival:      date(2026, 2, 16, 5, 28, tz: "Asia/Tokyo"),
        aircraft: "Boeing 787-9",
        aircraftReg: "JA873J",
        gate: "A6", terminal: "I",
        seat: "8K",
        cabin: "Business · SKY SUITE III",
        bookingClass: "J",
        status: .landed,
        distanceKm: 8_277,
        onTimeProbability: 1.0,
        baggageClaim: "5",
        mealService: [],
        entertainmentHours: 11
    )

    static let trips: [Trip] = [
        Trip(
            id: "t1",
            confirmationCode: "X92K7P",
            passengerName: "DAICHI YAMASHITA",
            flights: [nextFlight, returnFlight]
        ),
        Trip(
            id: "t2",
            confirmationCode: "B47QM2",
            passengerName: "DAICHI YAMASHITA",
            flights: [domesticFlight]
        ),
        Trip(
            id: "t3",
            confirmationCode: "K10WX9",
            passengerName: "DAICHI YAMASHITA",
            flights: [pastFlight]
        )
    ]

    static let boardingPass = BoardingPass(
        id: "bp-jl2-7k",
        flight: nextFlight,
        passengerName: "YAMASHITA/DAICHI MR",
        sequence: "027",
        group: "1",
        ffNumber: "JL 1 003 4567",
        tsa: "TSA Pre ✓",
        qrPayload: "M1YAMASHITA/DAICHI    EJL2JFKHNDJL 0002 103Y007K0027 100"
    )

    static let profile = JMBProfile(
        name: "Daichi Yamashita",
        memberNumber: "JL 1 003 4567",
        tier: "JMB Diamond",
        miles: 184_320,
        flyOnPoints: 118_450,
        flightsYTD: 42,
        segmentsYTD: 58,
        nextTier: nil,
        milesToNextTier: nil
    )
}
