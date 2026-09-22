//
//  Hunch.swift
//  Higitus
//
//  Created by syan on 17/09/2026.
//

import Foundation

// https://github.com/lijunzh/hunch
struct Hunch {
    static func analyze(_ url: FileURL, inside parent: FileURL) throws(AppError) -> HunchResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["hunch", "--context", parent.asPath, "--json", url.asPath]

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe() // swallow hunch's own logging

        do {
            try process.run()
        } catch {
            throw .hunchError("Couldn't launch hunch: \(error.localizedDescription)")
        }
        process.waitUntilExit()

        let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            throw .hunchError("Hunch exited with error \(process.terminationStatus)")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(HunchResult.self, from: data)
        }
        catch {
            throw .hunchError("Couldnt decode hunch result for \(url.asPath): \(error.localizedDescription)")
        }
    }
}
