//
//  ColorTheme.swift
//  Sudoku
//
//  The full theming system: a `Theme` value type containing every color the
//  app uses plus an optional background image, a `ThemeManager` observable
//  object that holds the active theme and persists it across launches, and
//  a curated set of preset themes (light/dark color palettes + photo themes).
//
//  Photo themes reference image assets by name (e.g. "theme-sakura"). If the
//  asset isn't in the bundle, the theme falls back to its gradient automatically
//  — so the app still looks intentional even before you've added the photos.
//  See README for which image names to drop into Assets.xcassets.
//
//  Views consume the active theme via SwiftUI's environment:
//      @Environment(ThemeManager.self) private var themeManager
//      themeManager.current.cellBackground
//

import SwiftUI
import Observation

// MARK: - Theme

/// Every color and background asset the app needs in one place.
struct Theme: Identifiable, Hashable {
    let id: String
    let displayName: String

    // Optional photo background. If `nil` (or asset missing), the gradient
    // or solid background is used instead.
    let backgroundImageName: String?
    /// Soft fallback / always-on gradient. Used when there's no image.
    let backgroundGradient: [Color]
    /// Tint laid on top of the background image to keep the board legible.
    let backgroundTint: Color
    let backgroundTintOpacity: Double

    // Surfaces
    let surface: Color

    // Cells
    let cellBackground: Color
    let cellSelected: Color
    let cellPeerHighlight: Color
    let cellSameValue: Color

    // Grid lines
    let gridThin: Color
    let gridThick: Color

    // Digits
    let givenDigit: Color
    let userDigit: Color
    let conflictDigit: Color
    let noteDigit: Color

    // Controls
    let numberPadButton: Color
    let numberPadButtonDisabled: Color
    let accent: Color
}

// MARK: - Background view

extension Theme {
    /// Renders the theme's full-screen background: image if present in the
    /// asset catalog, otherwise the gradient. Tinted for legibility.
    @ViewBuilder
    func backgroundView() -> some View {
        ZStack {
            // Always-on gradient as the base layer.
            LinearGradient(
                colors: backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Optional image layered on top (only if user has added the asset).
            if let name = backgroundImageName, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .overlay(backgroundTint.opacity(backgroundTintOpacity))
            }
        }
    }

    /// `true` if this theme uses (or wants to use) a photo background. The
    /// number pad / toolbar can use this to slightly bump background opacity
    /// for legibility.
    var hasImageBackground: Bool { backgroundImageName != nil }
}

// MARK: - Presets

extension Theme {

    /// All themes shown in the picker, in display order.
    static let allPresets: [Theme] = [
        .classic,
        .midnight,
        .sakura,
        .ocean,
        .forest,
        .zenGarden,
    ]

    // Plain palettes ------------------------------------------------------

    static let classic = Theme(
        id: "classic",
        displayName: "Classic",
        backgroundImageName: nil,
        backgroundGradient: [Color(uiColor: .systemBackground), Color(uiColor: .systemBackground)],
        backgroundTint: .clear,
        backgroundTintOpacity: 0,
        surface: Color(uiColor: .secondarySystemBackground),
        cellBackground: Color(uiColor: .systemBackground),
        cellSelected: Color.blue.opacity(0.30),
        cellPeerHighlight: Color.blue.opacity(0.08),
        cellSameValue: Color.blue.opacity(0.18),
        gridThin: Color.secondary.opacity(0.35),
        gridThick: Color.primary,
        givenDigit: Color.primary,
        userDigit: Color.blue,
        conflictDigit: Color.red,
        noteDigit: Color.secondary,
        numberPadButton: Color(uiColor: .secondarySystemBackground),
        numberPadButtonDisabled: Color(uiColor: .tertiarySystemBackground),
        accent: Color.blue
    )

    static let midnight = Theme(
        id: "midnight",
        displayName: "Midnight",
        backgroundImageName: nil,
        backgroundGradient: [
            Color(red: 0.05, green: 0.07, blue: 0.15),
            Color(red: 0.10, green: 0.12, blue: 0.22),
        ],
        backgroundTint: .clear,
        backgroundTintOpacity: 0,
        surface: Color(red: 0.13, green: 0.16, blue: 0.26),
        cellBackground: Color(red: 0.17, green: 0.20, blue: 0.30).opacity(0.95),
        cellSelected: Color(red: 0.50, green: 0.60, blue: 1.0).opacity(0.45),
        cellPeerHighlight: Color(red: 0.50, green: 0.60, blue: 1.0).opacity(0.12),
        cellSameValue: Color(red: 0.50, green: 0.60, blue: 1.0).opacity(0.22),
        gridThin: Color.white.opacity(0.20),
        gridThick: Color.white.opacity(0.85),
        givenDigit: Color.white,
        userDigit: Color(red: 0.65, green: 0.80, blue: 1.0),
        conflictDigit: Color(red: 1.0, green: 0.45, blue: 0.45),
        noteDigit: Color.white.opacity(0.55),
        numberPadButton: Color(red: 0.18, green: 0.21, blue: 0.32),
        numberPadButtonDisabled: Color(red: 0.13, green: 0.16, blue: 0.24),
        accent: Color(red: 0.55, green: 0.72, blue: 1.0)
    )

    // Photo / nature themes ----------------------------------------------
    //
    // These reference an image asset (`backgroundImageName`). If that asset
    // is missing, the gradient remains as the visible background — so each
    // theme is usable immediately, photos are optional polish.

    static let sakura = Theme(
        id: "sakura",
        displayName: "Sakura",
        backgroundImageName: "theme-sakura",
        backgroundGradient: [
            Color(red: 1.00, green: 0.92, blue: 0.94),
            Color(red: 0.99, green: 0.82, blue: 0.86),
        ],
        backgroundTint: Color(red: 1.0, green: 0.95, blue: 0.97),
        backgroundTintOpacity: 0.75,
        surface: Color.white.opacity(0.95),
        cellBackground: Color.white.opacity(0.97),
        cellSelected: Color(red: 0.95, green: 0.55, blue: 0.70).opacity(0.45),
        cellPeerHighlight: Color(red: 0.95, green: 0.55, blue: 0.70).opacity(0.18),
        cellSameValue: Color(red: 0.95, green: 0.55, blue: 0.70).opacity(0.30),
        gridThin: Color(red: 0.60, green: 0.30, blue: 0.40).opacity(0.45),
        gridThick: Color(red: 0.30, green: 0.10, blue: 0.20),
        givenDigit: Color(red: 0.20, green: 0.05, blue: 0.15),
        userDigit: Color(red: 0.75, green: 0.20, blue: 0.45),
        conflictDigit: Color(red: 0.80, green: 0.10, blue: 0.20),
        noteDigit: Color(red: 0.45, green: 0.20, blue: 0.30),
        numberPadButton: Color.white.opacity(0.96),
        numberPadButtonDisabled: Color.white.opacity(0.65),
        accent: Color(red: 0.85, green: 0.30, blue: 0.50)
    )

    static let ocean = Theme(
        id: "ocean",
        displayName: "Ocean",
        backgroundImageName: "theme-ocean",
        backgroundGradient: [
            Color(red: 0.78, green: 0.93, blue: 0.97),
            Color(red: 0.40, green: 0.68, blue: 0.85),
        ],
        backgroundTint: Color(red: 0.85, green: 0.95, blue: 1.0),
        backgroundTintOpacity: 0.70,
        surface: Color.white.opacity(0.95),
        cellBackground: Color.white.opacity(0.97),
        cellSelected: Color(red: 0.10, green: 0.50, blue: 0.75).opacity(0.45),
        cellPeerHighlight: Color(red: 0.10, green: 0.50, blue: 0.75).opacity(0.15),
        cellSameValue: Color(red: 0.10, green: 0.50, blue: 0.75).opacity(0.30),
        gridThin: Color(red: 0.10, green: 0.30, blue: 0.50).opacity(0.40),
        gridThick: Color(red: 0.03, green: 0.15, blue: 0.35),
        givenDigit: Color(red: 0.03, green: 0.15, blue: 0.35),
        userDigit: Color(red: 0.05, green: 0.40, blue: 0.70),
        conflictDigit: Color(red: 0.85, green: 0.20, blue: 0.30),
        noteDigit: Color(red: 0.15, green: 0.30, blue: 0.50),
        numberPadButton: Color.white.opacity(0.96),
        numberPadButtonDisabled: Color.white.opacity(0.65),
        accent: Color(red: 0.10, green: 0.50, blue: 0.80)
    )

    static let forest = Theme(
        id: "forest",
        displayName: "Forest",
        backgroundImageName: "theme-forest",
        backgroundGradient: [
            Color(red: 0.85, green: 0.93, blue: 0.82),
            Color(red: 0.40, green: 0.60, blue: 0.40),
        ],
        backgroundTint: Color(red: 0.92, green: 0.97, blue: 0.88),
        backgroundTintOpacity: 0.70,
        surface: Color.white.opacity(0.95),
        cellBackground: Color.white.opacity(0.97),
        cellSelected: Color(red: 0.30, green: 0.55, blue: 0.30).opacity(0.45),
        cellPeerHighlight: Color(red: 0.30, green: 0.55, blue: 0.30).opacity(0.15),
        cellSameValue: Color(red: 0.30, green: 0.55, blue: 0.30).opacity(0.30),
        gridThin: Color(red: 0.20, green: 0.35, blue: 0.20).opacity(0.40),
        gridThick: Color(red: 0.08, green: 0.20, blue: 0.08),
        givenDigit: Color(red: 0.08, green: 0.20, blue: 0.08),
        userDigit: Color(red: 0.15, green: 0.45, blue: 0.20),
        conflictDigit: Color(red: 0.80, green: 0.25, blue: 0.20),
        noteDigit: Color(red: 0.20, green: 0.35, blue: 0.20),
        numberPadButton: Color.white.opacity(0.96),
        numberPadButtonDisabled: Color.white.opacity(0.65),
        accent: Color(red: 0.25, green: 0.55, blue: 0.30)
    )

    static let zenGarden = Theme(
        id: "zen",
        displayName: "Zen Garden",
        backgroundImageName: "theme-zen",
        backgroundGradient: [
            Color(red: 0.96, green: 0.93, blue: 0.86),
            Color(red: 0.82, green: 0.75, blue: 0.62),
        ],
        backgroundTint: Color(red: 0.96, green: 0.92, blue: 0.84),
        backgroundTintOpacity: 0.70,
        surface: Color.white.opacity(0.95),
        cellBackground: Color.white.opacity(0.97),
        cellSelected: Color(red: 0.55, green: 0.45, blue: 0.30).opacity(0.40),
        cellPeerHighlight: Color(red: 0.55, green: 0.45, blue: 0.30).opacity(0.15),
        cellSameValue: Color(red: 0.55, green: 0.45, blue: 0.30).opacity(0.28),
        gridThin: Color(red: 0.30, green: 0.25, blue: 0.15).opacity(0.40),
        gridThick: Color(red: 0.20, green: 0.15, blue: 0.08),
        givenDigit: Color(red: 0.20, green: 0.15, blue: 0.08),
        userDigit: Color(red: 0.50, green: 0.35, blue: 0.15),
        conflictDigit: Color(red: 0.75, green: 0.25, blue: 0.20),
        noteDigit: Color(red: 0.35, green: 0.25, blue: 0.15),
        numberPadButton: Color.white.opacity(0.96),
        numberPadButtonDisabled: Color.white.opacity(0.65),
        accent: Color(red: 0.55, green: 0.40, blue: 0.20)
    )
}

// MARK: - ThemeManager

@Observable
final class ThemeManager {
    /// Currently active theme. Setting it auto-persists.
    var current: Theme {
        didSet { persist() }
    }

    private static let key = "sudoku.theme.v1"

    init() {
        let savedId = UserDefaults.standard.string(forKey: Self.key) ?? Theme.classic.id
        self.current = Theme.allPresets.first(where: { $0.id == savedId }) ?? .classic
    }

    func select(_ theme: Theme) {
        current = theme
    }

    private func persist() {
        UserDefaults.standard.set(current.id, forKey: Self.key)
    }
}
