//
//  GameState.swift
//  Sudoku
//
//  Holds the mutable state for a single in-progress game: the puzzle,
//  the move history (for undo/redo), the elapsed timer, the selected
//  cell, the active input mode, and the hint budget. Also handles
//  persistence to UserDefaults via Codable.
//
//  Move history note: we record one `Move` per user action, with both
//  the "before" and "after" cell snapshot. Undo restores `before`,
//  redo restores `after`. This is simpler and more robust than trying
//  to invert each move type — particularly for pencil-mark edits.
//

import Foundation

/// A single player action, fully describing the cell before and after.
struct Move: Codable, Equatable {
    let index: CellIndex
    let before: Cell
    let after: Cell
}

/// Whether tapping a number commits a value or toggles a pencil mark.
enum InputMode: String, Codable {
    case value
    case notes
}

/// All state for one game session. Codable so we can persist game-in-progress.
struct GameState: Codable {
    var puzzle: SudokuPuzzle
    var difficulty: Difficulty
    var elapsedSeconds: Int = 0
    var selected: CellIndex? = nil
    var inputMode: InputMode = .value
    var undoStack: [Move] = []
    var redoStack: [Move] = []
    var hintsUsed: Int = 0
    var completed: Bool = false
    /// Cells revealed via the Hint button. Used for a subtle visual marker.
    var hintCells: Set<CellIndex> = []

    /// Max hints per game (matches spec).
    static let hintLimit = 3
    var hintsRemaining: Int { Self.hintLimit - hintsUsed }

    init(puzzle: SudokuPuzzle, difficulty: Difficulty) {
        self.puzzle = puzzle
        self.difficulty = difficulty
    }
}

/// Lightweight stats record: best times per difficulty + games played.
/// Stored alongside the in-progress game in UserDefaults.
struct PlayerStats: Codable {
    var bestTimes: [Difficulty: Int] = [:]
    var gamesCompleted: [Difficulty: Int] = [:]

    mutating func record(difficulty: Difficulty, seconds: Int) {
        gamesCompleted[difficulty, default: 0] += 1
        if let prev = bestTimes[difficulty] {
            bestTimes[difficulty] = min(prev, seconds)
        } else {
            bestTimes[difficulty] = seconds
        }
    }
}

// MARK: - Persistence

/// Thin wrapper around UserDefaults for save/load. We use UserDefaults
/// instead of SwiftData because the data is small (one game + a stats
/// blob) and we want zero schema/migration ceremony.
enum GamePersistence {
    private static let gameKey = "sudoku.currentGame.v1"
    private static let statsKey = "sudoku.stats.v1"

    static func saveGame(_ state: GameState?) {
        let defaults = UserDefaults.standard
        guard let state else {
            defaults.removeObject(forKey: gameKey)
            return
        }
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: gameKey)
        }
    }

    static func loadGame() -> GameState? {
        guard
            let data = UserDefaults.standard.data(forKey: gameKey),
            let state = try? JSONDecoder().decode(GameState.self, from: data)
        else { return nil }
        return state
    }

    static func saveStats(_ stats: PlayerStats) {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: statsKey)
        }
    }

    static func loadStats() -> PlayerStats {
        guard
            let data = UserDefaults.standard.data(forKey: statsKey),
            let stats = try? JSONDecoder().decode(PlayerStats.self, from: data)
        else { return PlayerStats() }
        return stats
    }
}
