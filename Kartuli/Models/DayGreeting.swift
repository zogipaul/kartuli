import Foundation

/// The Today greeting follows the clock, so learners pick up four real phrases.
enum DayGreeting: CaseIterable {
    case morning, day, evening, night

    init(hour: Int) {
        switch hour {
        case 5..<12: self = .morning
        case 12..<18: self = .day
        case 18..<22: self = .evening
        default: self = .night
        }
    }

    init(date: Date, calendar: Calendar = .autoupdatingCurrent) {
        self.init(hour: calendar.component(.hour, from: date))
    }

    var georgian: String {
        switch self {
        case .morning: "დილა მშვიდობისა!"
        case .day: "დღე მშვიდობისა!"
        case .evening: "საღამო მშვიდობისა!"
        case .night: "ღამე მშვიდობისა!"
        }
    }

    var transliteration: String {
        switch self {
        case .morning: "dila mshvidobisa"
        case .day: "dghe mshvidobisa"
        case .evening: "saghamo mshvidobisa"
        case .night: "ghame mshvidobisa"
        }
    }

    var meaning: LocalizedStringResource {
        switch self {
        case .morning: "Good morning"
        case .day: "Good afternoon"
        case .evening: "Good evening"
        case .night: "Good night"
        }
    }
}
