//
//  FakeStationService.swift
//  TestingWorkshop
//

import Fakes
@testable import TestingWorkshop

struct FakeStationService: StationService {
    let station_spy = ThrowingPendableSpy<Void, [Station], Swift.Error>()
    func stations() async throws -> [Station] {
        try await station_spy()
    }

    let departures_spy = ThrowingPendableSpy<Station, [Departure], Swift.Error>()
    func departures(for station: Station) async throws -> [Departure] {
        try await departures_spy(station)
    }
}
