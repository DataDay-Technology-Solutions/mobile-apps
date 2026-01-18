//
//  WelcomeView.swift
//  TeacherLink
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignIn = false
    @State private var showSignUp = false
    @State private var selectedRole: UserRole = .teacher

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // Logo and Branding
                VStack(spacing: 16) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.blue, .blue.opacity(0.3))

                    Text("TeacherLink")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Connect your classroom with families")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Features
                VStack(spacing: 20) {
                    FeatureRow(
                        icon: "photo.stack.fill",
                        title: "Share Moments",
                        description: "Post photos and updates from your classroom"
                    )

                    FeatureRow(
                        icon: "message.fill",
                        title: "Easy Messaging",
                        description: "Communicate directly with parents"
                    )

                    FeatureRow(
                        icon: "bell.badge.fill",
                        title: "Stay Connected",
                        description: "Real-time notifications and updates"
                    )
                }
                .padding(.horizontal, 32)

                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    Button {
                        showSignUp = true
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }

                    Button {
                        showSignIn = true
                    } label: {
                        Text("I already have an account")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }

                    // Demo quick login (for testing)
                    if USE_MOCK_DATA {
                        Divider()
                            .padding(.vertical, 8)

                        Text("Demo Quick Login")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            Button {
                                authViewModel.demoLoginAsTeacher()
                            } label: {
                                VStack {
                                    Image(systemName: "person.fill.viewfinder")
                                    Text("Teacher")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }

                            Button {
                                authViewModel.demoLoginAsParent()
                            } label: {
                                VStack {
                                    Image(systemName: "figure.2.and.child.holdinghands")
                                    Text("Parent")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
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

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
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
