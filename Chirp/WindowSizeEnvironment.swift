//
//  WindowSizeEnvironment.swift
//  Chirp
//
//  Created for responsive window sizing support
//

import SwiftUI

enum WindowSizeClass {
    case full    // >= 1000px width
    case compact // < 1000px width

    static func from(width: CGFloat) -> WindowSizeClass {
        width >= 1000 ? .full : .compact
    }
}

struct WindowSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = CGSize(width: 1000, height: 700)
}

struct WindowSizeClassKey: EnvironmentKey {
    static let defaultValue: WindowSizeClass = .full
}

extension EnvironmentValues {
    var windowSize: CGSize {
        get { self[WindowSizeKey.self] }
        set { self[WindowSizeKey.self] = newValue }
    }

    var windowSizeClass: WindowSizeClass {
        get { self[WindowSizeClassKey.self] }
        set { self[WindowSizeClassKey.self] = newValue }
    }
}
