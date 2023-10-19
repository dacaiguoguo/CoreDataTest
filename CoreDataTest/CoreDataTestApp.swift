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
            TabView {
                FtContentView<JtItem>(filename: "chaizi-jt")
                    .onAppear {
                        print("\(NSHomeDirectory())")
                    }
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Image(systemName: "lasso")
                        Text("简体")
                    }

                FtContentView<FtItem>(filename: "chaizi-ft")
                    .onAppear {
                        print("\(NSHomeDirectory())")
                    }
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .tabItem {
                        Image(systemName: "lasso.and.sparkles")
                        Text("繁体")
                    }
            }

        }
    }
}
