//
//  TestingWorkshopApp.swift
//  TestingWorkshop
//

import SwiftUI

@main
struct TestingWorkshopApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                StationListCoordinator(stationService: DefaultStationService()).makeView()
            }
        }
    }
}
