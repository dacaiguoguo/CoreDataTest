//
//  CoreDataTestApp.swift
//  CoreDataTest
//
//  Created by yanguo sun on 2023/10/18.
//

import SwiftUI

@main
struct CoreDataTestApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("\(NSHomeDirectory())")
                }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
