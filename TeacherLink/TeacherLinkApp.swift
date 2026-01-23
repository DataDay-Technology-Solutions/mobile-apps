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

    init() {
        configureAppearance()
    }

    private func configureAppearance() {
        // Configure tab bar appearance globally
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .white

        // Unselected state - light gray
        let normalColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = normalColor
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor
        ]

        // Selected state - blue
        let selectedColor = UIColor.systemBlue
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor
        ]

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().unselectedItemTintColor = normalColor
        UITabBar.appearance().tintColor = selectedColor

        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }

    var body: some Scene {
        WindowGroup {
            Group {
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
            .preferredColorScheme(.light)  // Force light mode for bright, cheerful look
        }
    }
}
