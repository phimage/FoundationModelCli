//
//  Logger.swift
//  FM CLI
//
//  Global logger configuration
//

import Foundation
import Logging

/// Global logger instance for the FM CLI application
nonisolated(unsafe) var logger = Logger(label: "fm.cli")
