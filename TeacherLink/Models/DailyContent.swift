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
        case science
        case sports
        case music
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
        case ocean
        case body
        case weather
        case geography
    }
}

// Pre-loaded jokes for kids (age-appropriate for elementary school)
struct DailyContentService {
    static let shared = DailyContentService()

    // MARK: - Jokes Collection (100+ jokes)
    private let jokes: [DailyJoke] = [
        // Animal Jokes
        DailyJoke(id: "j1", setup: "Why did the teddy bear say no to dessert?", punchline: "Because she was already stuffed!", category: .silly, date: Date()),
        DailyJoke(id: "j2", setup: "What do you call a fish without eyes?", punchline: "A fsh!", category: .animal, date: Date()),
        DailyJoke(id: "j3", setup: "What do you call a sleeping dinosaur?", punchline: "A dino-snore!", category: .animal, date: Date()),
        DailyJoke(id: "j4", setup: "What do you call a dog that does magic tricks?", punchline: "A Labracadabrador!", category: .animal, date: Date()),
        DailyJoke(id: "j5", setup: "What do you call a bear with no teeth?", punchline: "A gummy bear!", category: .animal, date: Date()),
        DailyJoke(id: "j6", setup: "Why do bees have sticky hair?", punchline: "Because they use honeycombs!", category: .animal, date: Date()),
        DailyJoke(id: "j7", setup: "Why couldn't the pony sing?", punchline: "Because she was a little horse!", category: .animal, date: Date()),
        DailyJoke(id: "j8", setup: "What do you call a lazy kangaroo?", punchline: "A pouch potato!", category: .animal, date: Date()),
        DailyJoke(id: "j9", setup: "Why do cows wear bells?", punchline: "Because their horns don't work!", category: .animal, date: Date()),
        DailyJoke(id: "j10", setup: "What do you call a pig that knows karate?", punchline: "A pork chop!", category: .animal, date: Date()),
        DailyJoke(id: "j11", setup: "Why don't elephants use computers?", punchline: "Because they're afraid of the mouse!", category: .animal, date: Date()),
        DailyJoke(id: "j12", setup: "What do you call a fly without wings?", punchline: "A walk!", category: .animal, date: Date()),
        DailyJoke(id: "j13", setup: "Why do seagulls fly over the sea?", punchline: "Because if they flew over the bay, they'd be bagels!", category: .animal, date: Date()),
        DailyJoke(id: "j14", setup: "What do you get when you cross a snake and a pie?", punchline: "A pie-thon!", category: .animal, date: Date()),
        DailyJoke(id: "j15", setup: "Why do birds fly south in winter?", punchline: "Because it's too far to walk!", category: .animal, date: Date()),
        DailyJoke(id: "j16", setup: "What do cats eat for breakfast?", punchline: "Mice Krispies!", category: .animal, date: Date()),
        DailyJoke(id: "j17", setup: "What do you call a cow with no legs?", punchline: "Ground beef!", category: .animal, date: Date()),
        DailyJoke(id: "j18", setup: "Why are fish so smart?", punchline: "Because they live in schools!", category: .animal, date: Date()),
        DailyJoke(id: "j19", setup: "What do you call a dinosaur that crashes their car?", punchline: "Tyrannosaurus Wrecks!", category: .animal, date: Date()),
        DailyJoke(id: "j20", setup: "Why don't oysters share?", punchline: "Because they're shellfish!", category: .animal, date: Date()),
        DailyJoke(id: "j21", setup: "What do you call a duck that steals?", punchline: "A robber ducky!", category: .animal, date: Date()),
        DailyJoke(id: "j22", setup: "Why do pandas like old movies?", punchline: "Because they're in black and white!", category: .animal, date: Date()),
        DailyJoke(id: "j23", setup: "What do you call an alligator in a vest?", punchline: "An investigator!", category: .animal, date: Date()),
        DailyJoke(id: "j24", setup: "Why did the spider go to the computer?", punchline: "To check his website!", category: .animal, date: Date()),
        DailyJoke(id: "j25", setup: "What do you call a cat that bowls?", punchline: "An alley cat!", category: .animal, date: Date()),

        // Food Jokes
        DailyJoke(id: "j26", setup: "Why did the banana go to the doctor?", punchline: "Because it wasn't peeling well!", category: .food, date: Date()),
        DailyJoke(id: "j27", setup: "Why did the cookie go to the nurse?", punchline: "Because it felt crummy!", category: .food, date: Date()),
        DailyJoke(id: "j28", setup: "What do you call cheese that isn't yours?", punchline: "Nacho cheese!", category: .food, date: Date()),
        DailyJoke(id: "j29", setup: "Why did the tomato turn red?", punchline: "Because it saw the salad dressing!", category: .food, date: Date()),
        DailyJoke(id: "j30", setup: "What did the grape say when it got stepped on?", punchline: "Nothing, it just let out a little wine!", category: .food, date: Date()),
        DailyJoke(id: "j31", setup: "Why did the melon jump into the lake?", punchline: "Because it wanted to be a watermelon!", category: .food, date: Date()),
        DailyJoke(id: "j32", setup: "What do you call a fake noodle?", punchline: "An impasta!", category: .food, date: Date()),
        DailyJoke(id: "j33", setup: "Why did the orange stop rolling down the hill?", punchline: "It ran out of juice!", category: .food, date: Date()),
        DailyJoke(id: "j34", setup: "What do you call a sad strawberry?", punchline: "A blueberry!", category: .food, date: Date()),
        DailyJoke(id: "j35", setup: "Why do mushrooms get invited to parties?", punchline: "Because they're such fun-guys!", category: .food, date: Date()),
        DailyJoke(id: "j36", setup: "What did the pizza say to the topping?", punchline: "I never SAUsage a pretty face!", category: .food, date: Date()),
        DailyJoke(id: "j37", setup: "Why did the egg hide?", punchline: "It was a little chicken!", category: .food, date: Date()),
        DailyJoke(id: "j38", setup: "What's a potato's favorite day?", punchline: "Fry-day!", category: .food, date: Date()),
        DailyJoke(id: "j39", setup: "Why did the bread go to therapy?", punchline: "Because it had too many problems to loaf around!", category: .food, date: Date()),
        DailyJoke(id: "j40", setup: "What do you call a peanut in space?", punchline: "An astro-nut!", category: .food, date: Date()),

        // School Jokes
        DailyJoke(id: "j41", setup: "Why did the student eat his homework?", punchline: "Because the teacher told him it was a piece of cake!", category: .school, date: Date()),
        DailyJoke(id: "j42", setup: "What do elves learn in school?", punchline: "The elf-abet!", category: .school, date: Date()),
        DailyJoke(id: "j43", setup: "Why did the math book look sad?", punchline: "Because it had too many problems!", category: .school, date: Date()),
        DailyJoke(id: "j44", setup: "What's a snake's favorite subject?", punchline: "Hiss-tory!", category: .school, date: Date()),
        DailyJoke(id: "j45", setup: "Why did the pencil win the race?", punchline: "Because it kept drawing ahead!", category: .school, date: Date()),
        DailyJoke(id: "j46", setup: "What do librarians take with them when they go fishing?", punchline: "Bookworms!", category: .school, date: Date()),
        DailyJoke(id: "j47", setup: "Why did the clock get in trouble at school?", punchline: "Because it tocked too much!", category: .school, date: Date()),
        DailyJoke(id: "j48", setup: "What's a witch's favorite subject?", punchline: "Spelling!", category: .school, date: Date()),
        DailyJoke(id: "j49", setup: "Why did the music teacher go to jail?", punchline: "Because she got caught with too many sharp objects!", category: .school, date: Date()),
        DailyJoke(id: "j50", setup: "What do you call a teacher who forgot to take attendance?", punchline: "Absent-minded!", category: .school, date: Date()),
        DailyJoke(id: "j51", setup: "Why did the ruler feel important?", punchline: "Because everyone looked up to it for measurements!", category: .school, date: Date()),
        DailyJoke(id: "j52", setup: "What did zero say to eight?", punchline: "Nice belt!", category: .school, date: Date()),
        DailyJoke(id: "j53", setup: "Why was the equal sign so humble?", punchline: "Because it wasn't greater than or less than anyone!", category: .school, date: Date()),

        // Nature Jokes
        DailyJoke(id: "j54", setup: "What did the ocean say to the beach?", punchline: "Nothing, it just waved!", category: .nature, date: Date()),
        DailyJoke(id: "j55", setup: "Why did the scarecrow win an award?", punchline: "Because he was outstanding in his field!", category: .nature, date: Date()),
        DailyJoke(id: "j56", setup: "What did the tree say to the wind?", punchline: "Leaf me alone!", category: .nature, date: Date()),
        DailyJoke(id: "j57", setup: "Why do trees seem suspicious on sunny days?", punchline: "They just seem a little shady!", category: .nature, date: Date()),
        DailyJoke(id: "j58", setup: "What did one volcano say to the other?", punchline: "I lava you!", category: .nature, date: Date()),
        DailyJoke(id: "j59", setup: "Why did the sun go to school?", punchline: "To get a little brighter!", category: .nature, date: Date()),
        DailyJoke(id: "j60", setup: "What do you call a flower that runs on electricity?", punchline: "A power plant!", category: .nature, date: Date()),
        DailyJoke(id: "j61", setup: "Why did the leaf go to the doctor?", punchline: "Because it was feeling green!", category: .nature, date: Date()),
        DailyJoke(id: "j62", setup: "What's a mountain's favorite type of candy?", punchline: "Snow caps!", category: .nature, date: Date()),
        DailyJoke(id: "j63", setup: "Why do rivers never get lost?", punchline: "Because they always follow the current!", category: .nature, date: Date()),

        // Silly Jokes
        DailyJoke(id: "j64", setup: "Why can't you give Elsa a balloon?", punchline: "Because she will let it go!", category: .silly, date: Date()),
        DailyJoke(id: "j65", setup: "What do you call a boomerang that doesn't come back?", punchline: "A stick!", category: .silly, date: Date()),
        DailyJoke(id: "j66", setup: "Why did the picture go to jail?", punchline: "Because it was framed!", category: .silly, date: Date()),
        DailyJoke(id: "j67", setup: "What do you call a snowman in summer?", punchline: "A puddle!", category: .silly, date: Date()),
        DailyJoke(id: "j68", setup: "Why did the bicycle fall over?", punchline: "Because it was two-tired!", category: .silly, date: Date()),
        DailyJoke(id: "j69", setup: "What do you call a shoe made of a banana?", punchline: "A slipper!", category: .silly, date: Date()),
        DailyJoke(id: "j70", setup: "Why did the golfer bring two pairs of pants?", punchline: "In case he got a hole in one!", category: .silly, date: Date()),
        DailyJoke(id: "j71", setup: "What did one wall say to the other wall?", punchline: "I'll meet you at the corner!", category: .silly, date: Date()),
        DailyJoke(id: "j72", setup: "Why can't you tell a joke while ice skating?", punchline: "Because the ice might crack up!", category: .silly, date: Date()),
        DailyJoke(id: "j73", setup: "What has ears but cannot hear?", punchline: "A cornfield!", category: .silly, date: Date()),
        DailyJoke(id: "j74", setup: "What did one toilet say to the other?", punchline: "You look flushed!", category: .silly, date: Date()),
        DailyJoke(id: "j75", setup: "Why did the kid throw butter out the window?", punchline: "To see a butterfly!", category: .silly, date: Date()),
        DailyJoke(id: "j76", setup: "What do you call a train that sneezes?", punchline: "Achoo-choo train!", category: .silly, date: Date()),
        DailyJoke(id: "j77", setup: "Why did the belt go to jail?", punchline: "For holding up the pants!", category: .silly, date: Date()),
        DailyJoke(id: "j78", setup: "What do you call a dinosaur that wears glasses?", punchline: "A Do-you-think-he-saurus!", category: .silly, date: Date()),

        // Science Jokes
        DailyJoke(id: "j79", setup: "Why did the atom cross the road?", punchline: "Because it was time to split!", category: .science, date: Date()),
        DailyJoke(id: "j80", setup: "What did the scientist say when he found 2 atoms of helium?", punchline: "HeHe!", category: .science, date: Date()),
        DailyJoke(id: "j81", setup: "Why can't you trust atoms?", punchline: "Because they make up everything!", category: .science, date: Date()),
        DailyJoke(id: "j82", setup: "What did Earth say to the other planets?", punchline: "You guys have no life!", category: .science, date: Date()),
        DailyJoke(id: "j83", setup: "Why did the scientist install a knocker on his door?", punchline: "He wanted to win the No-bell prize!", category: .science, date: Date()),
        DailyJoke(id: "j84", setup: "What's a robot's favorite snack?", punchline: "Computer chips!", category: .science, date: Date()),
        DailyJoke(id: "j85", setup: "Why did the moon skip dinner?", punchline: "Because it was full!", category: .science, date: Date()),
        DailyJoke(id: "j86", setup: "What planet has the shortest year?", punchline: "Mercury, because it's closest to the sun!", category: .science, date: Date()),
        DailyJoke(id: "j87", setup: "Why did the rocket break up with the satellite?", punchline: "It needed more space!", category: .science, date: Date()),

        // Sports Jokes
        DailyJoke(id: "j88", setup: "Why did the football coach go to the bank?", punchline: "To get his quarterback!", category: .sports, date: Date()),
        DailyJoke(id: "j89", setup: "What's a cheerleader's favorite color?", punchline: "Yeller!", category: .sports, date: Date()),
        DailyJoke(id: "j90", setup: "Why did the basketball player bring a ladder?", punchline: "Because the coach told him to shoot for the stars!", category: .sports, date: Date()),
        DailyJoke(id: "j91", setup: "Why did the tennis player bring a racket to dinner?", punchline: "In case they served up some tennis rolls!", category: .sports, date: Date()),
        DailyJoke(id: "j92", setup: "What do you call a pig that plays basketball?", punchline: "A ball hog!", category: .sports, date: Date()),
        DailyJoke(id: "j93", setup: "Why are baseball games at night?", punchline: "Because bats sleep during the day!", category: .sports, date: Date()),
        DailyJoke(id: "j94", setup: "What lights up a soccer stadium?", punchline: "A soccer match!", category: .sports, date: Date()),

        // Music Jokes
        DailyJoke(id: "j95", setup: "What's a skeleton's favorite instrument?", punchline: "The trom-bone!", category: .music, date: Date()),
        DailyJoke(id: "j96", setup: "Why did the music note go to the doctor?", punchline: "Because it had a bad tone!", category: .music, date: Date()),
        DailyJoke(id: "j97", setup: "What type of music are balloons scared of?", punchline: "Pop music!", category: .music, date: Date()),
        DailyJoke(id: "j98", setup: "Why did the piano player keep banging his head?", punchline: "He was playing by ear!", category: .music, date: Date()),
        DailyJoke(id: "j99", setup: "What do you get when you drop a piano down a mine shaft?", punchline: "A flat minor!", category: .music, date: Date()),
        DailyJoke(id: "j100", setup: "What's a cat's favorite song?", punchline: "Three Blind Mice!", category: .music, date: Date()),

        // More Animal Jokes
        DailyJoke(id: "j101", setup: "What do you call a sleeping bull?", punchline: "A bulldozer!", category: .animal, date: Date()),
        DailyJoke(id: "j102", setup: "What do you get from a pampered cow?", punchline: "Spoiled milk!", category: .animal, date: Date()),
        DailyJoke(id: "j103", setup: "Why do hummingbirds hum?", punchline: "Because they don't know the words!", category: .animal, date: Date()),
        DailyJoke(id: "j104", setup: "What do you call a monkey in a minefield?", punchline: "A ba-BOOM!", category: .animal, date: Date()),
        DailyJoke(id: "j105", setup: "Why do ducks have tail feathers?", punchline: "To cover their butt quacks!", category: .animal, date: Date()),
        DailyJoke(id: "j106", setup: "What do you call a rabbit with fleas?", punchline: "Bugs Bunny!", category: .animal, date: Date()),
        DailyJoke(id: "j107", setup: "Why don't crabs give to charity?", punchline: "Because they're shellfish!", category: .animal, date: Date()),
        DailyJoke(id: "j108", setup: "What's a frog's favorite candy?", punchline: "Lollihops!", category: .animal, date: Date()),
        DailyJoke(id: "j109", setup: "Why did the turkey join the band?", punchline: "Because it had the drumsticks!", category: .animal, date: Date()),
        DailyJoke(id: "j110", setup: "What do you call a chicken looking at lettuce?", punchline: "Chicken Caesar Salad!", category: .animal, date: Date()),
        DailyJoke(id: "j111", setup: "What do you call a sheep with no legs?", punchline: "A cloud!", category: .animal, date: Date()),
        DailyJoke(id: "j112", setup: "Why did the dolphin cross the road?", punchline: "To get to the other tide!", category: .animal, date: Date()),
        DailyJoke(id: "j113", setup: "What do you call a snake that works for the government?", punchline: "A civil serpent!", category: .animal, date: Date()),
        DailyJoke(id: "j114", setup: "Why are leopards bad at hide and seek?", punchline: "Because they're always spotted!", category: .animal, date: Date()),
        DailyJoke(id: "j115", setup: "What do you call a grumpy cow?", punchline: "Moo-dy!", category: .animal, date: Date()),

        // More Silly Jokes
        DailyJoke(id: "j116", setup: "What has hands but can't clap?", punchline: "A clock!", category: .silly, date: Date()),
        DailyJoke(id: "j117", setup: "What runs but never walks?", punchline: "Water!", category: .silly, date: Date()),
        DailyJoke(id: "j118", setup: "What has a head and a tail but no body?", punchline: "A coin!", category: .silly, date: Date()),
        DailyJoke(id: "j119", setup: "What can travel around the world while staying in a corner?", punchline: "A stamp!", category: .silly, date: Date()),
        DailyJoke(id: "j120", setup: "What has keys but can't open locks?", punchline: "A piano!", category: .silly, date: Date())
    ]

    // MARK: - Fun Facts Collection (100+ facts)
    private let funFacts: [FunFact] = [
        // Animal Facts
        FunFact(id: "f1", fact: "A group of flamingos is called a 'flamboyance'!", category: .animals, emoji: "🦩", date: Date()),
        FunFact(id: "f2", fact: "Octopuses have three hearts and blue blood!", category: .animals, emoji: "🐙", date: Date()),
        FunFact(id: "f3", fact: "Butterflies taste with their feet!", category: .animals, emoji: "🦋", date: Date()),
        FunFact(id: "f4", fact: "Elephants are the only animals that can't jump!", category: .animals, emoji: "🐘", date: Date()),
        FunFact(id: "f5", fact: "A snail can sleep for three years!", category: .animals, emoji: "🐌", date: Date()),
        FunFact(id: "f6", fact: "Cows have best friends and get stressed when separated!", category: .animals, emoji: "🐄", date: Date()),
        FunFact(id: "f7", fact: "Dolphins sleep with one eye open!", category: .animals, emoji: "🐬", date: Date()),
        FunFact(id: "f8", fact: "Cats spend 70% of their lives sleeping!", category: .animals, emoji: "😺", date: Date()),
        FunFact(id: "f9", fact: "A group of owls is called a 'parliament'!", category: .animals, emoji: "🦉", date: Date()),
        FunFact(id: "f10", fact: "Koalas sleep up to 22 hours a day!", category: .animals, emoji: "🐨", date: Date()),
        FunFact(id: "f11", fact: "Hummingbirds are the only birds that can fly backwards!", category: .animals, emoji: "🐦", date: Date()),
        FunFact(id: "f12", fact: "A shrimp's heart is in its head!", category: .animals, emoji: "🦐", date: Date()),
        FunFact(id: "f13", fact: "Sloths can hold their breath longer than dolphins - up to 40 minutes!", category: .animals, emoji: "🦥", date: Date()),
        FunFact(id: "f14", fact: "A jellyfish is 95% water!", category: .animals, emoji: "🪼", date: Date()),
        FunFact(id: "f15", fact: "Penguins propose to their mates with a pebble!", category: .animals, emoji: "🐧", date: Date()),
        FunFact(id: "f16", fact: "A cheetah can run as fast as a car on the highway - 70 mph!", category: .animals, emoji: "🐆", date: Date()),
        FunFact(id: "f17", fact: "Giraffes only need 30 minutes of sleep per day!", category: .animals, emoji: "🦒", date: Date()),
        FunFact(id: "f18", fact: "Polar bear fur is actually transparent, not white!", category: .animals, emoji: "🐻‍❄️", date: Date()),
        FunFact(id: "f19", fact: "A group of porcupines is called a 'prickle'!", category: .animals, emoji: "🦔", date: Date()),
        FunFact(id: "f20", fact: "Bats are the only mammals that can fly!", category: .animals, emoji: "🦇", date: Date()),
        FunFact(id: "f21", fact: "A crocodile cannot stick its tongue out!", category: .animals, emoji: "🐊", date: Date()),
        FunFact(id: "f22", fact: "Sea otters hold hands while they sleep so they don't drift apart!", category: .animals, emoji: "🦦", date: Date()),
        FunFact(id: "f23", fact: "Frogs don't drink water - they absorb it through their skin!", category: .animals, emoji: "🐸", date: Date()),
        FunFact(id: "f24", fact: "A dog's nose print is unique, like a human fingerprint!", category: .animals, emoji: "🐕", date: Date()),
        FunFact(id: "f25", fact: "Kangaroos can't walk backwards!", category: .animals, emoji: "🦘", date: Date()),

        // Space Facts
        FunFact(id: "f26", fact: "The sun is so big that about 1.3 million Earths could fit inside it!", category: .space, emoji: "☀️", date: Date()),
        FunFact(id: "f27", fact: "A day on Venus is longer than a year on Venus!", category: .space, emoji: "🪐", date: Date()),
        FunFact(id: "f28", fact: "There are more stars in the universe than grains of sand on Earth!", category: .space, emoji: "⭐", date: Date()),
        FunFact(id: "f29", fact: "You could fit all the planets between Earth and the Moon!", category: .space, emoji: "🌙", date: Date()),
        FunFact(id: "f30", fact: "One million Earths could fit inside the Sun!", category: .space, emoji: "🌞", date: Date()),
        FunFact(id: "f31", fact: "The footprints on the Moon will be there for 100 million years!", category: .space, emoji: "👣", date: Date()),
        FunFact(id: "f32", fact: "There's a planet made of diamonds twice the size of Earth!", category: .space, emoji: "💎", date: Date()),
        FunFact(id: "f33", fact: "A neutron star can spin 600 times per second!", category: .space, emoji: "✨", date: Date()),
        FunFact(id: "f34", fact: "Space is completely silent because there's no air to carry sound!", category: .space, emoji: "🤫", date: Date()),
        FunFact(id: "f35", fact: "You would weigh less on Mars than on Earth!", category: .space, emoji: "⚖️", date: Date()),
        FunFact(id: "f36", fact: "The sunset on Mars appears blue!", category: .space, emoji: "🔵", date: Date()),
        FunFact(id: "f37", fact: "Jupiter's Great Red Spot is a storm that's been going for over 400 years!", category: .space, emoji: "🔴", date: Date()),
        FunFact(id: "f38", fact: "Saturn would float if you could put it in a giant bathtub!", category: .space, emoji: "🛁", date: Date()),
        FunFact(id: "f39", fact: "A year on Mercury is only 88 Earth days!", category: .space, emoji: "📅", date: Date()),
        FunFact(id: "f40", fact: "There's a volcano on Mars three times taller than Mount Everest!", category: .space, emoji: "🌋", date: Date()),

        // Nature Facts
        FunFact(id: "f41", fact: "Honey never goes bad! Scientists have found 3,000-year-old honey that was still good to eat!", category: .nature, emoji: "🍯", date: Date()),
        FunFact(id: "f42", fact: "Bananas are berries, but strawberries aren't!", category: .nature, emoji: "🍌", date: Date()),
        FunFact(id: "f43", fact: "A cloud can weigh more than a million pounds!", category: .nature, emoji: "☁️", date: Date()),
        FunFact(id: "f44", fact: "There are more trees on Earth than stars in the Milky Way!", category: .nature, emoji: "🌲", date: Date()),
        FunFact(id: "f45", fact: "The Amazon rainforest produces 20% of Earth's oxygen!", category: .nature, emoji: "🌳", date: Date()),
        FunFact(id: "f46", fact: "A single tree can absorb 48 pounds of carbon dioxide per year!", category: .nature, emoji: "🌿", date: Date()),
        FunFact(id: "f47", fact: "Bamboo can grow up to 35 inches in a single day!", category: .nature, emoji: "🎋", date: Date()),
        FunFact(id: "f48", fact: "Sunflowers can help clean up radioactive waste!", category: .nature, emoji: "🌻", date: Date()),
        FunFact(id: "f49", fact: "The oldest tree in the world is over 5,000 years old!", category: .nature, emoji: "🌴", date: Date()),
        FunFact(id: "f50", fact: "Pineapples take about 2 years to grow!", category: .nature, emoji: "🍍", date: Date()),
        FunFact(id: "f51", fact: "Apples float in water because they're 25% air!", category: .nature, emoji: "🍎", date: Date()),
        FunFact(id: "f52", fact: "Avocados are poisonous to birds!", category: .nature, emoji: "🥑", date: Date()),
        FunFact(id: "f53", fact: "A tomato is technically a fruit!", category: .nature, emoji: "🍅", date: Date()),

        // Science Facts
        FunFact(id: "f54", fact: "Lightning is five times hotter than the surface of the sun!", category: .science, emoji: "⚡", date: Date()),
        FunFact(id: "f55", fact: "Your brain uses about 20% of all your body's energy!", category: .science, emoji: "🧠", date: Date()),
        FunFact(id: "f56", fact: "Water can boil and freeze at the same time!", category: .science, emoji: "💧", date: Date()),
        FunFact(id: "f57", fact: "Light from the sun takes 8 minutes to reach Earth!", category: .science, emoji: "💡", date: Date()),
        FunFact(id: "f58", fact: "Hot water freezes faster than cold water!", category: .science, emoji: "🧊", date: Date()),
        FunFact(id: "f59", fact: "A teaspoon of a neutron star would weigh 6 billion tons!", category: .science, emoji: "🥄", date: Date()),
        FunFact(id: "f60", fact: "Sound travels 4 times faster in water than in air!", category: .science, emoji: "🔊", date: Date()),
        FunFact(id: "f61", fact: "Glass is actually a liquid that moves very, very slowly!", category: .science, emoji: "🪟", date: Date()),
        FunFact(id: "f62", fact: "Your nose can remember 50,000 different scents!", category: .science, emoji: "👃", date: Date()),
        FunFact(id: "f63", fact: "Humans share 50% of their DNA with bananas!", category: .science, emoji: "🧬", date: Date()),
        FunFact(id: "f64", fact: "A bolt of lightning contains enough energy to toast 100,000 slices of bread!", category: .science, emoji: "🍞", date: Date()),
        FunFact(id: "f65", fact: "The human body contains enough iron to make a 3-inch nail!", category: .science, emoji: "📌", date: Date()),

        // Ocean Facts
        FunFact(id: "f66", fact: "The ocean covers more than 70% of Earth's surface!", category: .ocean, emoji: "🌊", date: Date()),
        FunFact(id: "f67", fact: "We've explored less than 5% of the ocean!", category: .ocean, emoji: "🔭", date: Date()),
        FunFact(id: "f68", fact: "The longest mountain range on Earth is underwater!", category: .ocean, emoji: "🏔️", date: Date()),
        FunFact(id: "f69", fact: "There are more historical artifacts under the sea than in all museums combined!", category: .ocean, emoji: "🏛️", date: Date()),
        FunFact(id: "f70", fact: "The blue whale's heart is the size of a small car!", category: .ocean, emoji: "🐋", date: Date()),
        FunFact(id: "f71", fact: "Coral reefs are home to 25% of all ocean species!", category: .ocean, emoji: "🪸", date: Date()),
        FunFact(id: "f72", fact: "The Pacific Ocean is wider than the Moon!", category: .ocean, emoji: "🌏", date: Date()),
        FunFact(id: "f73", fact: "There's enough gold in the ocean to give everyone on Earth 9 pounds!", category: .ocean, emoji: "🥇", date: Date()),
        FunFact(id: "f74", fact: "The deepest part of the ocean is deeper than Mount Everest is tall!", category: .ocean, emoji: "📏", date: Date()),
        FunFact(id: "f75", fact: "Sharks have been around longer than trees!", category: .ocean, emoji: "🦈", date: Date()),

        // Body Facts
        FunFact(id: "f76", fact: "Your heart beats about 100,000 times per day!", category: .body, emoji: "❤️", date: Date()),
        FunFact(id: "f77", fact: "You blink about 20,000 times a day!", category: .body, emoji: "👁️", date: Date()),
        FunFact(id: "f78", fact: "Your tongue print is unique, just like your fingerprint!", category: .body, emoji: "👅", date: Date()),
        FunFact(id: "f79", fact: "Babies have about 300 bones, but adults only have 206!", category: .body, emoji: "🦴", date: Date()),
        FunFact(id: "f80", fact: "The human nose can detect over 1 trillion different scents!", category: .body, emoji: "👃", date: Date()),
        FunFact(id: "f81", fact: "Your body has enough blood vessels to wrap around Earth twice!", category: .body, emoji: "🩸", date: Date()),
        FunFact(id: "f82", fact: "Humans are the only animals that blush!", category: .body, emoji: "😊", date: Date()),
        FunFact(id: "f83", fact: "Your ears and nose never stop growing!", category: .body, emoji: "👂", date: Date()),
        FunFact(id: "f84", fact: "The human eye can distinguish about 10 million different colors!", category: .body, emoji: "🌈", date: Date()),
        FunFact(id: "f85", fact: "Your brain generates enough electricity to power a small light bulb!", category: .body, emoji: "💡", date: Date()),

        // Weather Facts
        FunFact(id: "f86", fact: "A snowflake can take up to 1 hour to fall to the ground!", category: .weather, emoji: "❄️", date: Date()),
        FunFact(id: "f87", fact: "The largest recorded snowflake was 15 inches wide!", category: .weather, emoji: "🌨️", date: Date()),
        FunFact(id: "f88", fact: "A single hurricane can release as much energy as 10,000 nuclear bombs!", category: .weather, emoji: "🌀", date: Date()),
        FunFact(id: "f89", fact: "Rainbows are actually full circles, but we only see half from the ground!", category: .weather, emoji: "🌈", date: Date()),
        FunFact(id: "f90", fact: "Lightning strikes Earth about 100 times every second!", category: .weather, emoji: "⛈️", date: Date()),
        FunFact(id: "f91", fact: "The coldest temperature ever recorded was -128.6°F in Antarctica!", category: .weather, emoji: "🥶", date: Date()),
        FunFact(id: "f92", fact: "Tornadoes can spin faster than 300 miles per hour!", category: .weather, emoji: "🌪️", date: Date()),
        FunFact(id: "f93", fact: "It can rain diamonds on Jupiter and Saturn!", category: .weather, emoji: "💎", date: Date()),

        // History Facts
        FunFact(id: "f94", fact: "Cleopatra lived closer in time to the Moon landing than to the building of the pyramids!", category: .history, emoji: "👑", date: Date()),
        FunFact(id: "f95", fact: "The Great Wall of China is NOT visible from space with the naked eye!", category: .history, emoji: "🏯", date: Date()),
        FunFact(id: "f96", fact: "Vikings used to give kittens to new brides as essential household gifts!", category: .history, emoji: "🐱", date: Date()),
        FunFact(id: "f97", fact: "Ancient Egyptians used to shave off their eyebrows to mourn their cats!", category: .history, emoji: "😿", date: Date()),
        FunFact(id: "f98", fact: "The Eiffel Tower can be 15 cm taller during the summer due to heat expansion!", category: .history, emoji: "🗼", date: Date()),
        FunFact(id: "f99", fact: "Oxford University is older than the Aztec Empire!", category: .history, emoji: "🎓", date: Date()),
        FunFact(id: "f100", fact: "The first computer mouse was made of wood!", category: .history, emoji: "🖱️", date: Date()),

        // Geography Facts
        FunFact(id: "f101", fact: "Russia has a larger surface area than Pluto!", category: .geography, emoji: "🗺️", date: Date()),
        FunFact(id: "f102", fact: "Canada has more lakes than the rest of the world combined!", category: .geography, emoji: "🏞️", date: Date()),
        FunFact(id: "f103", fact: "Australia is wider than the Moon!", category: .geography, emoji: "🦘", date: Date()),
        FunFact(id: "f104", fact: "Vatican City is the smallest country in the world - smaller than a golf course!", category: .geography, emoji: "⛪", date: Date()),
        FunFact(id: "f105", fact: "The Amazon River has no bridges across it!", category: .geography, emoji: "🏝️", date: Date()),
        FunFact(id: "f106", fact: "Mount Everest grows about 4 millimeters taller every year!", category: .geography, emoji: "🏔️", date: Date()),
        FunFact(id: "f107", fact: "There's a waterfall in Antarctica that looks like blood!", category: .geography, emoji: "🩸", date: Date()),
        FunFact(id: "f108", fact: "The Dead Sea is so salty you can float without trying!", category: .geography, emoji: "🏊", date: Date()),

        // More Animal Facts
        FunFact(id: "f109", fact: "A cockroach can live for a week without its head!", category: .animals, emoji: "🪳", date: Date()),
        FunFact(id: "f110", fact: "Pigeons can do math at a similar level to monkeys!", category: .animals, emoji: "🐦", date: Date()),
        FunFact(id: "f111", fact: "A woodpecker's tongue wraps around its skull!", category: .animals, emoji: "🪶", date: Date()),
        FunFact(id: "f112", fact: "Starfish don't have blood - they use sea water instead!", category: .animals, emoji: "⭐", date: Date()),
        FunFact(id: "f113", fact: "Wombat poop is cube-shaped!", category: .animals, emoji: "🐻", date: Date()),
        FunFact(id: "f114", fact: "Crows can recognize human faces and hold grudges!", category: .animals, emoji: "🐦‍⬛", date: Date()),
        FunFact(id: "f115", fact: "A group of cats is called a 'clowder'!", category: .animals, emoji: "🐈", date: Date()),
        FunFact(id: "f116", fact: "Honeybees can recognize human faces!", category: .animals, emoji: "🐝", date: Date()),
        FunFact(id: "f117", fact: "Tigers have striped skin, not just striped fur!", category: .animals, emoji: "🐅", date: Date()),
        FunFact(id: "f118", fact: "A flamingo can only eat with its head upside down!", category: .animals, emoji: "🦩", date: Date()),
        FunFact(id: "f119", fact: "Axolotls can regrow their limbs, heart, and even parts of their brain!", category: .animals, emoji: "🦎", date: Date()),
        FunFact(id: "f120", fact: "A group of hedgehogs is called a 'prickle'!", category: .animals, emoji: "🦔", date: Date())
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

    // Get total counts for variety
    var jokeCount: Int { jokes.count }
    var factCount: Int { funFacts.count }
}
