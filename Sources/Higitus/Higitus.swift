//
//  Higitus.swift
//  higitus
//
//  Created by syan on 03/09/2026.
//

import ArgumentParser

@main
struct Higitus: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "higitus",
        abstract: "Organizes your download folder.",
        version: "1.0.2",
        subcommands: [
            CommandInit.self,
            CommandFigitus.self
        ],
        defaultSubcommand: CommandFigitus.self
    )
    
    static func main() {
        DotEnv.load(path: ".env")
        DotEnv.load(path: "higitus.env")
        do {
            var command = try parseAsRoot()
            try command.run()
        } catch {
            exit(withError: error)
        }
    }
}
