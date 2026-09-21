//
//  CommandFigitus.swift
//  Higitus
//
//  Created by syan on 17/09/2026.
//

import Foundation
import ArgumentParser

struct CommandFigitus: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "figitus",
        abstract: "Organizes the given folder"
    )
    
    @OptionGroup var options: Options
    
    mutating func validate() throws {
        try options.validate()
    }
    
    mutating func run() throws {
        Log.level = options.logLevel

        let lock = Lock(url: Config.lockFileURL)
        guard lock.acquire() else {
            print("Already running, marked need for a new run once the current one is done")
            Config.runAgainFlagURL.touch()
            return
        }
        defer { lock.release() }

        try? FileManager.default.removeItem(atPath: Config.runAgainFlagURL.asPath)

        try runOnce(
            downloadsURL: options.path,
            moviesURL: options.moviesPath,
            showsURL: options.showsPath
        )

        if Config.runAgainFlagURL.exists {
            print("Needs another run, starting now!")
            try run()
        }
    }
    
    private func runOnce(downloadsURL: FileURL, moviesURL: FileURL, showsURL: FileURL) throws(AppError) {
        print("Organizing: \(downloadsURL.asPath)")
        
        let medias = try FileManager.default.mediaFiles(under: downloadsURL)
        for m in medias {
            let relM = m.mediaURL.asPath(relativeTo: downloadsURL)
            do {
                print("---------------")
                Log.i(relM, "TODO: Download subtitles")

                let hunch = try Hunch.analyze(m.mediaURL, inside: downloadsURL)
                let newMediaURL = try m.mediaURL.suggestURL(using: hunch, moviesRoot: moviesURL, seriesRoot: showsURL)
                Log.i(relM, "Found subtitles: \(try m.findSubtitles().keys.joined(separator: ", "))")
                Log.i(relM, "TODO: Move to \(newMediaURL.asPath)")
                Log.i(relM, "TODO: Move subtitles too")
            }
            catch {
                Log.e(relM, "Error: \(error.localizedDescription)")
            }
        }
        
        try FileManager.default.cleanup(at: downloadsURL, isDeletable: false)
    }
}
