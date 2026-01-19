//
//  TeacherLinkApp.swift
//  TeacherLink
//
//  A classroom communication app for teachers and parents
//

import SwiftUI
import FirebaseCore

// Set to true to use mock data (no Firebase required)
let USE_MOCK_DATA = true

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct TeacherLinkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
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
                // Use Firebase-based flow
                ContentView()
                    .environmentObject(AuthenticationService())
            }
        }
    }
}
