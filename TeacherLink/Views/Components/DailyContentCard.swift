//
//  DailyContentCard.swift
//  TeacherLink
//
//  Daily joke and fun fact cards for kids
//

import SwiftUI

struct DailyJokeCard: View {
    let joke: DailyJoke
    @State private var showPunchline = false
    var onRefresh: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "face.smiling.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)

                Text("Joke of the Day")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if let refresh = onRefresh {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showPunchline = false
                            refresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue.opacity(0.7))
                    }
                }

                Text(categoryEmoji)
                    .font(.title2)
            }

            // Setup
            Text(joke.setup)
                .font(.body)
                .foregroundColor(.primary)

            // Punchline (tap to reveal)
            if showPunchline {
                Text(joke.punchline)
                    .font(.body.bold())
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        showPunchline = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                        Text("Tap to see the answer!")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var categoryEmoji: String {
        switch joke.category {
        case .animal: return "🐾"
        case .food: return "🍕"
        case .school: return "📚"
        case .nature: return "🌳"
        case .silly: return "🤪"
        case .science: return "🔬"
        case .sports: return "⚽"
        case .music: return "🎵"
        }
    }
}

struct FunFactCard: View {
    let fact: FunFact
    var onRefresh: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(fact.emoji)
                    .font(.title)

                Text("Fun Fact!")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if let refresh = onRefresh {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            refresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue.opacity(0.7))
                    }
                }

                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            }

            // Fact
            Text(fact.fact)
                .font(.body)
                .foregroundColor(.primary)

            // Category badge
            HStack {
                Spacer()
                Text(categoryLabel)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(categoryColor)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [categoryColor.opacity(0.1), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var categoryLabel: String {
        switch fact.category {
        case .animals: return "Animals"
        case .space: return "Space"
        case .nature: return "Nature"
        case .science: return "Science"
        case .history: return "History"
        case .ocean: return "Ocean"
        case .body: return "Human Body"
        case .weather: return "Weather"
        case .geography: return "Geography"
        }
    }

    private var categoryColor: Color {
        switch fact.category {
        case .animals: return .green
        case .space: return .purple
        case .nature: return .teal
        case .science: return .orange
        case .history: return .brown
        case .ocean: return .blue
        case .body: return .pink
        case .weather: return .cyan
        case .geography: return .indigo
        }
    }
}

struct DailyContentSection: View {
    @State private var currentJoke: DailyJoke = DailyContentService.shared.randomJoke()
    @State private var currentFact: FunFact = DailyContentService.shared.randomFunFact()
    @State private var jokeId = UUID()
    @State private var factId = UUID()

    var body: some View {
        VStack(spacing: 16) {
            DailyJokeCard(joke: currentJoke, onRefresh: refreshJoke)
                .id(jokeId)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 1.1).combined(with: .opacity)
                ))

            FunFactCard(fact: currentFact, onRefresh: refreshFact)
                .id(factId)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 1.1).combined(with: .opacity)
                ))
        }
        .onAppear {
            // Randomize on each appear
            refreshJoke()
            refreshFact()
        }
    }

    private func refreshJoke() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            currentJoke = DailyContentService.shared.randomJoke()
            jokeId = UUID()
        }
    }

    private func refreshFact() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            currentFact = DailyContentService.shared.randomFunFact()
            factId = UUID()
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            DailyContentSection()
        }
        .padding()
    }
    .background(Color(.systemGray6))
}
