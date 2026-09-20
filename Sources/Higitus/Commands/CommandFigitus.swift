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
    
    @Option(help: "Movies folder")
    var moviesFolder: String
    
    @Option(help: "Shows folder")
    var showsFolder: String

    @Argument(help: "Folder to organize")
    var path: String
    
    @Option(help: "Log verbosity level.")
    var logLevel: Log.Level = .info
    
    mutating func run() throws {
        Log.level = logLevel
        
        let lock = Lock(url: Config.lockFileURL)
        guard lock.acquire() else {
            print("Already running, marked need for a new run once the current one is done")
            Config.runAgainFlagURL.touch()
            return
        }
        defer { lock.release() }

        try? FileManager.default.removeItem(atPath: Config.runAgainFlagURL.asPath)

        runOnce()

        if Config.runAgainFlagURL.exists {
            print("Needs another run, starting now!")
            try run()
        }
    }
    
    private func runOnce() {
        let moviesURL = FileURL(path: moviesFolder)
        let showsURL = FileURL(path: showsFolder)
        let downloadsURL = FileURL(path: path)

        print("Organizing: \(downloadsURL.asPath)")
        
        var pathsToOrganize = [downloadsURL]
        pathsToOrganize += FileManager.default.children(at: downloadsURL, ignoringUnderscores: true).filter { $0.isDirectory }
        
        for p in pathsToOrganize {
            let medias = FileManager.default.children(at: p, ignoringUnderscores: true).compactMap(\.asMedia)
            for m in medias {
                let relM = m.url.asPath(relativeTo: downloadsURL)
                do {
                    print("---------------")
                    Log.i(relM, "TODO: Download subtitles")

                    let hunch = try Hunch.analyze(m.url, inside: downloadsURL)
                    let newMediaURL = try m.url.suggestURL(using: hunch, moviesRoot: moviesURL, seriesRoot: showsURL)
                    Log.i(relM, "Found \(m.findSubtitles().count) subtitles")
                    Log.i(relM, "TODO: Move to \(newMediaURL.asPath)")
                    Log.i(relM, "TODO: Move subtitles too")
                }
                catch {
                    Log.e(relM, "Error: \(error.localizedDescription)")
                }
            }
        }
        
        FileManager.default.cleanup(at: downloadsURL)
    }
}
