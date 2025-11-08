//
//  LogManager.swift
//  Chirp
//
//  Centralized logging using OSLog for production-ready logging
//

import Foundation
import OSLog

/// Centralized logging system for Chirp using OSLog
enum LogManager {
    // Define subsystem
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.chirp.app"

    // Define loggers for different categories
    static let app = Logger(subsystem: subsystem, category: "App")
    static let menu = Logger(subsystem: subsystem, category: "MenuBar")
    static let timer = Logger(subsystem: subsystem, category: "Timer")
    static let data = Logger(subsystem: subsystem, category: "Data")
}

// MARK: - Log Level Extensions
extension Logger {
    /// Log an info message (visible in Console.app)
    func info(_ message: String) {
        self.info("\(message, privacy: .public)")
    }

    /// Log a debug message (only in debug builds)
    func debug(_ message: String) {
        self.debug("\(message, privacy: .public)")
    }

    /// Log a warning message
    func warning(_ message: String) {
        self.warning("\(message, privacy: .public)")
    }

    /// Log an error message with details
    func error(_ message: String, error: Error? = nil) {
        if let error = error {
            self.error("\(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            self.error("\(message, privacy: .public)")
        }
    }

    /// Log a fault (critical error)
    func fault(_ message: String) {
        self.fault("\(message, privacy: .public)")
    }
}
