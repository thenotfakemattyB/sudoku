//
//  SettingsSheetView.swift
//  Sudoku
//
//  The settings sheet presented from GameView's toolbar gear button. Holds
//  the gameplay toggles (error highlighting, peer highlighting, etc.) plus
//  the theme picker — so you can swap themes mid-game.
//

import SwiftUI

struct SettingsSheetView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var confirmingRestart = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    ThemePickerView()
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }

                Section("Assists") {
                    Toggle("Highlight conflicts", isOn: bind(\.highlightErrors))
                    Toggle("Highlight row / column / box", isOn: bind(\.highlightPeers))
                    Toggle("Auto-remove notes", isOn: bind(\.autoRemoveNotes))
                }

                Section("Feedback") {
                    Toggle("Haptics", isOn: Binding(
                        get: { viewModel.settings.hapticsEnabled },
                        set: { newValue in
                            viewModel.settings.hapticsEnabled = newValue
                            HapticsManager.isEnabled = newValue
                        }
                    ))
                }

                Section("This game") {
                    Button(role: .destructive) {
                        confirmingRestart = true
                    } label: {
                        Label("Restart this puzzle", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Restart this puzzle?",
                isPresented: $confirmingRestart,
                titleVisibility: .visible
            ) {
                Button("Restart", role: .destructive) {
                    viewModel.restartCurrentPuzzle()
                    HapticsManager.tap()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This clears your entries, notes, hints used, and timer. The same puzzle stays.")
            }
        }
    }

    /// Helper that converts a GameSettings keypath into a SwiftUI Binding.
    /// Keeps the toggle declarations above tidy.
    private func bind(_ keyPath: WritableKeyPath<GameSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { viewModel.settings[keyPath: keyPath] },
            set: { viewModel.settings[keyPath: keyPath] = $0 }
        )
    }
}
