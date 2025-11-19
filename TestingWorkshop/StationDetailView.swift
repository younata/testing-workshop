//
//  StationDetailView.swift
//  TestingWorkshop
//

import Observation
import SwiftUI

struct Platform: Identifiable, Hashable {
    var id: String { name }
    let name: String
}

typealias StationDetailCoordinatorFactory = @MainActor (Station) -> StationDetailCoordinator

@MainActor
@Observable
final class StationDetailCoordinator {
    let station: Station
    let stationService: StationService

    var state: CoordinatorState<[Departure]> = .loading

    init(station: Station, stationService: StationService) {
        self.station = station
        self.stationService = stationService
    }

    func makeView() -> some View {
        StationDetailView(coordinator: self)
    }

    func start() async {
        do {
            let departures = try await stationService.departures(for: station)
            self.state = .loaded(departures)// .loaded(process(departures: departures))
        } catch {
            self.state = .error
        }
    }

    func retry() {
        self.state = .loading
        Task {
            await self.start()
        }
    }

    private func process(departures: [Departure]) -> [(platform: Platform, departures: [Departure])] {
        return station.platforms.map { platform in
            return (Platform(name: platform), departures.filter { $0.platform == platform })
        }
    }

}

struct StationDetailView: View {
    let coordinator: StationDetailCoordinator

    var body: some View {
        ZStack {
            switch coordinator.state {
            case .loading:
                ProgressView()
            case .loaded(let departures):
                List(departures) { departure in
                    DepartureCell(departure: departure)
                }
                .listStyle(.plain)
            case .error:
                ErrorView(title: "Unable to load departures") {
                    coordinator.retry()
                }
                Text("not handled")
            }
        }
        .navigationTitle(coordinator.station.name)
        .task {
            await coordinator.start()
        }
    }
}

struct DepartureCell: View {
    let departure: Departure

    var body: some View {
        VStack(alignment: .leading) {
            Text("Line: \(departure.line)")
            Text("Platform: \(departure.platform)")
            Text(departure.etd, style: .relative)
        }
    }
}
