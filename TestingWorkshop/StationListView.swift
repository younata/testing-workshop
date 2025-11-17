//
//  StationListView.swift
//  TestingWorkshop
//

import Observation
import SwiftUI

enum CoordinatorState<T> {
    case loading
    case loaded(T)
    case error
}

@MainActor
@Observable
final class StationListCoordinator {
    let stationService: StationService
    private(set) var state: CoordinatorState<[Station]> = .loading

    init(stationService: StationService) {
        self.stationService = stationService
    }

    func start() async {
        do {
            self.state = .loaded(
                try await stationService.stations()
            )
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
}

struct StationListView: View {
    let coordinator: StationListCoordinator

    var body: some View {
        ZStack {
            switch coordinator.state {
            case .loading:
                ProgressView()
            case .loaded(let stations):
                List(stations) { station in
                    Text(verbatim: station.name)
                }
            case .error:
                VStack(alignment: .center, spacing: 8) {
                    Text("Unable to load stations")
                    Button("Retry?") {
                        coordinator.retry()
                    }
                }
            }
        }
        .task {
            await coordinator.start()
        }
    }
}
