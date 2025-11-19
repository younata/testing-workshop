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

typealias StationListCoordinatorFactory = @MainActor () -> StationListCoordinator

@MainActor
@Observable
final class StationListCoordinator {
    let stationRepository: StationRepository
    let stationDetailFactory: StationDetailCoordinatorFactory
    private(set) var state: CoordinatorState<[Station]> = .loading

    init(stationRepository: StationRepository, stationDetailFactory: @escaping StationDetailCoordinatorFactory) {
        self.stationRepository = stationRepository
        self.stationDetailFactory = stationDetailFactory
    }

    func makeView() -> some View {
        StationListView(coordinator: self)
    }

    func start() async {
        do {
            self.state = .loaded(
                try await stationRepository.stations()
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

    func refresh() async {
        do {
            state = .loaded(
                try await stationRepository.refresh()
            )
        } catch {}
    }

    func detailView(for station: Station) -> some View {
        stationDetailFactory(station).makeView()
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
                .refreshable {
                    await coordinator.refresh()
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
