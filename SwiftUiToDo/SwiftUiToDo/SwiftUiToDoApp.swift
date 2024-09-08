//
//  Copyright © Uber Technologies, Inc. All rights reserved.
//


import SwiftUI

@main
struct SwiftUiToDoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
