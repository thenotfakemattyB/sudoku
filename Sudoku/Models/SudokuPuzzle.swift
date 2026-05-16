//
//  SudokuPuzzle.swift
//  Sudoku
//
//  The core data model: a 9x9 Sudoku grid made up of `Cell` values plus
//  the puzzle's known solution. All conflict-detection logic lives here
//  so views and view models can stay focused on presentation/orchestration.
//

import Foundation

/// One square on the Sudoku board.
struct Cell: Equatable, Codable {
    /// The committed value (1...9) or `nil` if empty.
    var value: Int?
    /// Pencil-mark candidates (1...9). Cleared when `value` is set.
    var notes: Set<Int>
    /// `true` for clues placed by the generator. Givens cannot be edited.
    var isGiven: Bool

    init(value: Int? = nil, notes: Set<Int> = [], isGiven: Bool = false) {
        self.value = value
        self.notes = notes
        self.isGiven = isGiven
    }

    /// Empty if there's neither a value nor any pencil marks.
    var isEmpty: Bool { value == nil && notes.isEmpty }
}

/// A coordinate on the board. Row and column are 0...8.
struct CellIndex: Hashable, Codable {
    let row: Int
    let col: Int

    /// The 3x3 box index (0...8) this cell falls into.
    var box: Int { (row / 3) * 3 + (col / 3) }
}

/// A full Sudoku puzzle: the working grid plus the unique solution it was generated from.
struct SudokuPuzzle: Codable {
    /// 9x9 grid of cells. Indexed `cells[row][col]`.
    var cells: [[Cell]]
    /// The full solved board. Used for hint and win-detection logic.
    var solution: [[Int]]

    init(cells: [[Cell]], solution: [[Int]]) {
        precondition(cells.count == 9 && cells.allSatisfy { $0.count == 9 })
        precondition(solution.count == 9 && solution.allSatisfy { $0.count == 9 })
        self.cells = cells
        self.solution = solution
    }

    // MARK: - Accessors

    subscript(_ index: CellIndex) -> Cell {
        get { cells[index.row][index.col] }
        set { cells[index.row][index.col] = newValue }
    }

    /// Every cell index on the board, in row-major order.
    static let allIndices: [CellIndex] = (0..<9).flatMap { r in
        (0..<9).map { c in CellIndex(row: r, col: c) }
    }

    // MARK: - Conflict detection

    /// Returns the set of cells that conflict with the given index — i.e. share a row,
    /// column, or 3x3 box with it AND hold the same value. Used for the "highlight
    /// errors" toggle. Returns an empty set if the target cell has no value.
    func conflicts(at index: CellIndex) -> Set<CellIndex> {
        guard let value = self[index].value else { return [] }
        var result: Set<CellIndex> = []
        for peer in peers(of: index) where cells[peer.row][peer.col].value == value {
            result.insert(peer)
        }
        return result
    }

    /// Every conflicting cell on the entire board. A cell is conflicting if it shares
    /// row/col/box with another filled cell of the same value.
    func allConflicts() -> Set<CellIndex> {
        var result: Set<CellIndex> = []
        for index in Self.allIndices where cells[index.row][index.col].value != nil {
            let local = conflicts(at: index)
            if !local.isEmpty {
                result.insert(index)
                result.formUnion(local)
            }
        }
        return result
    }

    /// All 20 peer cells of a given index (same row, column, or 3x3 box, excluding self).
    func peers(of index: CellIndex) -> [CellIndex] {
        var peers: [CellIndex] = []
        peers.reserveCapacity(20)
        // Row + column
        for i in 0..<9 {
            if i != index.col { peers.append(CellIndex(row: index.row, col: i)) }
            if i != index.row { peers.append(CellIndex(row: i, col: index.col)) }
        }
        // Box (skip already-added row/col members)
        let boxRow = (index.row / 3) * 3
        let boxCol = (index.col / 3) * 3
        for r in boxRow..<(boxRow + 3) {
            for c in boxCol..<(boxCol + 3) {
                if r != index.row && c != index.col {
                    peers.append(CellIndex(row: r, col: c))
                }
            }
        }
        return peers
    }

    // MARK: - State queries

    /// `true` once every cell holds a value AND no conflicts exist.
    /// Equivalent to "matches the solution", but cheaper to read.
    var isSolved: Bool {
        for r in 0..<9 {
            for c in 0..<9 {
                if cells[r][c].value != solution[r][c] { return false }
            }
        }
        return true
    }

    /// Count of each digit (1...9) currently placed on the board. Used by the
    /// number pad to dim digits that have all 9 instances filled.
    func valueCounts() -> [Int: Int] {
        var counts: [Int: Int] = [:]
        for row in cells {
            for cell in row {
                if let v = cell.value { counts[v, default: 0] += 1 }
            }
        }
        return counts
    }
}
