//
//  HapticsManager.swift
//  Sudoku
//
//  Thin wrapper around UIKit's feedback generators. All calls go through here
//  so we can globally enable/disable haptics from the settings panel.
//
//  Generators are created on each call (rather than stored) because the
//  occasional taps in a Sudoku game aren't latency-sensitive enough to need
//  the warm-up `prepare()` dance for stored instances.
//

import UIKit

enum HapticsManager {

    /// Master switch. Toggled by GameSettings.hapticsEnabled — the VM forwards
    /// the value here so we don't need to thread settings into every call site.
    static var isEnabled: Bool = true

    static func tap() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func error() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
