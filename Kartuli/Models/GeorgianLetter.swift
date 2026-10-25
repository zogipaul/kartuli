import Foundation

struct GeorgianLetter: Identifiable, Hashable {
    let id: Int
    let glyph: String
    let name: String
    let sound: String
    let example: String
    let translation: String
    let unit: Int

    static func quizOptions(for answer: GeorgianLetter) -> [GeorgianLetter] {
        let distractors = all.filter { $0.id != answer.id }.shuffled().prefix(3)
        return ([answer] + distractors).shuffled()
    }

    static let all: [GeorgianLetter] = {
        let rows: [(String, String, String, String, String)] = [
            ("ა", "ani", "a", "ამბავი", "story"), ("ბ", "bani", "b", "ბაღი", "garden"),
            ("გ", "gani", "g", "გული", "heart"), ("დ", "doni", "d", "დედა", "mother"),
            ("ე", "eni", "e", "ენა", "language"), ("ვ", "vini", "v", "ვაშლი", "apple"),
            ("ზ", "zeni", "z", "ზღვა", "sea"), ("თ", "tani", "tʰ", "თოვლი", "snow"),
            ("ი", "ini", "i", "იმედი", "hope"), ("კ", "k'ani", "kʼ", "კაცი", "man"),
            ("ლ", "lasi", "l", "ლამაზი", "beautiful"), ("მ", "mani", "m", "მზე", "sun"),
            ("ნ", "nari", "n", "ნინო", "Nino"), ("ო", "oni", "o", "ოჯახი", "family"),
            ("პ", "p'ari", "pʼ", "პური", "bread"), ("ჟ", "zhani", "zh", "ჟოლო", "raspberry"),
            ("რ", "rae", "r", "რაჭა", "Racha"), ("ს", "sani", "s", "სახლი", "house"),
            ("ტ", "t'ari", "tʼ", "ტბა", "lake"), ("უ", "uni", "u", "უცხო", "foreign"),
            ("ფ", "pari", "pʰ", "ფერი", "color"), ("ქ", "kani", "kʰ", "ქარი", "wind"),
            ("ღ", "ghani", "gh", "ღამე", "night"), ("ყ", "q'ari", "qʼ", "ყავა", "coffee"),
            ("შ", "shini", "sh", "შავი", "black"), ("ჩ", "chini", "ch", "ჩაი", "tea"),
            ("ც", "tsani", "ts", "ცა", "sky"), ("ძ", "dzili", "dz", "ძმა", "brother"),
            ("წ", "ts'ili", "tsʼ", "წყალი", "water"), ("ჭ", "ch'ari", "chʼ", "ჭიქა", "glass"),
            ("ხ", "khani", "kh", "ხაჭაპური", "khachapuri"), ("ჯ", "jani", "j", "ჯაზი", "jazz"),
            ("ჰ", "hae", "h", "ჰაერი", "air")
        ]
        return rows.enumerated().map { index, row in
            GeorgianLetter(id: index, glyph: row.0, name: row.1, sound: row.2,
                           example: row.3, translation: row.4, unit: min(index / 7 + 1, 5))
        }
    }()
}

struct LearningUnit: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
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

struct GeorgianWord: Identifiable, Hashable {
    let id: Int
    let text: String
    let transliteration: String
    let translation: String
    let category: String

    var letters: [String] { text.map(String.init) }

    static let categories = [
        "Phrases", "People", "Food & drink", "Places", "Nature",
        "Animals", "Time", "Numbers", "Everyday"
    ]

    static let all = [
        GeorgianWord(id: 0, text: "დედა", transliteration: "deda", translation: "mother", category: "People"),
        GeorgianWord(id: 1, text: "მამა", transliteration: "mama", translation: "father", category: "People"),
        GeorgianWord(id: 2, text: "ენა", transliteration: "ena", translation: "language", category: "Everyday"),
        GeorgianWord(id: 3, text: "გული", transliteration: "guli", translation: "heart", category: "Everyday"),
        GeorgianWord(id: 4, text: "მზე", transliteration: "mze", translation: "sun", category: "Nature"),
        GeorgianWord(id: 5, text: "ზღვა", transliteration: "zghva", translation: "sea", category: "Nature"),
        GeorgianWord(id: 6, text: "სახლი", transliteration: "sakhli", translation: "house", category: "Places"),
        GeorgianWord(id: 7, text: "ოჯახი", transliteration: "ojakhi", translation: "family", category: "People"),
        GeorgianWord(id: 8, text: "პური", transliteration: "puri", translation: "bread", category: "Food & drink"),
        GeorgianWord(id: 9, text: "ჩაი", transliteration: "chai", translation: "tea", category: "Food & drink"),
        GeorgianWord(id: 10, text: "ყავა", transliteration: "q'ava", translation: "coffee", category: "Food & drink"),
        GeorgianWord(id: 11, text: "წყალი", transliteration: "ts'q'ali", translation: "water", category: "Food & drink"),
        GeorgianWord(id: 12, text: "გამარჯობა", transliteration: "gamarjoba", translation: "hello", category: "Phrases"),
        GeorgianWord(id: 13, text: "ნახვამდის", transliteration: "nakhvamdis", translation: "goodbye", category: "Phrases"),
        GeorgianWord(id: 14, text: "კი", transliteration: "ki", translation: "yes", category: "Phrases"),
        GeorgianWord(id: 15, text: "არა", transliteration: "ara", translation: "no", category: "Phrases"),
        GeorgianWord(id: 16, text: "გთხოვთ", transliteration: "gtkhovt", translation: "please", category: "Phrases"),
        GeorgianWord(id: 17, text: "მადლობა", transliteration: "madloba", translation: "thank you", category: "Phrases"),
        GeorgianWord(id: 18, text: "ბოდიში", transliteration: "bodishi", translation: "sorry", category: "Phrases"),
        GeorgianWord(id: 19, text: "მეგობარი", transliteration: "megobari", translation: "friend", category: "People"),
        GeorgianWord(id: 20, text: "სიყვარული", transliteration: "siq'varuli", translation: "love", category: "People"),
        GeorgianWord(id: 21, text: "წიგნი", transliteration: "ts'igni", translation: "book", category: "Everyday"),
        GeorgianWord(id: 22, text: "სკოლა", transliteration: "skola", translation: "school", category: "Places"),
        GeorgianWord(id: 23, text: "ქალაქი", transliteration: "kalaki", translation: "city", category: "Places"),
        GeorgianWord(id: 24, text: "სოფელი", transliteration: "sopeli", translation: "village", category: "Places"),
        GeorgianWord(id: 25, text: "ქვეყანა", transliteration: "kveq'ana", translation: "country", category: "Places"),
        GeorgianWord(id: 26, text: "საქართველო", transliteration: "sakartvelo", translation: "Georgia", category: "Places"),
        GeorgianWord(id: 27, text: "თბილისი", transliteration: "tbilisi", translation: "Tbilisi", category: "Places"),
        GeorgianWord(id: 28, text: "მთა", transliteration: "mta", translation: "mountain", category: "Nature"),
        GeorgianWord(id: 29, text: "მდინარე", transliteration: "mdinare", translation: "river", category: "Nature"),
        GeorgianWord(id: 30, text: "ხე", transliteration: "khe", translation: "tree", category: "Nature"),
        GeorgianWord(id: 31, text: "ყვავილი", transliteration: "q'vavili", translation: "flower", category: "Nature"),
        GeorgianWord(id: 32, text: "ძაღლი", transliteration: "dzaghli", translation: "dog", category: "Animals"),
        GeorgianWord(id: 33, text: "კატა", transliteration: "kata", translation: "cat", category: "Animals"),
        GeorgianWord(id: 34, text: "ჩიტი", transliteration: "chiti", translation: "bird", category: "Animals"),
        GeorgianWord(id: 35, text: "დღე", transliteration: "dghe", translation: "day", category: "Time"),
        GeorgianWord(id: 36, text: "ღამე", transliteration: "ghame", translation: "night", category: "Time"),
        GeorgianWord(id: 37, text: "დილა", transliteration: "dila", translation: "morning", category: "Time"),
        GeorgianWord(id: 38, text: "საღამო", transliteration: "saghamo", translation: "evening", category: "Time"),
        GeorgianWord(id: 39, text: "დღეს", transliteration: "dghes", translation: "today", category: "Time"),
        GeorgianWord(id: 40, text: "ხვალ", transliteration: "khval", translation: "tomorrow", category: "Time"),
        GeorgianWord(id: 41, text: "ერთი", transliteration: "erti", translation: "one", category: "Numbers"),
        GeorgianWord(id: 42, text: "ორი", transliteration: "ori", translation: "two", category: "Numbers"),
        GeorgianWord(id: 43, text: "სამი", transliteration: "sami", translation: "three", category: "Numbers"),
        GeorgianWord(id: 44, text: "ოთხი", transliteration: "otkhi", translation: "four", category: "Numbers"),
        GeorgianWord(id: 45, text: "ხუთი", transliteration: "khuti", translation: "five", category: "Numbers"),
        GeorgianWord(id: 46, text: "ყველი", transliteration: "q'veli", translation: "cheese", category: "Food & drink"),
        GeorgianWord(id: 47, text: "ღვინო", transliteration: "ghvino", translation: "wine", category: "Food & drink"),
        GeorgianWord(id: 48, text: "ვაშლი", transliteration: "vashli", translation: "apple", category: "Food & drink"),
        GeorgianWord(id: 49, text: "ყურძენი", transliteration: "q'urdzeni", translation: "grape", category: "Food & drink")
    ]
}
