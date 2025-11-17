# Workshop on Testing SwiftUI

Welcome! This is a "simple" swiftUI app to show station information for a small fictional transit system which references the San Francisco BART system.

There's a simple "backend" which is faked out for previewing the data. See [`StationService.swift`](TestingWorkshop/StationService.swift) for the protocol and "default" implementation. I'm not going to write and implement a backend for this, as that's outside the scope of this.

For this workshop, you have 3 tasks to implement:

- Test and implement a detail screen for viewing upcoming trains at a given station. Including error handling.
- Test and implement support for filtering and favoriting the list of stations locally. For extra points, make favoriting persist between launches somehow.
- Test and implement another top-level UI page (using a tab-bar style of navigation), which shows a flattened list of favorited stations along with when each train is arriving.

To help get you started, there is already a screen implemented and tested that shows the list of all stations, [StationListView.swift](TestingWorkshop/StationListView.swift). This tested in [`StationListViewTests.swift`](TestingWorkshopTests/StationListViewTests.swift), and uses Swift-Testing, [ViewInspector](https://github.com/nalexn/ViewInspector), and the [Swift-Fakes](https://github.com/quick/swift-fakes) libraries.

You'll note that I'm also using an experimental version of the Swift Testing library, specifically to use a still-in-pitch polling confirmations feature. These allow you to check for when a component's state changes over some period. Which is especially useful when testing UI code as you often want to check behavior that happens in a background thread as a result of interactions on the main thread. Take a look at [the pitch thread on the swift forums](https://forums.swift.org/t/pitch-2-polling-confirmations-in-the-testing-library/81711) for more details.

There are also no UI tests here. That's not really the point of this test.

There is a reference solution, available at the [`reference-solution` branch](https://github.com/younata/testing-workshop/tree/reference-solution).
