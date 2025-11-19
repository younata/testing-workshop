//
//  StationRepositoryTests.swift
//  TestingWorkshop
//

import Fakes
@_spi(Experimental) import Testing
@testable import TestingWorkshop

struct StationRepositoryTests {
    struct `when data hasn't been fetched yet` {
        let service: FakeStationService
        let subject: StationRepository

        init() {
            service = FakeStationService()
            subject = ActualStationRepository(stationService: service)
        }

        @Test func `stations() fetches new data and returns it`() async throws {
            // Act
            let task = Task {
                try await subject.stations()
            }

            // Assert
            try await confirmation(until: .firstPass) {
                service.stations_spy.wasCalled
            }

            service.stations_spy.resolveStub(success: [
                Station(name: "a", platforms: ["b"])
            ])

            #expect(try await task.value == [Station(name: "a", platforms: ["b"])])
        }

        @Test func `stations() fetches new data and forwards errors`() async throws {
            // Act
            let task = Task {
                try await subject.stations()
            }

            // Assert
            try await confirmation(until: .firstPass) {
                service.stations_spy.wasCalled
            }

            service.stations_spy.resolveStub(failure: TestError())

            await #expect(throws: TestError.self) {
                _ = try await task.value
            }
        }

        @Test func `fetching stations() again before it's resolved doesn't make another request`() async throws {
            // Act
            let task1 = Task {
                try await subject.stations()
            }

            let task2 = Task {
                try await subject.stations()
            }

            // Assert
            // Check first that it's called at all.
            try await confirmation(until: .firstPass) {
                service.stations_spy.wasCalled
            }
            // Then make sure that it's never called again during the duration.
            try await confirmation(until: .stopsPassing) {
                service.stations_spy.calls.count == 1
            }
            // Would be nice to combine these two checks into one passing behavior
            // but I'll wait for that to be a follow-up proposal.
        }

        @Test func `fetching stations() again before the first fetch resolves will resolve all extant calls`() async throws {
            // Act
            let task1 = Task {
                try await subject.stations()
            }

            let task2 = Task {
                try await subject.stations()
            }

            // Assert
            try await confirmation(until: .firstPass) {
                service.stations_spy.wasCalled
            }

            service.stations_spy.resolveStub(success: [
                Station(name: "a", platforms: ["b"])
            ])

            #expect(try await task1.value == [Station(name: "a", platforms: ["b"])])
            #expect(try await task2.value == [Station(name: "a", platforms: ["b"])])
        }

        @Test func `calling refresh() and getting an error will throw the error`() async throws {
            service.stations_spy.stub(failure: TestError())

            await #expect(throws: TestError.self) {
                try await subject.refresh()
            }
        }
    }

    struct `when data has been successfully fetched` {
        let service: FakeStationService
        let subject: StationRepository

        init() async throws {
            service = FakeStationService()
            service.stations_spy.stub(success: [
                Station(name: "b", platforms: ["c"])
            ])
            subject = ActualStationRepository(stationService: service)

            // This is still part of setup.
            let _ = try await subject.stations()
        }

        @Test func `stations() returns the cached data and doesn't refetch data`() async throws {
            // Act
            let secondFetch = try await subject.stations()

            // Assert
            #expect(service.stations_spy.calls.count == 1)
            #expect(secondFetch == [Station(name: "b", platforms: ["c"])])
        }

        @Test func `refresh() will fetch new data and cache it`() async throws {
            service.stations_spy.clearCalls()
            service.stations_spy.stub(pendingSuccess: [])

            // Act
            let task = Task {
                try await subject.refresh()
            }

            // Assert
            try await confirmation(until: .firstPass) {
                service.stations_spy.wasCalled
            }

            service.stations_spy.resolveStub(success: [
                Station(name: "a", platforms: ["b"])
            ])

            #expect(try await task.value == [Station(name: "a", platforms: ["b"])])

            #expect(try await subject.stations() == [Station(name: "a", platforms: ["b"])])
            #expect(service.stations_spy.calls.count == 1)
        }

        @Test func `refresh() will return previously cached data if it errors`() async throws {
            service.stations_spy.clearCalls()
            service.stations_spy.stub(pendingSuccess: [])

            // Act
            let task = Task {
                try await subject.refresh()
            }

            // Assert
            try await confirmation(until: .firstPass) {
                service.stations_spy.wasCalled
            }

            service.stations_spy.resolveStub(failure: TestError())

            #expect(try await task.value == [Station(name: "b", platforms: ["c"])])
        }

        @Test func `calling stations() while refresh() is ongoing will return previously cached data`() async throws {
            // Arrange
            service.stations_spy.clearCalls()
            service.stations_spy.stub(pendingSuccess: [])

            let task = Task {
                try await subject.refresh()
            }

            // Wait for that task to be started...
            try await confirmation(until: .firstPass) {
                service.stations_spy.wasCalled
            }

            // Act
            let stations = try await subject.stations()

            // Assert
            #expect(stations == [Station(name: "b", platforms: ["c"])])
        }

        @Test func `calling refresh() multiple times at once won't attempt to refetch stations multiple times`() async throws {
            // Arrange
            service.stations_spy.clearCalls()
            service.stations_spy.stub(pendingSuccess: [])

            // Act
            let task1 = Task {
                try await subject.refresh()
            }
            let task2 = Task {
                try await subject.refresh()
            }

            // Assert
            // Wait for the service to be called at least once.
            try await confirmation(until: .firstPass) {
                service.stations_spy.wasCalled
            }
            try await confirmation(until: .stopsPassing) {
                service.stations_spy.calls.count == 1
            }
        }

        @Test func `calling refresh() multiple times at once will resolve all calls once the station call finishes`() async throws {
            // Arrange
            service.stations_spy.clearCalls()
            service.stations_spy.stub(success: [Station(name: "c", platforms: ["d"])])

            // Act
            let task1 = Task {
                try await subject.refresh()
            }
            let task2 = Task {
                try await subject.refresh()
            }

            // Assert
            #expect(try await task1.value == [Station(name: "c", platforms: ["d"])])
            #expect(try await task2.value == [Station(name: "c", platforms: ["d"])])
        }
    }

    struct `when data has been fetched earlier, but it returned an error` {
        @Test func `stations() will re-fetch new data`() async throws {
            // Arrange
            let service = FakeStationService()
            service.stations_spy.stub(failure: TestError())
            let subject = ActualStationRepository(stationService: service)

            try await #require(throws: TestError.self) {
                try await subject.stations()
            }

            service.stations_spy.stub(success: [])

            // Act
            let secondAttempt = try await subject.stations()

            // Assert
            #expect(service.stations_spy.calls.count == 2)
            #expect(secondAttempt.isEmpty)
        }
    }
}
