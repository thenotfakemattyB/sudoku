//
//  NumberPadView.swift
//  Sudoku
//
//  Row of 1-9 buttons under the board, plus action buttons (Erase, Notes,
//  Undo, Redo, Hint). Each digit button shows a small remaining-count badge
//  (9 − placed) and disables itself when all 9 instances are on the board.
//

import SwiftUI

struct NumberPadView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(1...9, id: \.self) { digit in
                    digitButton(digit)
                }
            }
            HStack(spacing: 12) {
                eraseButton
                noteToggleButton
                undoButton
                redoButton
                hintButton
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Digit button

    private func digitButton(_ digit: Int) -> some View {
        let theme = themeManager.current
        let placed = viewModel.count(of: digit)
        let remaining = max(0, 9 - placed)
        let isDisabled = remaining == 0

        return Button {
            viewModel.enterNumber(digit)
            HapticsManager.tap()
        } label: {
            VStack(spacing: 2) {
                Text("\(digit)")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(isDisabled ? Color.secondary : theme.givenDigit)
                Text("\(remaining)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isDisabled ? theme.numberPadButtonDisabled : theme.numberPadButton)
            )
        }
        .disabled(isDisabled)
    }

    // MARK: - Action buttons

    private var eraseButton: some View {
        actionButton(systemName: "delete.left", label: "Erase") {
            viewModel.clearSelected()
            HapticsManager.tap()
        }
    }

    private var noteToggleButton: some View {
        let theme = themeManager.current
        let isActive = viewModel.state.inputMode == .notes
        return Button {
            viewModel.toggleInputMode()
            HapticsManager.selection()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "pencil.tip")
                    .font(.system(size: 18, weight: .medium))
                Text("Notes")
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isActive ? theme.accent.opacity(0.25) : theme.numberPadButton)
            )
            .foregroundStyle(isActive ? theme.accent : theme.givenDigit)
        }
    }

    private var undoButton: some View {
        actionButton(systemName: "arrow.uturn.backward", label: "Undo") {
            viewModel.undo()
            HapticsManager.tap()
        }
        .disabled(!viewModel.canUndo)
        .opacity(viewModel.canUndo ? 1.0 : 0.4)
    }

    private var redoButton: some View {
        actionButton(systemName: "arrow.uturn.forward", label: "Redo") {
            viewModel.redo()
            HapticsManager.tap()
        }
        .disabled(!viewModel.canRedo)
        .opacity(viewModel.canRedo ? 1.0 : 0.4)
    }

    private var hintButton: some View {
        let theme = themeManager.current
        let remaining = viewModel.state.hintsRemaining
        return Button {
            viewModel.useHint()
            HapticsManager.tap()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 18, weight: .medium))
                Text("Hint (\(remaining))")
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.numberPadButton)
            )
            .foregroundStyle(remaining > 0 ? theme.givenDigit : Color.secondary)
        }
        .disabled(remaining == 0)
    }

    private func actionButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        let theme = themeManager.current
        return Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .medium))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.numberPadButton)
            )
            .foregroundStyle(theme.givenDigit)
        }
    }
}
