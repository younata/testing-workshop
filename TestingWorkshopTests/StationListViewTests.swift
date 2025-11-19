//
//  StationListViewTest.swift
//  TestingWorkshopTests
//

import Fakes
import SwiftUI
@_spi(Experimental) import Testing
import ViewInspector
@testable import TestingWorkshop

private let stationDetailFactory: StationDetailCoordinatorFactory = { StationDetailCoordinator(station: $0, stationService: FakeStationService()) }

struct StationListViewTests {
    @MainActor
    struct `Before loading` {
        @Test func `shows a spinner`() throws {
            let subject = StationListCoordinator(stationRepository: FakeStationRepository(), stationDetailFactory: stationDetailFactory).makeView()

            let inspectedView = try subject.inspect()

            // This would throw if the spinner isn't found.
            #expect(throws: Never.self) {
                _ = try inspectedView.find(ViewType.ProgressView.self)
            }
        }

        @Test func `requests list of stations`() async throws {
            let stationRepository = FakeStationRepository()
            let subject = StationListCoordinator(stationRepository: stationRepository, stationDetailFactory: stationDetailFactory).makeView()

            let task = Task {
                try await subject.inspect().zStack().callTask()
            }

            defer {
                task.cancel()
            }

            try await confirmation(until: .firstPass) {
                stationRepository.stations_spy.wasCalled
            }
        }
    }

    @MainActor
    struct `After successfully loading data` {
        @Test func `shows the list of stations`() async throws {
            let stationRepository = FakeStationRepository()
            stationRepository.stations_spy.stub(success: [
                Station(name: "Station 1", platforms: ["a", "b"]),
                Station(name: "Station 2", platforms: ["a", "b"])
            ])

            let subject = StationListCoordinator(stationRepository: stationRepository, stationDetailFactory: stationDetailFactory).makeView()

            let inspectedView = try subject.inspect()
            try await inspectedView.zStack().callTask()

            #expect(throws: Never.self) {
                _ = try inspectedView.find(text: "Station 1")
                _ = try inspectedView.find(text: "Station 2")
            }
        }

        @Test func `tapping on a station opens the detail view`() async throws {
            let stationRepository = FakeStationRepository()
            stationRepository.stations_spy.stub(success: [
                Station(name: "Station 1", platforms: ["a", "b"]),
                Station(name: "Station 2", platforms: ["a", "b"])
            ])

            let inspectedView = try NavigationStack {
                StationListCoordinator(stationRepository: stationRepository, stationDetailFactory: stationDetailFactory).makeView()
            }.inspect()

            try await inspectedView.find(StationListView.self).zStack().callTask()

            let link = try inspectedView.find(navigationLink: "Station 1")

            // This would throw if the link didn't host the StationDetailView
            let detailView = try link.view(StationDetailView.self)
            #expect(try detailView.actualView().coordinator.station == Station(name: "Station 1", platforms: ["a", "b"]))
        }

        @Test func `using pull to refresh will refresh the repository`() async throws {
            let stationRepository = FakeStationRepository()
            stationRepository.stations_spy.stub(success: [
                Station(name: "Station 1", platforms: ["a", "b"]),
                Station(name: "Station 2", platforms: ["a", "b"])
            ])

            let subject = StationListCoordinator(stationRepository: stationRepository, stationDetailFactory: stationDetailFactory).makeView()

            let inspectedView = try subject.inspect()
            try await inspectedView.zStack().callTask()

            let list = try inspectedView.zStack().find(ViewType.List.self)

            // Act
            let task = Task {
                try await list.callRefreshable()
            }

            // Assert
            try await confirmation(until: .firstPass) {
                stationRepository.refresh_spy.wasCalled
            }
        }

        @Test func `when refreshing the repository succeeds, it shows the updated stations`() async throws {
            // Arrange
            let stationRepository = FakeStationRepository()
            stationRepository.stations_spy.stub(success: [
                Station(name: "Station 1", platforms: ["a", "b"]),
                Station(name: "Station 2", platforms: ["a", "b"])
            ])

            let subject = StationListCoordinator(stationRepository: stationRepository, stationDetailFactory: stationDetailFactory).makeView()

            let inspectedView = try subject.inspect()
            try await inspectedView.zStack().callTask()

            let list = try inspectedView.zStack().find(ViewType.List.self)

            stationRepository.refresh_spy.stub(success: [
                Station(name: "Station 3", platforms: ["c", "d"]),
                Station(name: "Station 4", platforms: ["c", "d"])
            ])

            // Act
            try await list.callRefreshable()

            // Assert
            #expect(throws: Never.self) {
                _ = try inspectedView.find(text: "Station 3")
                _ = try inspectedView.find(text: "Station 4")
            }
        }

        @Test func `when refreshing the repository fails, it shows the old stations without showing an error`() async throws {
            // Arrange
            let stationRepository = FakeStationRepository()
            stationRepository.stations_spy.stub(success: [
                Station(name: "Station 1", platforms: ["a", "b"]),
                Station(name: "Station 2", platforms: ["a", "b"])
            ])

            let subject = StationListCoordinator(stationRepository: stationRepository, stationDetailFactory: stationDetailFactory).makeView()

            let inspectedView = try subject.inspect()
            try await inspectedView.zStack().callTask()

            let list = try inspectedView.zStack().find(ViewType.List.self)

            stationRepository.refresh_spy.stub(failure: TestError())

            // Act
            try await list.callRefreshable()

            // Assert
            #expect(throws: Never.self) {
                _ = try inspectedView.find(text: "Station 1")
                _ = try inspectedView.find(text: "Station 2")
            }

            // It does not show the error
            #expect(throws: InspectionError.self) {
                _ = try inspectedView.find(text: "Unable to load stations")
            }
            #expect(throws: InspectionError.self) {
                _ = try inspectedView.find(button: "Retry?")
            }
        }
    }

    @MainActor
    struct `When loading throws an error` {
        @Test func `shows error message and retry button`() async throws {
            let stationRepository = FakeStationRepository()
            stationRepository.stations_spy.stub(failure: TestError())

            let subject = StationListCoordinator(stationRepository: stationRepository, stationDetailFactory: stationDetailFactory).makeView()

            let inspectedView = try subject.inspect()
            try await inspectedView.zStack().callTask()

            #expect(throws: Never.self) {
                _ = try inspectedView.find(text: "Unable to load stations")
                _ = try inspectedView.find(button: "Retry?")
            }
        }

        @Test func `tapping retry attempts to fetch the stations again`() async throws {
            let stationRepository = FakeStationRepository()
            stationRepository.stations_spy.stub(failure: TestError())

            let subject = StationListCoordinator(stationRepository: stationRepository, stationDetailFactory: stationDetailFactory).makeView()

            let inspectedView = try subject.inspect()
            try await inspectedView.zStack().callTask()

            // reset the station service.
            stationRepository.stations_spy.clearCalls()
            stationRepository.stations_spy.stub(pendingFailure: TestError())

            try inspectedView.find(button: "Retry?").tap()

            try await confirmation(until: .firstPass) {
                stationRepository.stations_spy.wasCalled
            }
        }

        @Test func `tapping retry shows a spinner again`() async throws {
            let stationRepository = FakeStationRepository()
            stationRepository.stations_spy.stub(failure: TestError())

            let subject = StationListCoordinator(stationRepository: stationRepository, stationDetailFactory: stationDetailFactory).makeView()

            let inspectedView = try subject.inspect()
            try await inspectedView.zStack().callTask()

            // reset the station service.
            stationRepository.stations_spy.clearCalls()
            stationRepository.stations_spy.stub(pendingFailure: TestError())

            try inspectedView.find(button: "Retry?").tap()

            #expect(throws: Never.self) {
                _ = try inspectedView.find(ViewType.ProgressView.self)
            }
        }
    }
}
