//
//  ContentView.swift
//  TeacherLink
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        Group {
            if authService.isLoading {
                // Show loading while checking auth state
                ProgressView("Loading...")
            } else if authService.needsEmailConfirmation {
                // Email confirmation required
                EmailConfirmationView()
                    .environmentObject(authService)
            } else if authService.isAuthenticated, let appUser = authService.appUser {
                // User is logged in - route based on role first, then admin level
                switch appUser.role {
                case .teacher:
                    TeacherDashboardView()
                        .environmentObject(authService)
                case .parent:
                    ParentDashboardView()
                        .environmentObject(authService)
                case .student:
                    ParentDashboardView()
                        .environmentObject(authService)
                case .admin:
                    // Route admins based on their admin level
                    if let adminLevel = appUser.adminLevel {
                        switch adminLevel {
                        case .superAdmin:
                            AdminDashboardView()
                                .environmentObject(authService)
                        case .districtAdmin:
                            DistrictAdminDashboardView()
                                .environmentObject(authService)
                        case .principal, .schoolAdmin:
                            PrincipalDashboardView()
                                .environmentObject(authService)
                        case .none:
                            AdminDashboardView()
                                .environmentObject(authService)
                        }
                    } else {
                        // Admin role but no admin level set - use super admin view
                        AdminDashboardView()
                            .environmentObject(authService)
                    }
                }
            } else if authService.isAuthenticated {
                // Authenticated but no user profile yet - show setup screen
                AccountSetupView()
                    .environmentObject(authService)
            } else {
                // Not logged in - show login
                SupabaseLoginView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService())
}
