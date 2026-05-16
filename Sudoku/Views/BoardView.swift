//
//  BoardView.swift
//  Sudoku
//
//  The 9x9 grid. Lays out 81 `CellView`s and draws the grid lines on top,
//  using thicker strokes for the 3x3 box borders. The board sizes itself
//  to the smaller of its width/height so it scales cleanly on every iPhone.
//
//  Grid-line approach: instead of trying to make each cell draw its own
//  borders (which gets fiddly with shared edges and thickness mismatches),
//  we overlay a single `Path` that strokes thin lines first, then thick
//  lines on top. This guarantees crisp, consistent intersections.
//

import SwiftUI

struct BoardView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        let theme = themeManager.current

        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cellSize = side / 9.0
            let conflicts = viewModel.conflictSet
            let peers = viewModel.peersOfSelected
            let sameValue = viewModel.sameValueAsSelected
            let hintCells = viewModel.state.hintCells
            let glowingIndex = viewModel.lastHintIndex

            ZStack {
                cellGrid(
                    cellSize: cellSize,
                    conflicts: conflicts,
                    peers: peers,
                    sameValue: sameValue,
                    hintCells: hintCells,
                    glowingIndex: glowingIndex
                )
                gridLines(side: side, theme: theme)
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Cells

    private func cellGrid(
        cellSize: CGFloat,
        conflicts: Set<CellIndex>,
        peers: Set<CellIndex>,
        sameValue: Set<CellIndex>,
        hintCells: Set<CellIndex>,
        glowingIndex: CellIndex?
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<9, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { col in
                        let index = CellIndex(row: row, col: col)
                        CellView(
                            cell: viewModel.state.puzzle[index],
                            isSelected: viewModel.state.selected == index,
                            isPeerHighlighted: peers.contains(index),
                            isSameValueAsSelected: sameValue.contains(index),
                            isConflicting: conflicts.contains(index),
                            isHintRevealed: hintCells.contains(index),
                            isHintGlowing: glowingIndex == index,
                            size: cellSize
                        )
                        .onTapGesture {
                            viewModel.selectCell(index)
                            HapticsManager.selection()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Grid lines

    private func gridLines(side: CGFloat, theme: Theme) -> some View {
        ZStack {
            Path { path in
                let step = side / 9.0
                for i in 1..<9 {
                    let pos = step * CGFloat(i)
                    path.move(to: CGPoint(x: pos, y: 0))
                    path.addLine(to: CGPoint(x: pos, y: side))
                    path.move(to: CGPoint(x: 0, y: pos))
                    path.addLine(to: CGPoint(x: side, y: pos))
                }
            }
            .stroke(theme.gridThin, lineWidth: 0.5)

            Path { path in
                let step = side / 9.0
                for i in 0...9 where i % 3 == 0 {
                    let pos = step * CGFloat(i)
                    path.move(to: CGPoint(x: pos, y: 0))
                    path.addLine(to: CGPoint(x: pos, y: side))
                    path.move(to: CGPoint(x: 0, y: pos))
                    path.addLine(to: CGPoint(x: side, y: pos))
                }
            }
            .stroke(theme.gridThick, lineWidth: 2.0)
        }
        .allowsHitTesting(false)
    }
}
