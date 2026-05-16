//
//  ContentView.swift
//  Sudoku
//
//  Root navigation view. Wraps `MenuView` in a NavigationStack so MenuView
//  can push into GameView. Lives separately from `SudokuApp` so the app
//  entry point stays minimal.
//

import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: GameViewModel

    var body: some View {
        NavigationStack {
            MenuView(viewModel: viewModel)
        }
    }
}
