//
//  PushesLogApp.swift
//  PushesLog
//
//  Created by Benjamin on 17/08/2024.
//

import SwiftUI

@main
struct PushesLogApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
