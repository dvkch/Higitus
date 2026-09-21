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
    
    @OptionGroup var options: Options

    @Option(help: "Transmission config.json path")
    var transmissionConfigPath: String

    mutating func run() throws {
        Log.level = options.logLevel
        
        let transmission = Transmission(configURL: FileURL(path: transmissionConfigPath))
        let selfPath = FileURL.higitusURL.asPath
        // we expect the params to be available via env vars here, or the hook won't be able to run.
        try transmission.setPostDownloadHook(to: selfPath)

        print("\(transmissionConfigPath) has been updated to run \(selfPath)")
    }
}
