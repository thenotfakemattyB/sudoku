//
//  ThemePickerView.swift
//  Sudoku
//
//  Reusable theme picker. A horizontally-scrolling row of swatches, one per
//  preset theme. Each swatch shows a mini preview (gradient/image + a sample
//  9-segment indicator) and is selectable.
//
//  Used in two places (per spec): the main menu and the in-game settings sheet.
//

import SwiftUI

struct ThemePickerView: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Theme")
                .font(.headline)
                .foregroundStyle(themeManager.current.givenDigit)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Theme.allPresets) { theme in
                        swatch(for: theme)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
        }
    }

    private func swatch(for theme: Theme) -> some View {
        let isSelected = themeManager.current.id == theme.id

        return Button {
            themeManager.select(theme)
            HapticsManager.selection()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Theme background preview
                    LinearGradient(
                        colors: theme.backgroundGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    if let name = theme.backgroundImageName, UIImage(named: name) != nil {
                        Image(name)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .overlay(theme.backgroundTint.opacity(theme.backgroundTintOpacity))
                    }
                    // Tiny digit sample so you can see the digit color
                    HStack(spacing: 4) {
                        Text("5")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.givenDigit)
                        Text("7")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.userDigit)
                    }
                    .padding(6)
                    .background(theme.cellBackground.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isSelected ? theme.accent : Color.clear, lineWidth: 3)
                )

                Text(theme.displayName)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}
