//
//  HelloMichaelApp.swift
//  HelloMichael
//
//  Created by Evie Rockwood on 3/16/26.
//

import SwiftUI
import FirebaseCore

@main
struct HelloMichaelApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
