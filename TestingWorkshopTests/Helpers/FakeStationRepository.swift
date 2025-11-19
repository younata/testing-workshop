//
//  FakeStationRepository.swift
//  TestingWorkshopTests
//

import Fakes
@testable import TestingWorkshop

struct FakeStationRepository: StationRepository {
    let stations_spy = ThrowingPendableSpy<Void, [Station], Swift.Error>()
    func stations() async throws -> [Station] {
        try await stations_spy()
    }

    let refresh_spy = ThrowingPendableSpy<Void, [Station], Swift.Error>()
    func refresh() async throws -> [Station] {
        try await refresh_spy()
    }
}
