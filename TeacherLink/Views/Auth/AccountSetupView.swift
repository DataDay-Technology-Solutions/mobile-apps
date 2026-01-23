//
//  AccountSetupView.swift
//  HallPass (formerly TeacherLink)
//
//  View shown while setting up user account
//

import SwiftUI
import Supabase

struct AccountSetupView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var currentStep = 0
    @State private var showError = false
    @State private var retryCount = 0
    @State private var funFacts = [
        "Did you know? Teachers make over 1,500 decisions per day!",
        "Fun fact: The word 'school' comes from the Greek word for 'leisure'",
        "Studies show students learn better with engaged parents!",
        "The average teacher spends $479 of their own money on classroom supplies",
        "A teacher's influence extends to about 3,000 students over a career",
        "Parent-teacher communication improves student success by 30%",
        "The first classroom bell was used in 1851",
        "Teachers rank among the most trusted professionals worldwide"
    ]
    @State private var currentFactIndex = 0

    let steps = [
        ("person.badge.plus", "Creating your profile..."),
        ("building.2", "Setting up classroom access..."),
        ("checkmark.circle", "Almost there...")
    ]

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Animated logo
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)

                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(currentStep > 0 ? 10 : -10))
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: currentStep)
            }

            // Title
            Text("Setting Up Your Account")
                .font(.title2)
                .fontWeight(.bold)

            // Progress steps
            VStack(spacing: 16) {
                ForEach(0..<steps.count, id: \.self) { index in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 36, height: 36)

                            if index < currentStep {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            } else if index == currentStep {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: steps[index].0)
                                    .foregroundColor(.gray)
                            }
                        }

                        Text(steps[index].1)
                            .foregroundColor(index <= currentStep ? .primary : .secondary)

                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 40)

            // Fun fact card
            VStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)

                Text(funFacts[currentFactIndex])
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()

            // Error state
            if showError {
                VStack(spacing: 16) {
                    Text("Having trouble setting up your account")
                        .foregroundColor(.secondary)

                    if let error = authService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    HStack(spacing: 16) {
                        Button("Try Again") {
                            retrySetup()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button("Sign Out") {
                            authService.signOut()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startSetup()
        }
    }

    private func startSetup() {
        showError = false
        currentStep = 0

        // Animate through steps
        Task {
            // Step 1: Creating profile
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            currentStep = 1
            rotateFunFact()

            // Step 2: Setting up access
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            currentStep = 2
            rotateFunFact()

            // Try to load the profile
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            // Check if we have a user profile now
            if authService.appUser == nil {
                // Try to reload
                await reloadProfile()
            }

            // If still no profile after waiting, show error
            if authService.appUser == nil {
                showError = true
            }
        }
    }

    private func reloadProfile() async {
        do {
            let session = try await SupabaseConfig.client.auth.session
            let userId = session.user.id
            print("DEBUG: Looking for user with ID: \(userId.uuidString)")

            let dbUser: DatabaseUser = try await SupabaseConfig.client
                .from("users")
                .select()
                .eq("id", value: userId.uuidString.lowercased())
                .single()
                .execute()
                .value

            print("DEBUG: Found user: \(dbUser.name)")
            authService.appUser = dbUser.toAppUser()
            authService.isAuthenticated = true
        } catch {
            print("DEBUG: Error loading profile: \(error)")
            authService.errorMessage = "Error: \(error)"
        }
    }

    private func retrySetup() {
        retryCount += 1
        startSetup()
    }

    private func rotateFunFact() {
        currentFactIndex = (currentFactIndex + 1) % funFacts.count
    }
}

#Preview {
    AccountSetupView()
        .environmentObject(AuthenticationService())
}
