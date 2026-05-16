//
//  SudokuApp.swift
//  Sudoku
//
//  @main entry point. Creates the long-lived GameViewModel + ThemeManager
//  and injects them into the SwiftUI environment so every view can read
//  them via @Environment(...).
//
//  Listens for scene phase changes to pause/persist the game when the app
//  is backgrounded, and resume it when it comes back to the foreground.
//

import SwiftUI

@main
struct SudokuApp: App {

    @State private var viewModel = GameViewModel()
    @State private var themeManager = ThemeManager()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .environment(themeManager)
                .onAppear {
                    // Mirror the saved haptics preference into the static manager.
                    HapticsManager.isEnabled = viewModel.settings.hapticsEnabled
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        viewModel.setActive(true)
                    case .inactive, .background:
                        viewModel.setActive(false)
                    @unknown default:
                        break
                    }
                }
        }
    }
}
