//
//  TestingWorkshopApp.swift
//  TestingWorkshop
//

import SwiftUI

@main
struct TestingWorkshopApp: App {
    var body: some Scene {
        WindowGroup {
            StationListView(coordinator: StationListCoordinator(stationService: DefaultStationService()))
        }
    }
}
