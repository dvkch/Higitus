//
//  CommandInit.swift
//  Higitus
//
//  Created by syan on 17/09/2026.
//

import Foundation
import ArgumentParser

struct CommandInit: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Sets this script as a post-download hook"
    )
    
    @Option(help: "Transmission config.json path")
    var transmissionConfigPath: String

    @Option(help: "Log verbosity level.")
    var logLevel: Log.Level = .info
    
    mutating func run() throws {
        Log.level = logLevel
        
        let transmission = Transmission(configURL: FileURL(path: transmissionConfigPath))
        let selfPath = FileURL.higitusURL.asPath
        // TODO: add params too, right ?
        try transmission.setPostDownloadHook(to: selfPath)

        print("\(transmissionConfigPath) has been updated to run \(selfPath)")
    }
}
