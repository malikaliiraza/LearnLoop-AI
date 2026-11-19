# LearnLoop AI

> **v0.2.0** (November 2026). A Flutter app that turns the student's own notes into quizzes: it builds questions from what they wrote, and when an answer is wrong, an AI tutor re-explains the concept in simple Urdu or English instead of just saying "wrong". Missed topics come back on a spaced-repetition schedule, so revision happens before the exam, not the night before.

**What makes it different:** most quiz apps ship a fixed question bank. LearnLoop AI quizzes you on *your own* notes — the PDF or pages you are actually studying — and the tutor is the point: a wrong answer triggers a re-explanation in simple language, in English or Roman Urdu, so a student in Pakistan can understand the concept, not just memorise the answer. Spaced repetition (SM-2) then schedules the weak topics to return at the right time.

## What is built now — v0.2.0

- **Real import:** paste notes, import a .txt file, or import a PDF — the PDF's text layer is extracted on-device with a pure-Dart reader (plain and FlateDecode streams, `Tj`/`TJ` operators). A scanned PDF has no text layer and is reported honestly instead of pretending the import worked.
- **Quiz generator (heuristic, v0.2):** finds the note's key terms (words that repeat) and asks two kinds of question — "what does your note say about this term?" and fill-in-the-blank — using the note's own sentences as answers and distractors. A quiz built from an imported PDF works exactly like one from a typed note. A real AI question generator (LLM, from a PDF or pasted notes) is on the roadmap — the current generator is a transparent heuristic, not AI.
- **AI tutor (local templates, v0.2):** after each answer, the tutor re-explains the concept in simple English or Roman Urdu — and when an answer is wrong it names the answer the student actually picked and shows what the note says instead. A real LLM tutor that generates fresh explanations is on the roadmap.
- **Spaced repetition (SM-2), now persisted:** every answered topic is saved on the device — a right answer reschedules it further out (1 day, then 6, then interval × ease factor), a wrong one brings it back tomorrow. The home screen shows how many topics are due, and the review screen offers a short quiz on each due topic alone. Fully implemented and unit-tested.
- **Home screen:** your notes with a "Start quiz" button each, the source of each note (Sample / Pasted / Text file / PDF), and whether it is long enough to quiz on; two sample notes included so the quiz and tutor can be tried immediately.
- **Offline-first storage:** notes and the review schedule are stored on the device with SharedPreferences; no account, backend, or API key needed.

## Roadmap

- Real AI quiz generation and tutor via an LLM, with the same quiz format.
- Weak-topic analytics: which topics you keep missing, and why.
- Urdu interface alongside English; Urdu voice re-explanation.
- Teacher mode: share a note set with a class and track the class's weak topics.

## Architecture

Clean Architecture, feature-first, following the Flutter playbook: `lib/core` holds the theme and constants; each feature under `lib/features/<feature>/` separates data (models, repositories), domain (quiz generator, tutor, spaced repetition), and presentation (screens). State is local `setState` + `SharedPreferences`, the same offline-first approach as the author's Hisaab Kitaab app.

## Run it

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Requires Flutter 3.x and Dart 3.x. No account, backend, or API key is needed — everything runs on the device with sample data.

## License

MIT — see [LICENSE](LICENSE).
