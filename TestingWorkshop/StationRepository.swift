//
//  StationRepository.swift
//  TestingWorkshop
//

protocol StationRepository {
    func stations() async throws -> [Station]
    func refresh() async throws -> [Station]
}

actor ActualStationRepository: StationRepository {
    let stationService: StationService

    private var stationsTask: Task<[Station], Error>? = nil
    private var stationsCache: [Station]? = nil

    init(stationService: StationService) {
        self.stationService = stationService
    }

    func stations() async throws -> [Station] {
        if let stationsCache {
            return stationsCache
        }
        return try await fetchStations()
    }

    func refresh() async throws -> [Station] {
        do {
            return try await fetchStations()
        } catch {
            if let stationsCache {
                return stationsCache
            }
            throw error
        }
    }

    private func fetchStations() async throws -> [Station] {
        if let stationsTask {
            return try await stationsTask.value
        } else {
            let task = Task {
                defer {
                    stationsTask = nil
                }
                do {
                    let value = try await stationService.stations()
                    stationsCache = value
                    return value
                } catch {
                    throw error
                }
            }
            stationsTask = task
            return try await task.value
        }
    }
}
