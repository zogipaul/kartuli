import Foundation

struct GeorgianLetter: Identifiable, Hashable {
    let id: Int
    let glyph: String
    let name: String
    /// National romanization, the same system used for every word in the app.
    let sound: String
    let example: String
    let translation: LocalizedStringResource
    let unit: Int

    /// The apostrophe marks an ejective consonant (k', p', t', q', ts', ch').
    var isEjective: Bool { sound.hasSuffix("'") }

    /// How VoiceOver announces the letter instead of an unpronounceable glyph.
    var spokenName: LocalizedStringResource { "Letter \(name)" }

    static func == (lhs: GeorgianLetter, rhs: GeorgianLetter) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    static func spokenName(for glyph: String) -> LocalizedStringResource {
        all.first { $0.glyph == glyph }?.spokenName ?? "Letter \(glyph)"
    }

    static func quizOptions(for answer: GeorgianLetter) -> [GeorgianLetter] {
        let distractors = all.filter { $0.id != answer.id }.shuffled().prefix(3)
        return ([answer] + distractors).shuffled()
    }

    static let all: [GeorgianLetter] = {
        let rows: [(String, String, String, String, LocalizedStringResource)] = [
            ("ა", "ani", "a", "ამბავი", "Story"), ("ბ", "bani", "b", "ბაღი", "Garden"),
            ("გ", "gani", "g", "გული", "Heart"), ("დ", "doni", "d", "დედა", "Mother"),
            ("ე", "eni", "e", "ენა", "Language"), ("ვ", "vini", "v", "ვაშლი", "Apple"),
            ("ზ", "zeni", "z", "ზღვა", "Sea"), ("თ", "tani", "t", "თოვლი", "Snow"),
            ("ი", "ini", "i", "იმედი", "Hope"), ("კ", "k'ani", "k'", "კაცი", "Man"),
            ("ლ", "lasi", "l", "ლამაზი", "Beautiful"), ("მ", "mani", "m", "მზე", "Sun"),
            ("ნ", "nari", "n", "ნინო", "Nino"), ("ო", "oni", "o", "ოჯახი", "Family"),
            ("პ", "p'ari", "p'", "პური", "Bread"), ("ჟ", "zhani", "zh", "ჟოლო", "Raspberry"),
            ("რ", "rae", "r", "რაჭა", "Racha"), ("ს", "sani", "s", "სახლი", "House"),
            ("ტ", "t'ari", "t'", "ტბა", "Lake"), ("უ", "uni", "u", "უცხო", "Foreign"),
            ("ფ", "pari", "p", "ფერი", "Color"), ("ქ", "kani", "k", "ქარი", "Wind"),
            ("ღ", "ghani", "gh", "ღამე", "Night"), ("ყ", "q'ari", "q'", "ყავა", "Coffee"),
            ("შ", "shini", "sh", "შავი", "Black"), ("ჩ", "chini", "ch", "ჩაი", "Tea"),
            ("ც", "tsani", "ts", "ცა", "Sky"), ("ძ", "dzili", "dz", "ძმა", "Brother"),
            ("წ", "ts'ili", "ts'", "წყალი", "Water"), ("ჭ", "ch'ari", "ch'", "ჭიქა", "Glass"),
            ("ხ", "khani", "kh", "ხაჭაპური", "Khachapuri"), ("ჯ", "jani", "j", "ჯაზი", "Jazz"),
            ("ჰ", "hae", "h", "ჰაერი", "Air")
        ]
        return rows.enumerated().map { index, row in
            GeorgianLetter(id: index, glyph: row.0, name: row.1, sound: row.2,
                           example: row.3, translation: row.4, unit: min(index / 7 + 1, 5))
        }
    }()
}

struct LearningUnit: Identifiable {
    let id: Int
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource
    let icon: String
    let colorName: String

    static let all = [
        LearningUnit(id: 1, title: "First shapes", subtitle: "Your first 7 letters", icon: "sparkles", colorName: "coral"),
        LearningUnit(id: 2, title: "Smooth sounds", subtitle: "Letters 8–14", icon: "waveform", colorName: "violet"),
        LearningUnit(id: 3, title: "Bold & bright", subtitle: "Letters 15–21", icon: "sun.max.fill", colorName: "yellow"),
        LearningUnit(id: 4, title: "Tricky twins", subtitle: "Letters 22–28", icon: "eyes", colorName: "mint"),
        LearningUnit(id: 5, title: "Final flourish", subtitle: "The last 5 letters", icon: "flag.checkered", colorName: "blue")
    ]
}

enum WordCategory: CaseIterable {
    case phrases, people, foodAndDrink, places, nature, animals, time, numbers, everyday

    var title: LocalizedStringResource {
        switch self {
        case .phrases: "Phrases"
        case .people: "People"
        case .foodAndDrink: "Food & drink"
        case .places: "Places"
        case .nature: "Nature"
        case .animals: "Animals"
        case .time: "Time"
        case .numbers: "Numbers"
        case .everyday: "Everyday"
        }
    }
}

struct GeorgianWord: Identifiable, Hashable {
    let id: Int
    let text: String
    let transliteration: String
    let translation: LocalizedStringResource
    let category: WordCategory

    var letters: [String] { text.map(String.init) }

    static func == (lhs: GeorgianWord, rhs: GeorgianWord) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    static let all = [
        GeorgianWord(id: 0, text: "დედა", transliteration: "deda", translation: "Mother", category: .people),
        GeorgianWord(id: 1, text: "მამა", transliteration: "mama", translation: "Father", category: .people),
        GeorgianWord(id: 2, text: "ენა", transliteration: "ena", translation: "Language", category: .everyday),
        GeorgianWord(id: 3, text: "გული", transliteration: "guli", translation: "Heart", category: .everyday),
        GeorgianWord(id: 4, text: "მზე", transliteration: "mze", translation: "Sun", category: .nature),
        GeorgianWord(id: 5, text: "ზღვა", transliteration: "zghva", translation: "Sea", category: .nature),
        GeorgianWord(id: 6, text: "სახლი", transliteration: "sakhli", translation: "House", category: .places),
        GeorgianWord(id: 7, text: "ოჯახი", transliteration: "ojakhi", translation: "Family", category: .people),
        GeorgianWord(id: 8, text: "პური", transliteration: "p'uri", translation: "Bread", category: .foodAndDrink),
        GeorgianWord(id: 9, text: "ჩაი", transliteration: "chai", translation: "Tea", category: .foodAndDrink),
        GeorgianWord(id: 10, text: "ყავა", transliteration: "q'ava", translation: "Coffee", category: .foodAndDrink),
        GeorgianWord(id: 11, text: "წყალი", transliteration: "ts'q'ali", translation: "Water", category: .foodAndDrink),
        GeorgianWord(id: 12, text: "გამარჯობა", transliteration: "gamarjoba", translation: "Hello", category: .phrases),
        GeorgianWord(id: 13, text: "ნახვამდის", transliteration: "nakhvamdis", translation: "Goodbye", category: .phrases),
        GeorgianWord(id: 14, text: "კი", transliteration: "k'i", translation: "Yes", category: .phrases),
        GeorgianWord(id: 15, text: "არა", transliteration: "ara", translation: "No", category: .phrases),
        GeorgianWord(id: 16, text: "გთხოვთ", transliteration: "gtkhovt", translation: "Please", category: .phrases),
        GeorgianWord(id: 17, text: "მადლობა", transliteration: "madloba", translation: "Thank you", category: .phrases),
        GeorgianWord(id: 18, text: "ბოდიში", transliteration: "bodishi", translation: "Sorry", category: .phrases),
        GeorgianWord(id: 19, text: "მეგობარი", transliteration: "megobari", translation: "Friend", category: .people),
        GeorgianWord(id: 20, text: "სიყვარული", transliteration: "siq'varuli", translation: "Love", category: .people),
        GeorgianWord(id: 21, text: "წიგნი", transliteration: "ts'igni", translation: "Book", category: .everyday),
        GeorgianWord(id: 22, text: "სკოლა", transliteration: "sk'ola", translation: "School", category: .places),
        GeorgianWord(id: 23, text: "ქალაქი", transliteration: "kalaki", translation: "City", category: .places),
        GeorgianWord(id: 24, text: "სოფელი", transliteration: "sopeli", translation: "Village", category: .places),
        GeorgianWord(id: 25, text: "ქვეყანა", transliteration: "kveq'ana", translation: "Country", category: .places),
        GeorgianWord(id: 26, text: "საქართველო", transliteration: "sakartvelo", translation: "Georgia", category: .places),
        GeorgianWord(id: 27, text: "თბილისი", transliteration: "tbilisi", translation: "Tbilisi", category: .places),
        GeorgianWord(id: 28, text: "მთა", transliteration: "mta", translation: "Mountain", category: .nature),
        GeorgianWord(id: 29, text: "მდინარე", transliteration: "mdinare", translation: "River", category: .nature),
        GeorgianWord(id: 30, text: "ხე", transliteration: "khe", translation: "Tree", category: .nature),
        GeorgianWord(id: 31, text: "ყვავილი", transliteration: "q'vavili", translation: "Flower", category: .nature),
        GeorgianWord(id: 32, text: "ძაღლი", transliteration: "dzaghli", translation: "Dog", category: .animals),
        GeorgianWord(id: 33, text: "კატა", transliteration: "k'at'a", translation: "Cat", category: .animals),
        GeorgianWord(id: 34, text: "ჩიტი", transliteration: "chit'i", translation: "Bird", category: .animals),
        GeorgianWord(id: 35, text: "დღე", transliteration: "dghe", translation: "Day", category: .time),
        GeorgianWord(id: 36, text: "ღამე", transliteration: "ghame", translation: "Night", category: .time),
        GeorgianWord(id: 37, text: "დილა", transliteration: "dila", translation: "Morning", category: .time),
        GeorgianWord(id: 38, text: "საღამო", transliteration: "saghamo", translation: "Evening", category: .time),
        GeorgianWord(id: 39, text: "დღეს", transliteration: "dghes", translation: "Today", category: .time),
        GeorgianWord(id: 40, text: "ხვალ", transliteration: "khval", translation: "Tomorrow", category: .time),
        GeorgianWord(id: 41, text: "ერთი", transliteration: "erti", translation: "One", category: .numbers),
        GeorgianWord(id: 42, text: "ორი", transliteration: "ori", translation: "Two", category: .numbers),
        GeorgianWord(id: 43, text: "სამი", transliteration: "sami", translation: "Three", category: .numbers),
        GeorgianWord(id: 44, text: "ოთხი", transliteration: "otkhi", translation: "Four", category: .numbers),
        GeorgianWord(id: 45, text: "ხუთი", transliteration: "khuti", translation: "Five", category: .numbers),
        GeorgianWord(id: 46, text: "ყველი", transliteration: "q'veli", translation: "Cheese", category: .foodAndDrink),
        GeorgianWord(id: 47, text: "ღვინო", transliteration: "ghvino", translation: "Wine", category: .foodAndDrink),
        GeorgianWord(id: 48, text: "ვაშლი", transliteration: "vashli", translation: "Apple", category: .foodAndDrink),
        GeorgianWord(id: 49, text: "ყურძენი", transliteration: "q'urdzeni", translation: "Grape", category: .foodAndDrink)
    ]
}
