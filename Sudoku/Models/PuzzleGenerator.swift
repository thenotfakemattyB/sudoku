//
//  PuzzleGenerator.swift
//  Sudoku
//
//  Generates Sudoku puzzles with a guaranteed unique solution.
//
//  Algorithm overview:
//    1. Fill an empty 9x9 grid via randomized backtracking → a complete board.
//    2. Walk cells in a randomized order, "removing" each (setting to 0).
//       After each removal, run a solver that COUNTS solutions (short-circuits
//       at 2). If removing the cell would make the puzzle ambiguous, put it
//       back. Otherwise leave it blank.
//    3. Stop once the target number of givens is reached (or every cell has
//       been considered — whichever comes first).
//
//  Uniqueness is what makes a Sudoku puzzle a "real" Sudoku, so we never relax
//  it. The trade-off is generation time: Hard puzzles do more uniqueness checks
//  and take longer, but on a modern iPhone this is still well under a second.
//

import Foundation

enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy, medium, hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        }
    }

    /// Target number of clues left on the board. Lower = harder.
    /// Picked from the requested ranges (38-45 / 30-37 / 22-29).
    var givenCount: Int {
        switch self {
        case .easy:   return Int.random(in: 38...45)
        case .medium: return Int.random(in: 30...37)
        case .hard:   return Int.random(in: 22...29)
        }
    }
}

enum PuzzleGenerator {

    /// Generate a fresh puzzle at the requested difficulty.
    static func generate(difficulty: Difficulty) -> SudokuPuzzle {
        // 1. Build a complete, valid board.
        var board = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = fill(&board)
        let solution = board

        // 2. Remove cells while preserving uniqueness.
        let target = difficulty.givenCount
        var indices = SudokuPuzzle.allIndices.shuffled()
        var removed = 0
        let toRemove = 81 - target

        while removed < toRemove, let next = indices.popLast() {
            let backup = board[next.row][next.col]
            board[next.row][next.col] = 0

            var count = 0
            var workingCopy = board
            countSolutions(&workingCopy, found: &count, limit: 2)
            if count != 1 {
                // Multiple solutions — restore.
                board[next.row][next.col] = backup
            } else {
                removed += 1
            }
        }

        // 3. Wrap into a SudokuPuzzle, marking remaining cells as givens.
        var cells = Array(
            repeating: Array(repeating: Cell(), count: 9),
            count: 9
        )
        for r in 0..<9 {
            for c in 0..<9 {
                let v = board[r][c]
                cells[r][c] = Cell(
                    value: v == 0 ? nil : v,
                    notes: [],
                    isGiven: v != 0
                )
            }
        }
        return SudokuPuzzle(cells: cells, solution: solution)
    }

    // MARK: - Backtracking fill (random)

    /// Fill `board` in place with a complete valid Sudoku solution.
    /// Randomized so each call yields a different board. Returns true on success.
    @discardableResult
    private static func fill(_ board: inout [[Int]]) -> Bool {
        guard let empty = firstEmpty(in: board) else { return true }
        let (r, c) = empty
        for value in (1...9).shuffled() {
            if isValid(board, row: r, col: c, value: value) {
                board[r][c] = value
                if fill(&board) { return true }
                board[r][c] = 0
            }
        }
        return false
    }

    // MARK: - Solution counting (uniqueness check)

    /// Counts how many distinct solutions `board` admits. Stops as soon as
    /// `found` reaches `limit` — for uniqueness checks we only ever need to
    /// know whether the count is 0, 1, or "≥2", so `limit = 2` is plenty.
    private static func countSolutions(_ board: inout [[Int]], found: inout Int, limit: Int) {
        if found >= limit { return }
        guard let empty = firstEmpty(in: board) else {
            found += 1
            return
        }
        let (r, c) = empty
        for value in 1...9 {
            if isValid(board, row: r, col: c, value: value) {
                board[r][c] = value
                countSolutions(&board, found: &found, limit: limit)
                board[r][c] = 0
                if found >= limit { return }
            }
        }
    }

    // MARK: - Helpers

    /// First empty (== 0) cell in row-major order, or nil if the board is full.
    private static func firstEmpty(in board: [[Int]]) -> (Int, Int)? {
        for r in 0..<9 {
            for c in 0..<9 where board[r][c] == 0 {
                return (r, c)
            }
        }
        return nil
    }

    /// Standard Sudoku validity check: is `value` allowed at (row, col)?
    private static func isValid(_ board: [[Int]], row: Int, col: Int, value: Int) -> Bool {
        for i in 0..<9 {
            if board[row][i] == value { return false }
            if board[i][col] == value { return false }
        }
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        for r in boxRow..<(boxRow + 3) {
            for c in boxCol..<(boxCol + 3) {
                if board[r][c] == value { return false }
            }
        }
        return true
    }
}
