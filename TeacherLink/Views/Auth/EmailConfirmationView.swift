//
//  EmailConfirmationView.swift
//  HallPass (formerly TeacherLink)
//
//  View shown when email confirmation is required
//

import SwiftUI
import Supabase

struct EmailConfirmationView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var isResending = false
    @State private var showResendSuccess = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Email icon
            Image(systemName: "envelope.badge")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            // Title
            Text("Check Your Email")
                .font(.title)
                .fontWeight(.bold)

            // Message
            VStack(spacing: 8) {
                Text("We sent a confirmation link to:")
                    .foregroundColor(.secondary)

                Text(authService.pendingEmail ?? "your email")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Please click the link in your email to verify your account.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(.horizontal)

            // Resend button
            Button(action: {
                resendConfirmation()
            }) {
                if isResending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text(showResendSuccess ? "Email Sent!" : "Resend Confirmation Email")
                }
            }
            .disabled(isResending || showResendSuccess)
            .padding(.top)

            // Check again button
            Button(action: {
                Task {
                    authService.isLoading = true
                    // Try to refresh the session
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await checkConfirmation()
                    authService.isLoading = false
                }
            }) {
                Text("I've confirmed my email")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)

            // Back to login
            Button(action: {
                authService.signOut()
                authService.needsEmailConfirmation = false
                authService.pendingEmail = nil
            }) {
                Text("Back to Login")
                    .foregroundColor(.blue)
            }

            Spacer()
        }
        .padding()
    }

    private func resendConfirmation() {
        guard let email = authService.pendingEmail else { return }

        isResending = true

        Task {
            do {
                try await SupabaseConfig.client.auth.resend(
                    email: email,
                    type: .signup
                )
                showResendSuccess = true

                // Reset after 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                showResendSuccess = false
            } catch {
                authService.errorMessage = error.localizedDescription
            }
            isResending = false
        }
    }

    private func checkConfirmation() async {
        do {
            let session = try await SupabaseConfig.client.auth.session
            let user = session.user
            if user.emailConfirmedAt != nil {
                // Email confirmed! Load profile
                authService.needsEmailConfirmation = false
                let dbUser: DatabaseUser = try await SupabaseConfig.client
                    .from("users")
                    .select()
                    .eq("id", value: user.id.uuidString)
                    .single()
                    .execute()
                    .value

                authService.appUser = dbUser.toAppUser()
                authService.isAuthenticated = true
            } else {
                authService.errorMessage = "Email not confirmed yet. Please check your inbox."
            }
        } catch {
            authService.errorMessage = "Please confirm your email first."
        }
    }
}

#Preview {
    EmailConfirmationView()
        .environmentObject(AuthenticationService())
}
