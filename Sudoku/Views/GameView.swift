//
//  GameView.swift
//  Sudoku
//
//  The main gameplay screen. Composes:
//   - The current theme's background (image or gradient).
//   - A top status row: difficulty label + elapsed time + paused indicator.
//   - The `BoardView`.
//   - The `NumberPadView` (digits + actions).
//   - Toolbar buttons: back-to-menu, settings sheet.
//   - Win overlay shown when `viewModel.winTime` is non-nil.
//

import SwiftUI

struct GameView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingSettings = false
    @State private var confirmingExit = false

    var body: some View {
        let theme = themeManager.current

        ZStack {
            theme.backgroundView()

            VStack(spacing: 16) {
                statusRow(theme: theme)

                BoardView(viewModel: viewModel)
                    .padding(.horizontal, 8)

                NumberPadView(viewModel: viewModel)
                    .padding(.horizontal, 8)

                Spacer(minLength: 0)
            }
            .padding(.top, 8)

            if let winTime = viewModel.winTime {
                winOverlay(time: winTime, theme: theme)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if viewModel.state.completed {
                        dismiss()
                    } else {
                        confirmingExit = true
                    }
                } label: {
                    Label("Menu", systemImage: "chevron.left")
                }
                .foregroundStyle(theme.accent)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .foregroundStyle(theme.accent)
            }
        }
        .navigationBarBackButtonHidden(true)
        .confirmationDialog(
            "Leave game?",
            isPresented: $confirmingExit,
            titleVisibility: .visible
        ) {
            Button("Save & exit") {
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your progress is saved and you can resume from the menu.")
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheetView(viewModel: viewModel)
        }
        .onChange(of: viewModel.lastHintIndex) { _, newValue in
            // After the hint glow animation finishes (~1.2s), clear it so the
            // glow doesn't persist if the user navigates away and back.
            guard newValue != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                viewModel.clearHintHighlight()
            }
        }
    }

    // MARK: - Status row

    private func statusRow(theme: Theme) -> some View {
        HStack {
            Label(viewModel.state.difficulty.displayName, systemImage: "square.grid.3x3")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(theme.givenDigit)

            Spacer()

            Text(viewModel.state.elapsedSeconds.asElapsedTimeString)
                .font(.system(.title3, design: .monospaced))
                .foregroundStyle(theme.givenDigit)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.surface)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Win overlay

    private func winOverlay(time: Int, theme: Theme) -> some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(theme.accent)

                Text("Solved!")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.givenDigit)

                Text(time.asElapsedTimeString)
                    .font(.system(.title2, design: .monospaced))
                    .foregroundStyle(theme.givenDigit)
                    .monospacedDigit()

                Text(viewModel.state.difficulty.displayName)
                    .font(.subheadline)
                    .foregroundStyle(theme.noteDigit)

                HStack(spacing: 12) {
                    Button {
                        viewModel.newGame(difficulty: viewModel.state.difficulty)
                    } label: {
                        Text("Play Again")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accent)

                    Button {
                        dismiss()
                    } label: {
                        Text("Menu")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(theme.accent)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(theme.surface)
            )
            .padding(.horizontal, 40)
            .onAppear { HapticsManager.success() }
        }
    }
}
