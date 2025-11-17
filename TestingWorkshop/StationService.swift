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

struct Departure: Codable, Equatable {
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
                Departure(line: "Red", platform: "1", etd: Date(timeIntervalSinceNow: 300)),
                Departure(line: "Red", platform: "2", etd: Date(timeIntervalSinceNow: 600)),
                Departure(line: "Yellow", platform: "1", etd: Date(timeIntervalSinceNow: 900)),
                Departure(line: "Yellow", platform: "2", etd: Date(timeIntervalSinceNow: 1200)),
            ],
            Station(name: "Powell", platforms: ["1", "2"]): [
                Departure(line: "Red", platform: "1", etd: Date(timeIntervalSinceNow: 60)),
                Departure(line: "Red", platform: "2", etd: Date(timeIntervalSinceNow: 120)),
                Departure(line: "Yellow", platform: "1", etd: Date(timeIntervalSinceNow: 240)),
                Departure(line: "Yellow", platform: "2", etd: Date(timeIntervalSinceNow: 840)),
                Departure(line: "Blue", platform: "1", etd: Date(timeIntervalSinceNow: 600)),
                Departure(line: "Blue", platform: "2", etd: Date(timeIntervalSinceNow: 780)),
                Departure(line: "Green", platform: "1", etd: Date(timeIntervalSinceNow: 900)),
                Departure(line: "Green", platform: "2", etd: Date(timeIntervalSinceNow: 540)),
            ],
            Station(name: "MacArthur", platforms: ["1", "2", "3", "4"]): [
                Departure(line: "Red", platform: "1", etd: Date(timeIntervalSinceNow: 180)),
                Departure(line: "Red", platform: "3", etd: Date(timeIntervalSinceNow: 600)),
                Departure(line: "Yellow", platform: "2", etd: Date(timeIntervalSinceNow: 480)),
                Departure(line: "Yellow", platform: "4", etd: Date(timeIntervalSinceNow: 1200)),
                Departure(line: "Orange", platform: "1", etd: Date(timeIntervalSinceNow: 300)),
                Departure(line: "Orange", platform: "3", etd: Date(timeIntervalSinceNow: 900)),
            ],
            Station(name: "12th Street", platforms: ["1", "2", "3"]): [
                Departure(line: "Red", platform: "1", etd: Date(timeIntervalSinceNow: 180)),
                Departure(line: "Red", platform: "3", etd: Date(timeIntervalSinceNow: 600)),
                Departure(line: "Yellow", platform: "2", etd: Date(timeIntervalSinceNow: 480)),
                Departure(line: "Yellow", platform: "3", etd: Date(timeIntervalSinceNow: 1200)),
                Departure(line: "Orange", platform: "1", etd: Date(timeIntervalSinceNow: 60)),
                Departure(line: "Orange", platform: "3", etd: Date(timeIntervalSinceNow: 420)),
            ],
            Station(name: "Ashby", platforms: ["1", "2"]): [
                Departure(line: "Red", platform: "1", etd: Date(timeIntervalSinceNow: 180)),
                Departure(line: "Red", platform: "3", etd: Date(timeIntervalSinceNow: 600)),
                Departure(line: "Orange", platform: "1", etd: Date(timeIntervalSinceNow: 120)),
                Departure(line: "Orange", platform: "3", etd: Date(timeIntervalSinceNow: 360)),
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
