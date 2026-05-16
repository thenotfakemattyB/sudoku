//
//  GameViewModel.swift
//  Sudoku
//
//  The single observable object views talk to. Owns a `GameState` and exposes
//  intent-style methods (selectCell, enterNumber, toggleNote, undo, redo, hint,
//  clear, …) plus derived UI state (conflict set, highlighted peers, win flag).
//
//  Uses the iOS 17 Observation framework (@Observable) so views can read
//  properties directly without ObservableObject/@Published boilerplate.
//

import Foundation
import SwiftUI
import Observation

/// Player-toggleable game settings. Stored on the VM so they survive
/// between games but reset cleanly with the app.
struct GameSettings {
    var highlightErrors: Bool = true
    var highlightPeers: Bool = true
    var autoRemoveNotes: Bool = true
    var hapticsEnabled: Bool = true
}

@Observable
final class GameViewModel {

    // MARK: - Observable state

    var state: GameState
    var settings = GameSettings()
    var stats: PlayerStats
    /// Set to a non-nil value when a win is detected; the view shows an overlay.
    var winTime: Int? = nil
    /// The most recently hint-revealed cell. Views observe this to animate a
    /// glow on that cell. Cleared after the animation by the view layer.
    var lastHintIndex: CellIndex? = nil

    // MARK: - Private

    private var timer: Timer?

    // MARK: - Init

    init() {
        // Try to resume an in-progress game on launch; otherwise start Easy.
        if let saved = GamePersistence.loadGame(), !saved.completed {
            self.state = saved
        } else {
            let puzzle = PuzzleGenerator.generate(difficulty: .easy)
            self.state = GameState(puzzle: puzzle, difficulty: .easy)
        }
        self.stats = GamePersistence.loadStats()
        startTimer()
    }

    // MARK: - Game lifecycle

    func newGame(difficulty: Difficulty) {
        stopTimer()
        let puzzle = PuzzleGenerator.generate(difficulty: difficulty)
        state = GameState(puzzle: puzzle, difficulty: difficulty)
        winTime = nil
        startTimer()
        persist()
    }

    /// Restart the *current* puzzle from scratch: keep the same givens and
    /// solution, but wipe player progress (entries, notes, hints, timer, undo).
    func restartCurrentPuzzle() {
        stopTimer()
        var fresh = state.puzzle
        for r in 0..<9 {
            for c in 0..<9 where !fresh.cells[r][c].isGiven {
                fresh.cells[r][c] = Cell()
            }
        }
        state = GameState(puzzle: fresh, difficulty: state.difficulty)
        winTime = nil
        lastHintIndex = nil
        startTimer()
        persist()
    }

    /// Wipe best times + games-completed across all difficulties.
    func resetStats() {
        stats = PlayerStats()
        GamePersistence.saveStats(stats)
    }

    /// Forget the in-progress game without starting a new one. Used by the
    /// menu's "abandon" path.
    func abandonCurrentGame() {
        stopTimer()
        GamePersistence.saveGame(nil)
        let puzzle = PuzzleGenerator.generate(difficulty: state.difficulty)
        state = GameState(puzzle: puzzle, difficulty: state.difficulty)
        winTime = nil
        lastHintIndex = nil
    }

    /// Pause when the app backgrounds; resume when it returns. Called from the App scene.
    func setActive(_ active: Bool) {
        if active {
            if !state.completed { startTimer() }
        } else {
            stopTimer()
            persist()
        }
    }

    // MARK: - Selection

    func selectCell(_ index: CellIndex) {
        state.selected = index
    }

    func toggleInputMode() {
        state.inputMode = (state.inputMode == .value) ? .notes : .value
    }

    // MARK: - Input

    /// Tapping a number on the pad. Honors the current input mode.
    func enterNumber(_ number: Int) {
        guard let index = state.selected else { return }
        let cell = state.puzzle[index]
        guard !cell.isGiven else { return }

        let before = cell
        var after = cell

        switch state.inputMode {
        case .value:
            // Toggle off if same value already there.
            after.value = (cell.value == number) ? nil : number
            after.notes.removeAll()
        case .notes:
            // Only allowed when the cell has no committed value.
            guard cell.value == nil else { return }
            if after.notes.contains(number) {
                after.notes.remove(number)
            } else {
                after.notes.insert(number)
            }
        }

        guard after != before else { return }
        applyMove(Move(index: index, before: before, after: after))

        // Auto-remove the just-placed value from notes in peer cells.
        if settings.autoRemoveNotes,
           state.inputMode == .value,
           after.value != nil {
            removeFromPeerNotes(value: number, around: index)
        }

        checkForWin()
        persist()
    }

    /// Clear the selected cell's value AND notes.
    func clearSelected() {
        guard let index = state.selected else { return }
        let cell = state.puzzle[index]
        guard !cell.isGiven, !cell.isEmpty else { return }
        var cleared = cell
        cleared.value = nil
        cleared.notes.removeAll()
        applyMove(Move(index: index, before: cell, after: cleared))
        persist()
    }

    // MARK: - Undo / Redo

    func undo() {
        guard let move = state.undoStack.popLast() else { return }
        state.puzzle[move.index] = move.before
        state.redoStack.append(move)
        persist()
    }

    func redo() {
        guard let move = state.redoStack.popLast() else { return }
        state.puzzle[move.index] = move.after
        state.undoStack.append(move)
        checkForWin()
        persist()
    }

    var canUndo: Bool { !state.undoStack.isEmpty }
    var canRedo: Bool { !state.redoStack.isEmpty }

    // MARK: - Hint

    /// Reveal the solution digit for the selected cell — or, if no cell is
    /// selected (or the selected one already has the right value or is a given),
    /// auto-pick the "easiest" empty cell on the board (the one with the
    /// fewest legal candidates) so the hint button never silently no-ops.
    /// Limited to 3 per game.
    func useHint() {
        guard state.hintsRemaining > 0 else { return }

        // Decide which cell to hint.
        let target: CellIndex? = resolveHintTarget()
        guard let index = target else { return }

        let cell = state.puzzle[index]
        let correct = state.puzzle.solution[index.row][index.col]

        var after = cell
        after.value = correct
        after.notes.removeAll()
        applyMove(Move(index: index, before: cell, after: after))
        state.hintsUsed += 1
        state.hintCells.insert(index)
        state.selected = index
        lastHintIndex = index

        if settings.autoRemoveNotes {
            removeFromPeerNotes(value: correct, around: index)
        }
        checkForWin()
        persist()
    }

    /// Pick which cell the next hint should target. Prefers (in order):
    /// 1. The currently selected cell if it's empty / wrong and not a given.
    /// 2. The empty cell with the fewest legal candidates (most constrained → easiest "logical" move).
    /// 3. Any empty cell, falling through if everything else is filled.
    private func resolveHintTarget() -> CellIndex? {
        if let sel = state.selected {
            let cell = state.puzzle[sel]
            let correct = state.puzzle.solution[sel.row][sel.col]
            if !cell.isGiven && cell.value != correct {
                return sel
            }
        }
        var best: (index: CellIndex, candidates: Int)?
        for idx in SudokuPuzzle.allIndices {
            let cell = state.puzzle.cells[idx.row][idx.col]
            guard cell.value == nil, !cell.isGiven else { continue }
            let cands = legalCandidateCount(at: idx)
            if best == nil || cands < best!.candidates {
                best = (idx, cands)
            }
        }
        return best?.index
    }

    /// How many digits (1...9) are legal at the given empty cell.
    private func legalCandidateCount(at index: CellIndex) -> Int {
        var taken = Set<Int>()
        for peer in state.puzzle.peers(of: index) {
            if let v = state.puzzle.cells[peer.row][peer.col].value { taken.insert(v) }
        }
        return 9 - taken.count
    }

    /// Called by the view after the hint glow animation finishes.
    func clearHintHighlight() {
        lastHintIndex = nil
    }

    // MARK: - Derived UI helpers

    /// Cells the UI should highlight as conflicting. Empty if the setting is off.
    var conflictSet: Set<CellIndex> {
        settings.highlightErrors ? state.puzzle.allConflicts() : []
    }

    /// Peers (row, col, box) of the selected cell — used for soft highlight.
    var peersOfSelected: Set<CellIndex> {
        guard let index = state.selected, settings.highlightPeers else { return [] }
        return Set(state.puzzle.peers(of: index))
    }

    /// All other cells holding the same value as the selected cell. The UI
    /// can use this to subtly highlight matching digits across the board.
    var sameValueAsSelected: Set<CellIndex> {
        guard let sel = state.selected, let v = state.puzzle[sel].value else { return [] }
        var out: Set<CellIndex> = []
        for idx in SudokuPuzzle.allIndices where idx != sel {
            if state.puzzle.cells[idx.row][idx.col].value == v { out.insert(idx) }
        }
        return out
    }

    func count(of digit: Int) -> Int {
        state.puzzle.valueCounts()[digit] ?? 0
    }

    // MARK: - Private helpers

    private func applyMove(_ move: Move) {
        state.puzzle[move.index] = move.after
        state.undoStack.append(move)
        state.redoStack.removeAll()
    }

    /// When a digit is placed, strip it from notes of peer cells (auto-cleanup).
    /// We record each peer change as its own undoable move so undo can fully reverse.
    private func removeFromPeerNotes(value: Int, around index: CellIndex) {
        for peer in state.puzzle.peers(of: index) {
            let cell = state.puzzle[peer]
            guard cell.notes.contains(value) else { continue }
            var updated = cell
            updated.notes.remove(value)
            applyMove(Move(index: peer, before: cell, after: updated))
        }
    }

    private func checkForWin() {
        guard !state.completed, state.puzzle.isSolved else { return }
        state.completed = true
        stopTimer()
        winTime = state.elapsedSeconds
        stats.record(difficulty: state.difficulty, seconds: state.elapsedSeconds)
        GamePersistence.saveStats(stats)
        // Clear the saved in-progress game — it's done.
        GamePersistence.saveGame(nil)
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        guard !state.completed else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        state.elapsedSeconds += 1
    }

    // MARK: - Persistence

    private func persist() {
        if state.completed {
            GamePersistence.saveGame(nil)
        } else {
            GamePersistence.saveGame(state)
        }
    }
}

// MARK: - Helpers

extension Int {
    /// Format an elapsed-seconds count as `MM:SS` (or `H:MM:SS` past an hour).
    var asElapsedTimeString: String {
        let h = self / 3600
        let m = (self % 3600) / 60
        let s = self % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}
