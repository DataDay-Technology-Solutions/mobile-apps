//
//  WelcomeView.swift
//  Hall Pass
//

import SwiftUI

// App theme colors - Bright and cheerful for education
struct AppTheme {
    // Primary: Friendly sky blue
    static let primary = Color(red: 0.25, green: 0.56, blue: 0.97) // Bright Blue
    // Secondary: Soft mint green
    static let secondary = Color(red: 0.35, green: 0.85, blue: 0.75) // Mint
    // Accent: Warm sunshine yellow-orange
    static let accent = Color(red: 1.0, green: 0.7, blue: 0.25) // Warm Yellow
    // Success: Fresh green
    static let success = Color(red: 0.35, green: 0.78, blue: 0.45) // Green
    // Background: Very light blue-gray
    static let background = Color(red: 0.96, green: 0.97, blue: 0.99) // Light

    static let gradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Softer gradient for backgrounds
    static let softGradient = LinearGradient(
        colors: [primary.opacity(0.15), secondary.opacity(0.1), Color.white],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignIn = false
    @State private var showSignUp = false
    @State private var animatePlane = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient - Bright and welcoming
                LinearGradient(
                    colors: [
                        AppTheme.primary.opacity(0.12),
                        AppTheme.secondary.opacity(0.08),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Logo and Branding
                    VStack(spacing: 20) {
                        // Animated paper airplane logo
                        ZStack {
                            Circle()
                                .fill(AppTheme.gradient)
                                .frame(width: 120, height: 120)
                                .shadow(color: AppTheme.primary.opacity(0.3), radius: 20, x: 0, y: 10)

                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(animatePlane ? -10 : 10))
                                .offset(x: animatePlane ? 2 : -2, y: animatePlane ? -2 : 2)
                                .animation(
                                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                                    value: animatePlane
                                )
                        }

                        Text("Hall Pass")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.gradient)

                        Text("Classroom communication,\nmade simple")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    // Features with new styling
                    VStack(spacing: 18) {
                        HallPassFeatureRow(
                            icon: "camera.fill",
                            title: "Capture Moments",
                            description: "Share classroom photos and memories",
                            color: AppTheme.primary
                        )

                        HallPassFeatureRow(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: "Direct Messages",
                            description: "Private conversations with families",
                            color: AppTheme.secondary
                        )

                        HallPassFeatureRow(
                            icon: "star.fill",
                            title: "Track Progress",
                            description: "Celebrate achievements and milestones",
                            color: AppTheme.accent
                        )
                    }
                    .padding(.horizontal, 28)

                    Spacer()

                    // Action Buttons with new styling
                    VStack(spacing: 14) {
                        Button {
                            showSignUp = true
                        } label: {
                            HStack {
                                Text("Get Started")
                                    .font(.headline)
                                Image(systemName: "arrow.right")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.gradient)
                            .cornerRadius(14)
                            .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        }

                        Button {
                            showSignIn = true
                        } label: {
                            Text("I already have an account")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(AppTheme.primary)
                        }
                        .padding(.top, 4)

                        // Demo quick login (for testing)
                        if USE_MOCK_DATA {
                            VStack(spacing: 12) {
                                HStack {
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.3))
                                        .frame(height: 1)
                                    Text("Demo Mode")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.secondary)
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.3))
                                        .frame(height: 1)
                                }
                                .padding(.top, 8)

                                HStack(spacing: 12) {
                                    Button {
                                        authViewModel.demoLoginAsTeacher()
                                    } label: {
                                        HStack {
                                            Image(systemName: "person.badge.key.fill")
                                            Text("Teacher")
                                                .font(.subheadline.weight(.medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(AppTheme.primary.opacity(0.1))
                                        .foregroundColor(AppTheme.primary)
                                        .cornerRadius(10)
                                    }

                                    Button {
                                        authViewModel.demoLoginAsParent()
                                    } label: {
                                        HStack {
                                            Image(systemName: "figure.and.child.holdinghands")
                                            Text("Parent")
                                                .font(.subheadline.weight(.medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(AppTheme.secondary.opacity(0.1))
                                        .foregroundColor(AppTheme.secondary)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 36)
                }
            }
            .onAppear {
                animatePlane = true
            }
            .sheet(isPresented: $showSignIn) {
                SignInView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct HallPassFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(color)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthViewModel())
}
