import Foundation

struct GeorgianLetter: Identifiable, Hashable {
    let id: Int
    let glyph: String
    let name: String
    let sound: String
    let example: String
    let translation: String
    let unit: Int

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

