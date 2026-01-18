//
//  TeacherLinkApp.swift
//  TeacherLink
//
//  A classroom communication app for teachers and parents
//

import SwiftUI

// Set to true to use mock data (no Firebase required)
let USE_MOCK_DATA = true

@main
struct TeacherLinkApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
