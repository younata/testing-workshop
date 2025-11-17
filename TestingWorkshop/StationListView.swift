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

    func makeView() -> some View {
        StationListView(coordinator: self)
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

    func detailView(for station: Station) -> some View {
        StationDetailCoordinator(station: station, stationService: stationService).makeView()
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
                    NavigationLink {
                        coordinator.detailView(for: station)
                    } label: {
                        Text(verbatim: station.name)
                    }

                }
                .listStyle(.plain)
            case .error:
                ErrorView(title: "Unable to load stations") {
                    coordinator.retry()
                }
            }
        }
        .task {
            await coordinator.start()
        }
    }
}

struct ErrorView: View {
    let title: LocalizedStringKey
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
            Button("Retry?", action: onRetry)
        }
    }
}
