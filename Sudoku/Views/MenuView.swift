//
//  MenuView.swift
//  Sudoku
//
//  The root menu screen. Lets the user:
//   - Resume an in-progress game (if one exists).
//   - Start a new game at Easy / Medium / Hard.
//   - Pick a theme.
//   - View stats (best times, games completed).
//

import SwiftUI

struct MenuView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(ThemeManager.self) private var themeManager

    @State private var showingGame = false
    @State private var showingStats = false

    /// True when there's an unfinished saved game we can resume.
    private var canResume: Bool {
        !viewModel.state.completed && viewModel.state.elapsedSeconds > 0
    }

    var body: some View {
        let theme = themeManager.current

        ZStack {
            theme.backgroundView()

            ScrollView {
                VStack(spacing: 24) {
                    header(theme: theme)

                    VStack(spacing: 12) {
                        if canResume {
                            resumeButton(theme: theme)
                        }
                        ForEach(Difficulty.allCases) { diff in
                            newGameButton(diff, theme: theme)
                        }
                    }
                    .padding(.horizontal, 20)

                    ThemePickerView()
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(theme.surface)
                        )
                        .padding(.horizontal, 16)

                    Button {
                        showingStats = true
                    } label: {
                        Label("Stats", systemImage: "chart.bar.xaxis")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(theme.surface)
                            )
                            .foregroundStyle(theme.givenDigit)
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
        }
        .navigationDestination(isPresented: $showingGame) {
            GameView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingStats) {
            StatsView(viewModel: viewModel)
        }
    }

    // MARK: - Header

    private func header(theme: Theme) -> some View {
        VStack(spacing: 6) {
            Text("Sudoku")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(theme.givenDigit)
            Text("A quiet, focused puzzle")
                .font(.subheadline)
                .foregroundStyle(theme.noteDigit)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.surface)
        )
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Buttons

    private func resumeButton(theme: Theme) -> some View {
        Button {
            showingGame = true
        } label: {
            HStack {
                Image(systemName: "play.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Resume")
                        .font(.system(.headline, design: .rounded))
                    Text("\(viewModel.state.difficulty.displayName) • \(viewModel.state.elapsedSeconds.asElapsedTimeString)")
                        .font(.caption)
                        .foregroundStyle(theme.noteDigit)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(theme.noteDigit)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.accent.opacity(0.18))
            )
            .foregroundStyle(theme.givenDigit)
        }
    }

    private func newGameButton(_ difficulty: Difficulty, theme: Theme) -> some View {
        Button {
            viewModel.newGame(difficulty: difficulty)
            showingGame = true
        } label: {
            HStack {
                Text(difficulty.displayName)
                    .font(.system(.headline, design: .rounded))
                Spacer()
                if let best = viewModel.stats.bestTimes[difficulty] {
                    Text("Best: \(best.asElapsedTimeString)")
                        .font(.caption)
                        .foregroundStyle(theme.noteDigit)
                }
                Image(systemName: "chevron.right")
                    .foregroundStyle(theme.noteDigit)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.surface)
            )
            .foregroundStyle(theme.givenDigit)
        }
    }
}
