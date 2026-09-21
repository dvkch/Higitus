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

        let opensubtitles = OpenSubtitlesClient(
            apiKey: options.opensubtitlesApiKey,
            username: options.opensubtitlesUsername,
            password: options.opensubtitlesPassword
        )
        try opensubtitles.login()
        
        let medias = try FileManager.default.mediaFiles(under: downloadsURL)
        for m in medias {
            let relM = m.mediaURL.asPath(relativeTo: downloadsURL)
            do {
                print("---------------")
                Log.i(relM, "Analyzing")

                let hunch = try Hunch.analyze(m.mediaURL, inside: downloadsURL)
                let newMediaURL = try m.mediaURL.suggestURL(using: hunch, moviesRoot: moviesURL, seriesRoot: showsURL)
                let existingSubtitles = try m.findSubtitles()
                Log.i(relM, "Found subtitles: \(existingSubtitles.keys.joined(separator: ", "))")

                let subtitlesToDownload = Set(options.subtitlesLocalesArray).subtracting(existingSubtitles.keys)
                Log.i(relM, "Will download subtitles: \(subtitlesToDownload.joined(separator: ", "))")
                for locale in subtitlesToDownload {
                    do {
                        let file = try opensubtitles.search(
                            hunch: hunch, hash: m.mediaURL.openSubtitlesHash(), language: locale
                        )
                        guard let file else {
                            Log.w(relM, "No available subtitles for \(locale)")
                            continue
                        }
                        try opensubtitles.download(file, to: m.mediaURL.replacingExtension(with: "\(locale).srt"))
                    }
                    catch {
                        Log.e(relM, "Couldn't find subtitles for \(locale)")
                    }
                }
                
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
