# Sudoku

A personal, ad-supported-free, App-Store-free Sudoku puzzle app for iOS, built in SwiftUI. iPhone-only, iOS 17+. Intended for personal sideloading via a free Apple Developer account.

## Features

- Algorithmic puzzle generation with **guaranteed unique solutions** (backtracking solver + uniqueness check).
- Three difficulties: Easy (38–45 givens), Medium (30–37), Hard (22–29).
- Pencil notes mode with auto-remove on peer placement.
- Conflict highlighting (toggleable), row/col/box peer highlighting, matching-value highlighting.
- Full undo/redo of every move (including auto-cleared notes).
- 3 hints per game.
- Pause-on-background timer.
- Local persistence: in-progress game survives quits; best times per difficulty.
- Light haptics on input, success on solve.
- **Themes**: 6 presets (Classic, Midnight, Sakura, Ocean, Forest, Zen Garden), each with gradient or optional photo background. Picker accessible from menu *and* the in-game settings sheet.
- Dark mode automatic (handled via theme palettes).

## Building the project in Xcode

These source files are not a `.xcodeproj` — Xcode 15/16 doesn't need one shipped in git. Create the project on your Mac like this:

1. **Create a new Xcode project**
   - Open Xcode 15 or 16.
   - File → New → Project → iOS → **App**.
   - Product Name: `Sudoku`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (we use plain UserDefaults; no Core Data / SwiftData required).
   - Save it somewhere convenient on your Mac.

2. **Drop in the source files**
   - In Finder, open the `Sudoku/` folder from this project.
   - Delete the default `ContentView.swift`, `SudokuApp.swift`, and `Assets.xcassets` that Xcode generated.
   - Drag the `Models/`, `ViewModels/`, `Views/`, `Utilities/` folders, the included **`Assets.xcassets`** folder (it has all four theme background photos already wired up), and the two top-level files (`SudokuApp.swift`, `ContentView.swift`) from this project into Xcode's project navigator.
   - When prompted: ✅ Copy items if needed, ✅ Create groups, ✅ Add to target "Sudoku".
   - Note: after replacing `Assets.xcassets`, re-create an **AccentColor** color set in it (Xcode normally generates this — right-click → New Color Set → name it `AccentColor` → pick your preferred blue in the Attributes inspector).

3. **Set the deployment target**
   - Click the project root in the navigator → Sudoku target → General tab.
   - **Minimum Deployments → iOS**: `17.0`.

4. **Configure Personal Team signing (for sideloading)**
   - Project root → Sudoku target → **Signing & Capabilities**.
   - ✅ **Automatically manage signing**.
   - **Team**: select your personal Apple ID team (sign into Xcode → Settings → Accounts first if you haven't).
   - **Bundle Identifier**: anything unique to you, e.g. `com.matthewbeigel.sudoku`. (Free accounts don't get wildcard IDs, so make it specific.)

5. **Build & run on your iPhone**
   - Plug in your iPhone via USB. Trust the computer on the phone if prompted.
   - In Xcode, select your iPhone as the run destination (top of the window).
   - Press ⌘R.
   - On first run, the phone will refuse to launch the app — go to **Settings → General → VPN & Device Management** on your phone, find your developer profile, and tap **Trust**.
   - Re-launch from the home screen.

**Note on free-account limits**: apps sideloaded with a free Apple ID expire after **7 days**. Just re-build and re-deploy from Xcode whenever you want to keep playing. The in-progress game and stats live in UserDefaults so they don't survive a reinstall — easy to relax to JSON-on-disk later if that becomes annoying.

## Theme background photos (already included)

Four of the six themes ship with a peaceful background photo, pre-downloaded and wired up inside `Sudoku/Assets.xcassets/`:

| Theme   | Image                                  | Source                                 | License        |
| ------- | -------------------------------------- | -------------------------------------- | -------------- |
| Sakura  | Mt. Hiei with cherry blossoms (Kyoto)  | Wikimedia Commons                      | CC0 / Public domain |
| Ocean   | Sunrise over the ocean (Dong Hae, KR)  | Wikimedia Commons                      | CC0 / Public domain |
| Forest  | Sun's rays in a dense forest (Filip Varga) | Wikimedia Commons (originally Unsplash, pre-2017) | CC0 / Public domain |
| Zen     | Ryōan-ji rock garden (Kyoto), 2018     | Bjørn Christian Tørrissen via Wikimedia Commons | CC BY-SA 4.0   |

Direct source pages:
- Sakura: https://commons.wikimedia.org/wiki/File:Mt_Hiei_with_Cherry_Blossom.JPG
- Ocean: https://commons.wikimedia.org/wiki/File:Sunrise_at_ocean.JPG
- Forest: https://commons.wikimedia.org/wiki/File:Sun%27s_rays_in_a_dense_forest_(Unsplash).jpg
- Zen: https://commons.wikimedia.org/wiki/File:Ryoan-ji-Garden-2018.jpg

**Attribution note**: the Zen image is **CC BY-SA 4.0**, which requires attribution and share-alike. For personal sideloaded use this is fine — but if you ever want to distribute the app, either credit Bjørn Christian Tørrissen in an in-app About screen and license the app source compatibly, or swap that image for a CC0 alternative (the other three are CC0, no strings attached).

When you drag `Assets.xcassets` into your Xcode project, all four image sets show up automatically with the correct names (`theme-sakura`, `theme-ocean`, `theme-forest`, `theme-zen`) and no further setup. If you want to swap any image for a different photo: open the image set in Xcode, delete the existing JPEG, drag a new landscape JPEG (~2000px on the long edge ideal) into the 1x slot.

## Architecture (quick orientation)

- **Models/** — Pure data + algorithms. `SudokuPuzzle` (board + conflict logic), `PuzzleGenerator` (uniqueness-checked generation), `GameState` (session state + persistence).
- **ViewModels/** — `GameViewModel` is the only one. `@Observable`, owns the model, exposes intent methods.
- **Views/** — SwiftUI. `MenuView` is the entry; `GameView` is gameplay; reusable pieces are `BoardView`, `CellView`, `NumberPadView`, `ThemePickerView`, `SettingsSheetView`, `StatsView`.
- **Utilities/** — `ColorTheme.swift` (the full theme system + presets + `ThemeManager`) and `HapticsManager.swift`.
- **App entry** — `SudokuApp.swift` constructs the `GameViewModel` and `ThemeManager`, injects them via SwiftUI environment, and handles scene-phase pause/resume.

No external dependencies. No SPM packages. No Core Data. Just Foundation + SwiftUI + UIKit (for haptics + asset image lookup).
