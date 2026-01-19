//
//  TeacherLinkApp.swift
//  TeacherLink
//
//  A classroom communication app for teachers and parents
//

import SwiftUI
import FirebaseCore

// Set to true to use mock data (no Firebase required)
let USE_MOCK_DATA = false

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
    @StateObject private var authService = AuthenticationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}
