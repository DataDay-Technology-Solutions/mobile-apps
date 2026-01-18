//
//  DailyContent.swift
//  TeacherLink
//
//  Daily joke and fun fact content for kids
//

import Foundation

struct DailyJoke: Identifiable, Codable {
    var id: String
    var setup: String
    var punchline: String
    var category: JokeCategory
    var date: Date

    enum JokeCategory: String, Codable {
        case animal
        case food
        case school
        case nature
        case silly
    }
}

struct FunFact: Identifiable, Codable {
    var id: String
    var fact: String
    var category: FactCategory
    var emoji: String
    var date: Date

    enum FactCategory: String, Codable {
        case animals
        case space
        case nature
        case science
        case history
    }
}

// Pre-loaded jokes for kids (age-appropriate for 1st grade)
struct DailyContentService {
    static let shared = DailyContentService()

    private let jokes: [DailyJoke] = [
        DailyJoke(id: "j1", setup: "Why did the teddy bear say no to dessert?", punchline: "Because she was already stuffed!", category: .silly, date: Date()),
        DailyJoke(id: "j2", setup: "What do you call a fish without eyes?", punchline: "A fsh!", category: .animal, date: Date()),
        DailyJoke(id: "j3", setup: "Why did the banana go to the doctor?", punchline: "Because it wasn't peeling well!", category: .food, date: Date()),
        DailyJoke(id: "j4", setup: "What do you call a sleeping dinosaur?", punchline: "A dino-snore!", category: .animal, date: Date()),
        DailyJoke(id: "j5", setup: "Why can't you give Elsa a balloon?", punchline: "Because she will let it go!", category: .silly, date: Date()),
        DailyJoke(id: "j6", setup: "What do you call a dog that does magic tricks?", punchline: "A Labracadabrador!", category: .animal, date: Date()),
        DailyJoke(id: "j7", setup: "Why did the cookie go to the nurse?", punchline: "Because it felt crummy!", category: .food, date: Date()),
        DailyJoke(id: "j8", setup: "What do you call a bear with no teeth?", punchline: "A gummy bear!", category: .animal, date: Date()),
        DailyJoke(id: "j9", setup: "Why did the student eat his homework?", punchline: "Because the teacher told him it was a piece of cake!", category: .school, date: Date()),
        DailyJoke(id: "j10", setup: "What do elves learn in school?", punchline: "The elf-abet!", category: .school, date: Date()),
        DailyJoke(id: "j11", setup: "Why do bees have sticky hair?", punchline: "Because they use honeycombs!", category: .animal, date: Date()),
        DailyJoke(id: "j12", setup: "What did the ocean say to the beach?", punchline: "Nothing, it just waved!", category: .nature, date: Date()),
        DailyJoke(id: "j13", setup: "Why did the scarecrow win an award?", punchline: "Because he was outstanding in his field!", category: .silly, date: Date()),
        DailyJoke(id: "j14", setup: "What do you call cheese that isn't yours?", punchline: "Nacho cheese!", category: .food, date: Date()),
        DailyJoke(id: "j15", setup: "Why couldn't the pony sing?", punchline: "Because she was a little horse!", category: .animal, date: Date())
    ]

    private let funFacts: [FunFact] = [
        FunFact(id: "f1", fact: "A group of flamingos is called a 'flamboyance'!", category: .animals, emoji: "🦩", date: Date()),
        FunFact(id: "f2", fact: "Honey never goes bad! Scientists have found 3,000-year-old honey in Egyptian tombs that was still good to eat!", category: .nature, emoji: "🍯", date: Date()),
        FunFact(id: "f3", fact: "Octopuses have three hearts and blue blood!", category: .animals, emoji: "🐙", date: Date()),
        FunFact(id: "f4", fact: "The sun is so big that about 1.3 million Earths could fit inside it!", category: .space, emoji: "☀️", date: Date()),
        FunFact(id: "f5", fact: "Butterflies taste with their feet!", category: .animals, emoji: "🦋", date: Date()),
        FunFact(id: "f6", fact: "A day on Venus is longer than a year on Venus!", category: .space, emoji: "🪐", date: Date()),
        FunFact(id: "f7", fact: "Elephants are the only animals that can't jump!", category: .animals, emoji: "🐘", date: Date()),
        FunFact(id: "f8", fact: "Bananas are berries, but strawberries aren't!", category: .nature, emoji: "🍌", date: Date()),
        FunFact(id: "f9", fact: "A snail can sleep for three years!", category: .animals, emoji: "🐌", date: Date()),
        FunFact(id: "f10", fact: "Lightning is five times hotter than the surface of the sun!", category: .science, emoji: "⚡", date: Date()),
        FunFact(id: "f11", fact: "Cows have best friends and get stressed when separated!", category: .animals, emoji: "🐄", date: Date()),
        FunFact(id: "f12", fact: "There are more stars in the universe than grains of sand on Earth!", category: .space, emoji: "⭐", date: Date()),
        FunFact(id: "f13", fact: "Dolphins sleep with one eye open!", category: .animals, emoji: "🐬", date: Date()),
        FunFact(id: "f14", fact: "Your brain uses about 20% of all your body's energy!", category: .science, emoji: "🧠", date: Date()),
        FunFact(id: "f15", fact: "Cats spend 70% of their lives sleeping!", category: .animals, emoji: "😺", date: Date())
    ]

    // Get joke for today (based on day of year)
    func jokeOfTheDay() -> DailyJoke {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % jokes.count
        return jokes[index]
    }

    // Get fun fact for today
    func funFactOfTheDay() -> FunFact {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % funFacts.count
        return funFacts[index]
    }

    // Get random joke
    func randomJoke() -> DailyJoke {
        return jokes.randomElement() ?? jokes[0]
    }

    // Get random fun fact
    func randomFunFact() -> FunFact {
        return funFacts.randomElement() ?? funFacts[0]
    }
}
