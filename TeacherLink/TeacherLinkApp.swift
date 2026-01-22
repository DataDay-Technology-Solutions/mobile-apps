//
//  TeacherLinkApp.swift
//  HallPass (formerly TeacherLink)
//
//  A classroom communication app for teachers and parents
//  Backend: Supabase (migrated from Firebase)
//

import SwiftUI

// Set to true to use mock data (no Supabase required)
let USE_MOCK_DATA = false

@main
struct TeacherLinkApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if USE_MOCK_DATA {
                // Use original Hall Pass app with mock data
                if authViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(authViewModel)
                } else {
                    WelcomeView()
                        .environmentObject(authViewModel)
                }
            } else {
                // Use Supabase-based flow
                ContentView()
                    .environmentObject(AuthenticationService())
            }
        }
    }
}
