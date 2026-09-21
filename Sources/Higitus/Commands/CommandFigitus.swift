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
    
    mutating func run() throws {
        Log.level = options.logLevel

        let lock = Lock(url: .lockFile)
        guard lock.acquire() else {
            print("Already running, marked need for a new run once the current one is done")
            FileURL.runAgainFlag.touch()
            return
        }
        defer { lock.release() }

        try? FileURL.runAgainFlag.delete()

        try runOnce(
            downloadsURL: options.path,
            moviesURL: options.moviesPath,
            showsURL: options.showsPath
        )

        if FileURL.runAgainFlag.exists {
            print("Needs another run, starting now!")
            try run()
        }
    }
    
    private func runOnce(downloadsURL: FileURL, moviesURL: FileURL, showsURL: FileURL) throws(AppError) {
        print("Organizing: \(downloadsURL.asPath)")

        // SETUP
        let opensubtitles = OpenSubtitlesClient(
            apiKey: options.opensubtitlesApiKey,
            username: options.opensubtitlesUsername,
            password: options.opensubtitlesPassword
        )
        do {
            try opensubtitles.login()
        } catch {
            Log.w("OpenSubtitles", "Login failed, continuing without an account (lower quota): \(error.localizedDescription)")
        }

        // MAIN LOOP
        let medias = try FileManager.default.mediaFiles(under: downloadsURL)
        for m in medias {
            let relM = m.mediaURL.asPath(relativeTo: downloadsURL)
            do {
                print("---------------")

                // ANALYSE
                Log.i(relM, "Analyzing")

                let hunch = try Hunch.analyze(m.mediaURL, inside: downloadsURL)
                let newMediaURL = try m.mediaURL.suggestURL(using: hunch, moviesRoot: moviesURL, seriesRoot: showsURL)
                let existingSubtitles = try m.findSubtitles()
                Log.i(relM, "Found subtitles: \(existingSubtitles.keys.joined(separator: ", "))")

                // DOWNLOAD SUBTITLES
                let subtitlesToDownload = Set(options.subtitlesLocalesArray).subtracting(existingSubtitles.keys)
                if subtitlesToDownload.isNotEmpty {
                    for locale in subtitlesToDownload {
                        do {
                            let hash = try? m.mediaURL.openSubtitlesHash()
                            let file = try opensubtitles.search(hunch: hunch, hash: hash, language: locale)
                            guard let file else {
                                Log.w(relM, "No available subtitles for \(locale)")
                                continue
                            }
                            try opensubtitles.download(file, to: m.mediaURL.replacingExtension(with: "\(locale).srt"))
                            Log.i(relM, "Downloaded subtitle '\(locale)'")
                        }
                        catch {
                            Log.e(relM, "Couldn't find subtitles for \(locale)")
                        }
                    }
                }
                else {
                    Log.i(relM, "All subtitles already present")
                }
                
                // MOVE FILES
                try m.move(to: newMediaURL, folderCreation: options.showsFolderCreation)
                Log.i(relM, "Media and subtitles moved to \(newMediaURL.asPath)")
            }
            catch {
                Log.e(relM, "Error: \(error.localizedDescription)")
            }
        }
        
        try FileManager.default.cleanup(at: downloadsURL, isDeletable: false)
    }
}
