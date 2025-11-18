//
//  StationDetailViewTests.swift
//  TestingWorkshop
//

import Fakes
import SwiftUI
@_spi(Experimental) import Testing
import ViewInspector
@testable import TestingWorkshop

struct StationDetailViewTests {
    @MainActor struct `Before loading` {
        let station = Station(name: "My Station", platforms: ["a", "b"])
        @Test(.disabled("inspecting navigation title with a non-Binding<String> is not yet supported in ViewInspector")) func `shows the station name as the nav title`() throws {
            let subject = try StationDetailCoordinator(
                station: station,
                stationService: FakeStationService()
            ).makeView().inspect()

            #expect(try subject.navigationTitle() == "My Station")
        }

        @Test func `shows a spinner`() throws {
            let subject = try StationDetailCoordinator(
                station: station,
                stationService: FakeStationService()
            ).makeView().inspect()

            // This would throw if the spinner isn't found.
            #expect(throws: Never.self) {
                _ = try subject.find(ViewType.ProgressView.self)
            }
        }

        @Test func `requests the departures for the station`() async throws {
            let stationService = FakeStationService()
            let subject = try StationDetailCoordinator(
                station: station,
                stationService: stationService
            ).makeView().inspect()

            try await subject.zStack().callTask()

            // these are the actual assertions
            try await confirmation(until: .firstPass) {
                stationService.departures_spy.wasCalled(with: station)
            }
        }
    }

    @MainActor struct `After successfully loading data` {
        let station = Station(name: "My Station", platforms: ["a", "b"])
        let stationService = FakeStationService()

        @Test func `shows the station departures`() async throws {
            stationService.departures_spy.stub(success: [
                Departure(id: 1, line: "Red", platform: "1", etd: Date(timeIntervalSinceNow: 300)),
                Departure(id: 2, line: "Red", platform: "2", etd: Date(timeIntervalSinceNow: 600)),
                Departure(id: 3, line: "Yellow", platform: "1", etd: Date(timeIntervalSinceNow: 900)),
                Departure(id: 4, line: "Yellow", platform: "2", etd: Date(timeIntervalSinceNow: 1200)),
            ])

            let subject = try StationDetailCoordinator(
                station: station,
                stationService: stationService
            ).makeView().inspect()

            try await subject.zStack().callTask()

            #expect(throws: Never.self) {
                let cell1 = try subject.find(DepartureCell.self, where: { try $0.actualView().departure.id == 1 })
                _ = try cell1.find(text: "Line: Red")
                _ = try cell1.find(text: "Platform: 1")
                // Checking the date isn't supported in view inspector, as far as I can tell?

                let cell2 = try subject.find(DepartureCell.self, where: { try $0.actualView().departure.id == 2 })
                _ = try cell2.find(text: "Line: Red")
                _ = try cell2.find(text: "Platform: 2")
                // Checking the date isn't supported in view inspector, as far as I can tell?

                let cell3 = try subject.find(DepartureCell.self, where: { try $0.actualView().departure.id == 3 })
                _ = try cell3.find(text: "Line: Yellow")
                _ = try cell3.find(text: "Platform: 1")
                // Checking the date isn't supported in view inspector, as far as I can tell?

                let cell4 = try subject.find(DepartureCell.self, where: { try $0.actualView().departure.id == 4 })
                _ = try cell4.find(text: "Line: Yellow")
                _ = try cell4.find(text: "Platform: 2")
                // Checking the date isn't supported in view inspector, as far as I can tell?
            }
        }
    }

    @MainActor
    struct `When loading throws an error` {
        struct TestError: Error {
            var localizedDescription: String {
                "Test Error"
            }
        }

        let station = Station(name: "My Station", platforms: ["a", "b"])
        let stationService = FakeStationService()

        @Test func `shows error message and retry button`() async throws {
            stationService.departures_spy.stub(failure: TestError())

            let subject = try StationDetailCoordinator(
                station: station,
                stationService: stationService
            ).makeView().inspect()

            try await subject.zStack().callTask()

            #expect(throws: Never.self) {
                _ = try subject.find(text: "Unable to load departures")
                _ = try subject.find(button: "Retry?")
            }
        }

        @Test func `tapping retry attempts to fetch the stations again`() async throws {
            stationService.departures_spy.stub(failure: TestError())

            let subject = try StationDetailCoordinator(
                station: station,
                stationService: stationService
            ).makeView().inspect()

            try await subject.zStack().callTask()

            // reset the station service.
            stationService.departures_spy.clearCalls()
            stationService.departures_spy.stub(pendingFailure: TestError())

            try subject.find(button: "Retry?").tap()

            try await confirmation(until: .firstPass) {
                stationService.departures_spy.wasCalled(with: station)
            }
        }

        @Test func `tapping retry shows a spinner again`() async throws {
            stationService.departures_spy.stub(failure: TestError())

            let subject = try StationDetailCoordinator(
                station: station,
                stationService: stationService
            ).makeView().inspect()

            try await subject.zStack().callTask()

            // reset the station service.
            stationService.departures_spy.clearCalls()
            stationService.departures_spy.stub(pendingFailure: TestError())

            try subject.find(button: "Retry?").tap()

            #expect(throws: Never.self) {
                _ = try subject.find(ViewType.ProgressView.self)
            }
        }
    }
}
