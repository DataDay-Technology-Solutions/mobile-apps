//
//  ContentView.swift
//  TeacherLink
//

import SwiftUI

struct MockContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}

#Preview {
    MockContentView()
        .environmentObject(AuthViewModel())
}
