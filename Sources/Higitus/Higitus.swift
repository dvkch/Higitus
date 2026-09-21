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
        subcommands: [
            CommandInit.self,
            CommandFigitus.self
        ],
        defaultSubcommand: CommandFigitus.self
    )
}
