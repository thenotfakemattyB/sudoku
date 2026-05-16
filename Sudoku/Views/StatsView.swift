//
//  StatsView.swift
//  Sudoku
//
//  Presented as a sheet from the menu. Shows best time and games completed
//  per difficulty. Kept deliberately spare — this is a personal app, not a
//  leaderboard.
//

import SwiftUI

struct StatsView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var confirmingReset = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(Difficulty.allCases) { diff in
                    Section(diff.displayName) {
                        statRow(
                            label: "Best time",
                            value: viewModel.stats.bestTimes[diff]?.asElapsedTimeString ?? "—"
                        )
                        statRow(
                            label: "Games completed",
                            value: "\(viewModel.stats.gamesCompleted[diff, default: 0])"
                        )
                    }
                }

                Section {
                    Button(role: .destructive) {
                        confirmingReset = true
                    } label: {
                        Label("Reset all stats", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Reset all stats?",
                isPresented: $confirmingReset,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    viewModel.resetStats()
                    HapticsManager.tap()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently erases your best times and games-completed counts. Can't be undone.")
            }
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
