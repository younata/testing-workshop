//
//  StationListViewTest.swift
//  TestingWorkshopTests
//

import Fakes
import SwiftUI
@_spi(Experimental) import Testing
import ViewInspector
@testable import TestingWorkshop

struct StationListViewTests {
    @MainActor
    struct `Before loading` {
        @Test func `shows a spinner`() throws {
            let subject = StationListView(coordinator: StationListCoordinator(stationService: FakeStationService()))

            let inspectedView = try subject.inspect()

            // This would throw if the spinner isn't found.
            _ = try inspectedView.find(ViewType.ProgressView.self)
        }

        @Test func `requests list of stations`() async throws {
            let stationService = FakeStationService()
            let subject = StationListView(coordinator: StationListCoordinator(stationService: stationService))

            let task = Task {
                try await subject.inspect().zStack().callTask()
            }

            defer {
                task.cancel()
            }

            try await confirmation(until: .firstPass) {
                stationService.station_spy.wasCalled
            }
        }
    }

    @MainActor
    struct `After successfully loading data` {
        @Test func `shows the list of stations`() async throws {
            let stationService = FakeStationService()
            stationService.station_spy.stub(success: [
                Station(name: "Station 1", platforms: ["a", "b"]),
                Station(name: "Station 2", platforms: ["a", "b"])
            ])

            let subject = StationListView(coordinator: StationListCoordinator(stationService: stationService))

            let inspectedView = try subject.inspect()
            try await inspectedView.zStack().callTask()

            // These would throw if the text isn't found.
            _ = try inspectedView.find(text: "Station 1")
            _ = try inspectedView.find(text: "Station 2")
        }

        @Test func `tapping on a station opens the detail view`() async throws {
            let stationService = FakeStationService()
            stationService.station_spy.stub(success: [
                Station(name: "Station 1", platforms: ["a", "b"]),
                Station(name: "Station 2", platforms: ["a", "b"])
            ])

            let inspectedView = try NavigationStack { StationListView(coordinator: StationListCoordinator(stationService: stationService)) }.inspect()


            try await inspectedView.find(StationListView.self).zStack().callTask()

            let link = try inspectedView.find(navigationLink: "Station 1")

            // This would throw if the link didn't host the StationDetailView
            let detailView = try link.view(StationDetailView.self)
            #expect(try detailView.actualView().coordinator.station == Station(name: "Station 1", platforms: ["a", "b"]))
        }
    }

    @MainActor
    struct `When loading throws an error` {
        struct TestError: Error {
            var localizedDescription: String {
                "Test Error"
            }
        }

        @Test func `shows error message and retry button`() async throws {
            let stationService = FakeStationService()
            stationService.station_spy.stub(failure: TestError())

            let subject = StationListView(coordinator: StationListCoordinator(stationService: stationService))

            let inspectedView = try subject.inspect()
            try await inspectedView.zStack().callTask()

            _ = try inspectedView.find(text: "Unable to load stations")
            _ = try inspectedView.find(button: "Retry?")
        }

        @Test func `tapping retry attempts to fetch the stations again`() async throws {
            let stationService = FakeStationService()
            stationService.station_spy.stub(failure: TestError())

            let subject = StationListView(coordinator: StationListCoordinator(stationService: stationService))

            let inspectedView = try subject.inspect()
            try await inspectedView.zStack().callTask()

            // reset the station service.
            stationService.station_spy.clearCalls()
            stationService.station_spy.stub(pendingFailure: TestError())

            try inspectedView.find(button: "Retry?").tap()

            try await confirmation(until: .firstPass) {
                stationService.station_spy.wasCalled
            }
        }

        @Test func `tapping retry shows a spinner again`() async throws {
            let stationService = FakeStationService()
            stationService.station_spy.stub(failure: TestError())

            let subject = StationListView(coordinator: StationListCoordinator(stationService: stationService))

            let inspectedView = try subject.inspect()
            try await inspectedView.zStack().callTask()

            // reset the station service.
            stationService.station_spy.clearCalls()
            stationService.station_spy.stub(pendingFailure: TestError())

            try inspectedView.find(button: "Retry?").tap()

            _ = try inspectedView.find(ViewType.ProgressView.self)
        }
    }
}
