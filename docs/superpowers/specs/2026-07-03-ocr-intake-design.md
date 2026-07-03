# OCR Intake ("Scan" mode)

Date: 2026-07-03
Status: Draft (awaiting review)
Feature branch: `feature/native-english-mvp`

## Goal

Add the fourth intake method from the MVP spec ("四入口录入": batch / single / share / **OCR**):
snap or pick an image, recognize the text, choose which words to keep, and run them
through the existing AI card generation. The Vision kernel already exists and is tested;
this is the UI + wiring to "continue" it.

## Existing building blocks (KaiServices)

- `TextRecognizer` protocol + `VisionTextRecognizer` — `recognizeLines(in imageData: Data)
  async throws -> [String]` (Vision, accurate, language-corrected).
- `WordCandidateExtractor.candidates(from lines:)` — deduped, lowercased, letters-only,
  min-length-2 single-word candidates. Unit-tested.
- `EntrySource` already has an `.ocr` case.

## Design

### Entry point — a third mode in `AddWordsView`

Extend the existing mode picker to **Single / Batch / Scan**, so scanned words reuse the
same (chunked, best-effort) generation path. No new screen or tab.

### Scan flow

1. **Source buttons:** "Take photo" (camera) and "Choose from library" (`PhotosPicker`,
   which also surfaces screenshots).
   - Library: `PhotosPicker` → `PhotosPickerItem.loadTransferable(type: Data.self)`.
   - Camera: a small `CameraPicker` (`UIViewControllerRepresentable` over
     `UIImagePickerController`, `sourceType: .camera`) returning a `UIImage` → `jpegData`.
     The camera button is hidden when `UIImagePickerController.isSourceTypeAvailable(.camera)`
     is false (e.g. simulator).
2. **Recognize:** on image `Data`, run `VisionTextRecognizer().recognizeLines(in:)` then
   `WordCandidateExtractor().candidates(from:)`, showing a spinner. Errors → `toast.error`
   (also logged) and stay on the form.
3. **Select:** candidates render as tappable chips in a `LazyVGrid` (adaptive), **all
   selected by default**; tapping toggles. A count shows "N selected".
4. **Generate:** the `lemmas` computed property returns the selected candidates in Scan
   mode; the existing `run()` generates and inserts them, tagged `source: .ocr`.

### Supporting changes

- `AICardMapper.entry(from:language:source:now:)` gains a `source` parameter (default
  `.single`); `run()` passes `.ocr` in Scan mode, `.single` otherwise.
- `Project.swift`: add `NSCameraUsageDescription` to the app target's `infoPlist`
  (`.extendingDefault`). Re-run `tuist generate`. (PhotosPicker needs no permission string.)

### State (in `AddWordsView`)

```swift
@State private var candidates: [String] = []
@State private var selectedCandidates: Set<String> = []
@State private var recognizing = false
@State private var pickedItem: PhotosPickerItem?
@State private var showingCamera = false
```

`Mode` gains `.scan`. `lemmas` returns `Array(selectedCandidates)` (in candidate order) for
`.scan`. `canGenerate` already gates on `!lemmas.isEmpty`, so it works unchanged.

## Testing

- `WordCandidateExtractor` — already unit-tested (dedupe, min length, punctuation strip).
- **App suite:** `AICardMapper` gains a case asserting `source: .ocr` propagates onto the
  entry (and that the default stays `.single`).
- `VisionTextRecognizer`, `CameraPicker`, and the Scan UI are compiled but not unit-tested,
  per the KaiServices "protocol + pure logic tested + thin platform adapter compiled" pattern.
- Manual: pick a screenshot in the simulator → candidates appear → select → generate.

## Non-goals

- Region-of-interest cropping or live text scanning (`DataScannerViewController`) — a still
  image is enough for MVP.
- Multi-word phrase detection from OCR — candidates are single words (extractor already
  filters to single tokens); phrases stay a manual/batch concern.
- The system **share extension** intake (separate target) — tracked separately.

## Open questions

None outstanding.
