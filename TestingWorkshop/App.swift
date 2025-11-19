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
                StationDependencies().stationListCoordinator().makeView()
            }
        }
    }
}
