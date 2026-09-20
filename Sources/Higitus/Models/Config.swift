//
//  Config.swift
//  Higitus
//
//  Created by syan on 17/09/2026.
//

import Foundation

struct Config {
    // MARK: Static config
    static let lockFileURL = FileURL(path: "/var/tmp/organize_lock")
    static let runAgainFlagURL = FileURL(path: "/var/tmp/organize_runagain")

    // MARK: ENV-based config
    static let openSubtitlesAPIKey = ProcessInfo.processInfo.environment["OPENSUBTITLES_API_KEY"]
    static let openSubtitlesUsername = ProcessInfo.processInfo.environment["OPENSUBTITLES_USERNAME"]
    static let openSubtitlesPassword = ProcessInfo.processInfo.environment["OPENSUBTITLES_PASSWORD"]
}
