//
//  CellView.swift
//  Sudoku
//
//  Renders a single Sudoku cell:
//   - Background color depending on selection/peer/conflict state.
//   - Either a single large digit, or a 3x3 grid of pencil marks.
//   - Foreground color: given vs user-entered vs conflict.
//
//  Colors come from the active `Theme` via the environment so swapping
//  themes redraws every cell with no extra wiring.
//

import SwiftUI

struct CellView: View {
    let cell: Cell
    let isSelected: Bool
    let isPeerHighlighted: Bool
    let isSameValueAsSelected: Bool
    let isConflicting: Bool
    let isHintRevealed: Bool
    let isHintGlowing: Bool
    let size: CGFloat

    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        let theme = themeManager.current

        ZStack {
            background(theme: theme)

            if let value = cell.value {
                Text("\(value)")
                    .font(.system(size: size * 0.55, weight: cell.isGiven ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(digitColor(theme: theme))
            } else if !cell.notes.isEmpty {
                notesGrid(theme: theme)
            }

            // Subtle persistent marker on cells revealed via Hint: a tiny dot
            // in the top-left corner using the accent color.
            if isHintRevealed {
                VStack {
                    HStack {
                        Circle()
                            .fill(theme.accent)
                            .frame(width: size * 0.10, height: size * 0.10)
                            .padding(size * 0.08)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        // Hint glow: a brief pulsing ring drawn on top when this cell was
        // just revealed by the Hint button. Driven by `isHintGlowing`,
        // which the GameView toggles off after ~1.2s.
        .overlay(
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(theme.accent, lineWidth: isHintGlowing ? 3 : 0)
                .shadow(color: isHintGlowing ? theme.accent.opacity(0.9) : .clear, radius: isHintGlowing ? 8 : 0)
                .animation(.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true), value: isHintGlowing)
        )
        .scaleEffect(isHintGlowing ? 1.05 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isHintGlowing)
    }

    // MARK: - Background

    @ViewBuilder
    private func background(theme: Theme) -> some View {
        if isSelected {
            theme.cellSelected
        } else if isSameValueAsSelected {
            theme.cellSameValue
        } else if isPeerHighlighted {
            theme.cellPeerHighlight
        } else {
            theme.cellBackground
        }
    }

    // MARK: - Digit color

    private func digitColor(theme: Theme) -> Color {
        if isConflicting { return theme.conflictDigit }
        return cell.isGiven ? theme.givenDigit : theme.userDigit
    }

    // MARK: - Pencil-mark grid

    private func notesGrid(theme: Theme) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { col in
                        let digit = row * 3 + col + 1
                        Text(cell.notes.contains(digit) ? "\(digit)" : " ")
                            .font(.system(size: size * 0.22, weight: .regular, design: .rounded))
                            .foregroundStyle(theme.noteDigit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .padding(size * 0.05)
    }
}
