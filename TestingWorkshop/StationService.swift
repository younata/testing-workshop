//
//  StationService.swift
//  TestingWorkshop
//

import Foundation

struct Station: Equatable, Hashable, Identifiable {
    var id: String { name }
    let name: String
    let platforms: [String]
}

struct Departure: Codable, Equatable, Identifiable {
    let id: Int
    let line: String
    let platform: String
    let etd: Date
}

protocol StationService {
    func stations() async throws -> [Station]
    func departures(for: Station) async throws -> [Departure]
}

struct StationNotFoundError: Error {
    let stationName: String
}

// I'm not writing an actual backend service.
struct DefaultStationService: StationService {
    // These are some of the BART stations with shorter names.
    private var stationMap: [Station: [Departure]] {
        [
            Station(name: "Colma", platforms: ["1", "2"]): [
                Departure(id: 1, line: "Red", platform: "1", etd: Date(timeIntervalSinceNow: 300)),
                Departure(id: 2, line: "Red", platform: "2", etd: Date(timeIntervalSinceNow: 600)),
                Departure(id: 3, line: "Yellow", platform: "1", etd: Date(timeIntervalSinceNow: 900)),
                Departure(id: 4, line: "Yellow", platform: "2", etd: Date(timeIntervalSinceNow: 1200)),
            ],
            Station(name: "Powell", platforms: ["1", "2"]): [
                Departure(id: 1, line: "Red", platform: "1", etd: Date(timeIntervalSinceNow: 60)),
                Departure(id: 2, line: "Red", platform: "2", etd: Date(timeIntervalSinceNow: 120)),
                Departure(id: 3, line: "Yellow", platform: "1", etd: Date(timeIntervalSinceNow: 240)),
                Departure(id: 4, line: "Yellow", platform: "2", etd: Date(timeIntervalSinceNow: 840)),
                Departure(id: 5, line: "Blue", platform: "1", etd: Date(timeIntervalSinceNow: 600)),
                Departure(id: 6, line: "Blue", platform: "2", etd: Date(timeIntervalSinceNow: 780)),
                Departure(id: 7, line: "Green", platform: "1", etd: Date(timeIntervalSinceNow: 900)),
                Departure(id: 8, line: "Green", platform: "2", etd: Date(timeIntervalSinceNow: 540)),
            ],
            Station(name: "MacArthur", platforms: ["1", "2", "3", "4"]): [
                Departure(id: 1, line: "Red", platform: "1", etd: Date(timeIntervalSinceNow: 180)),
                Departure(id: 2, line: "Red", platform: "3", etd: Date(timeIntervalSinceNow: 600)),
                Departure(id: 3, line: "Yellow", platform: "2", etd: Date(timeIntervalSinceNow: 480)),
                Departure(id: 4, line: "Yellow", platform: "4", etd: Date(timeIntervalSinceNow: 1200)),
                Departure(id: 5, line: "Orange", platform: "1", etd: Date(timeIntervalSinceNow: 300)),
                Departure(id: 6, line: "Orange", platform: "3", etd: Date(timeIntervalSinceNow: 900)),
            ],
            Station(name: "12th Street", platforms: ["1", "2", "3"]): [
                Departure(id: 1, line: "Red", platform: "1", etd: Date(timeIntervalSinceNow: 180)),
                Departure(id: 2, line: "Red", platform: "3", etd: Date(timeIntervalSinceNow: 600)),
                Departure(id: 3, line: "Yellow", platform: "2", etd: Date(timeIntervalSinceNow: 480)),
                Departure(id: 4, line: "Yellow", platform: "3", etd: Date(timeIntervalSinceNow: 1200)),
                Departure(id: 5, line: "Orange", platform: "1", etd: Date(timeIntervalSinceNow: 60)),
                Departure(id: 6, line: "Orange", platform: "3", etd: Date(timeIntervalSinceNow: 420)),
            ],
            Station(name: "Ashby", platforms: ["1", "2"]): [
                Departure(id: 1, line: "Red", platform: "1", etd: Date(timeIntervalSinceNow: 180)),
                Departure(id: 2, line: "Red", platform: "3", etd: Date(timeIntervalSinceNow: 600)),
                Departure(id: 3, line: "Orange", platform: "1", etd: Date(timeIntervalSinceNow: 120)),
                Departure(id: 4, line: "Orange", platform: "3", etd: Date(timeIntervalSinceNow: 360)),
            ],
        ]
    }

    func stations() async throws -> [Station] {
        Array(stationMap.keys)
    }

    func departures(for station: Station) async throws -> [Departure] {
        guard let departures = stationMap[station] else {
            throw StationNotFoundError(stationName: station.name)
        }
        return departures
    }
}
