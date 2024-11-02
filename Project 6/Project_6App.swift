//
//  Project_6App.swift
//  Project 6
//
//  Created by christian de angelo orozco on 10/30/24.
//

import SwiftUI
import FirebaseCore

@main
struct Project_6App: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            TranslateView()
        }
    }
}
