# Kartuli — Georgian, one letter at a time

Kartuli is a playful iOS 26 learning app concept for building confidence with the
33-letter Georgian alphabet. The navigation language is English; Georgian is
introduced through large, tactile letter cards, transliteration, pronunciation hints and
short daily challenges.

## Product concept

The daily loop is deliberately small: learn three letters, recognize them in a
multiple-choice challenge, earn 30 XP, and secure the day's streak. A complete alphabet map
makes progress tangible while short themed units turn the script into a path
instead of a reference chart.

- **Today:** a greeting that follows the time of day (დილა / დღე / საღამო / ღამე
  მშვიდობისა), daily goal, streak, XP, and the next lesson.
- **Learn:** a five-unit path through all 33 Mkhedruli letters, the practice
  modes, and a searchable list of words.
- **Alphabet:** filterable reference grid with learned/new states.
- **Endless Practice:** an unlimited mixed quiz across all 33 letters with
  accuracy, combos, instant feedback and a session summary.
- **Profile:** weekly activity, achievements, appearance (System, Light, Dark),
  and a daily notification reminder.
- **Widget:** a small or medium Home Screen view of the current learning streak.
- **Lesson:** reveal a letter, say it aloud, view a memory hook, then answer a
  randomized recognition question with immediate feedback.

A streak day has one fixed rule: earn 30 XP. Completing a lesson awards 30 XP;
each correct Endless Mode answer awards 2 XP, so 15 correct answers also secure
the day. Incorrect answers award no XP.

The visual direction combines a warm Georgian red with lavender and mint,
oversized typography, soft gradients, friendly microcopy, and native Liquid
Glass surfaces. It uses only SwiftUI and SF Symbols. Custom type sizes follow Dynamic Type, and
Georgian glyphs have VoiceOver labels with the letter name.

The app and widget are localized in English and German through String Catalogs
(`Localizable.xcstrings`). Letters and words use one romanization, the Georgian
national system, where an apostrophe marks an ejective (k', p', t', q', ts', ch').

On a fresh launch, a short SwiftUI intro brings the app-icon artwork into an orbit
of Georgian letters, followed by a light sweep and a soft transition into Today.
Tap anywhere to skip. Reduce Motion uses a brief static treatment, and returning
from the background does not replay the intro. The native launch screen shares
the intro's background color.

## Run

Open `Kartuli.xcodeproj` in Xcode 26 and run the `Kartuli` scheme on an iOS 26
simulator. No packages or external dependencies are required.

## QA

Run `scripts/qa.sh` with full Xcode installed. It runs the unit and UI suites,
then builds the app and widget in Release for iOS without signing. Override the
simulator with `QA_DESTINATION='platform=iOS Simulator,id=<UDID>'` and optionally
set `QA_DERIVED_DATA` (default: `/tmp/kartuli-local-qa`). Xcode's `Kartuli` shared
scheme also supports Test directly.

The tests cover XP thresholds, unlocks, persistence, midnight and DST changes,
widget expiry, redundant writes/reloads, quiz choices, complete lesson flows,
and practice navigation at the largest accessibility text size. UI fixtures
use isolated preferences and do not replace normal learning progress. Screenshots
and timing measurements are retained in the `.xcresult` under DerivedData.
The history benchmark compares the original linear scan with the indexed lookup
using 3,651 activity days; this is a stress scenario, not a launch/FPS benchmark.

Verified locally on 2026-10-26: 16 unit tests and 3 UI tests passed, including
maximum accessibility text size on iPhone 17 Pro; the unsigned iOS Release
build of app and widget passed. The final Debug simulator benchmark on iPhone
17 Pro / iOS 26.5 took 3,367 ms for 100 original week lookups versus 2.1 ms for
the indexed implementation with 3,651 activity dates. These are algorithm timings,
not physical-device frame-rate, battery, or launch-time measurements.
