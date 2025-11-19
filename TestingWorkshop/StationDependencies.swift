//
//  StationDependencies.swift
//  TestingWorkshop
//

import Foundation

// A very simple approach to providing dependencies that solves the transitive dependency problem.
struct StationDependencies {
    let service: StationService
    let repository: StationRepository

    init() {
        service = DefaultStationService()
        repository = ActualStationRepository(stationService: service)
    }

    @MainActor
    func stationListCoordinator() -> StationListCoordinator {
        StationListCoordinator(stationRepository: repository, stationDetailFactory: stationDetailCoordinator)
    }

    @MainActor
    func stationDetailCoordinator(_ station: Station) -> StationDetailCoordinator {
        StationDetailCoordinator(station: station, stationService: service)
    }
}
