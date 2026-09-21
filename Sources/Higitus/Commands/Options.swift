//
//  Options.swift
//  Higitus
//
//  Created by syan on 21/09/2026.
//

import Foundation
import ArgumentParser

struct Options: ParsableArguments {

    // MARK: Paths
    @Option(name: .customLong(Item.path.name.arg), help: "Folder to organize (\(Item.path.name.env))")
    var path: FileURL!

    @Option(name: .customLong(Item.moviesPath.name.arg), help: "Movies folder (\(Item.moviesPath.name.env))")
    var moviesPath: FileURL!
    
    @Option(name: .customLong(Item.showsPath.name.arg), help: "Shows folder (\(Item.showsPath.name.env))")
    var showsPath: FileURL!
    
    @Option(name: .customLong(Item.showsFolderCreation.name.arg), help: "How to create series folders that don't already exist (\(Item.showsFolderCreation.name.env))")
    var showsFolderCreation: FolderCreationPolicy!
    
    // MARK: OpenSubtitles
    @Option(name: .customLong(Item.opensubtitlesApiKey.name.arg), help: "OpenSubtitles API key (\(Item.opensubtitlesApiKey.name.env))")
    var opensubtitlesApiKey: String!

    @Option(name: .customLong(Item.opensubtitlesUsername.name.arg), help: "OpenSubtitles username (\(Item.opensubtitlesUsername.name.env))")
    var opensubtitlesUsername: String!

    @Option(name: .customLong(Item.opensubtitlesPassword.name.arg), help: "OpenSubtitles password (\(Item.opensubtitlesPassword.name.env))")
    var opensubtitlesPassword: String!

    // MARK: Misc
    @Option(name: .customLong(Item.logLevel.name.arg), help: "Log verbosity level (\(Item.logLevel.name.env))")
    var logLevel: Log.Level!
}

extension Options {
    enum Item {
        case path
        case moviesPath
        case showsPath
        case showsFolderCreation
        case opensubtitlesApiKey
        case opensubtitlesUsername
        case opensubtitlesPassword
        case logLevel
        
        var name: (arg: String, env: String) {
            switch self {
            case .path:                  ("path", "HIGITUS_PATH")
            case .moviesPath:            ("movies-path", "HIGITUS_MOVIES_PATH")
            case .showsPath:             ("shows-path", "HIGITUS_SHOWS_PATH")
            case .showsFolderCreation:   ("shows-folder-creation", "HIGITUS_SHOWS_FOLDER_CREATION")
            case .opensubtitlesApiKey:   ("opensubtitles-api-key", "HIGITUS_OPENSUBTITLES_API_KEY")
            case .opensubtitlesUsername: ("opensubtitles-username", "HIGITUS_OPENSUBTITLES_USERNAME")
            case .opensubtitlesPassword: ("opensubtitles-password", "HIGITUS_OPENSUBTITLES_PASSWORD")
            case .logLevel:              ("log-level", "HIGITUS_LOG_LEVEL")
            }
        }
        
        var fullname: String {
            return "--\(name.arg) or \(name.env)"
        }
    }
}

extension Options {
    mutating func validate() throws(ValidationError) {
        do {
            try resolve(\.path, item: .path)
            guard path.exists, path.isDirectory else {
                throw AppError.wrongArgument(name: Item.path.fullname, message: "not found")
            }
            try resolve(\.moviesPath, item: .moviesPath)
            guard moviesPath.exists, moviesPath.isDirectory else {
                throw AppError.wrongArgument(name: Item.moviesPath.fullname, message: "not found")
            }
            try resolve(\.showsPath, item: .showsPath)
            guard showsPath.exists, showsPath.isDirectory else {
                throw AppError.wrongArgument(name: Item.showsPath.fullname, message: "not found")
            }
            try resolve(\.showsFolderCreation, item: .showsFolderCreation, default: .seasonOnly)
            
            try resolve(\.opensubtitlesApiKey, item: .opensubtitlesApiKey)
            try resolve(\.opensubtitlesUsername, item: .opensubtitlesUsername)
            try resolve(\.opensubtitlesPassword, item: .opensubtitlesPassword)
            
            try resolve(\.logLevel, item: .logLevel, default: .info)
        }
        catch {
            throw ValidationError(error.localizedDescription)
        }
    }
    
    private mutating func resolve<T: ExpressibleByArgument>(
        _ keyPath: WritableKeyPath<Options, T?>, item: Item, default: T? = nil
    ) throws(AppError) {
        guard self[keyPath: keyPath] == nil else {
            return
        }
        
        if let raw = ProcessInfo.processInfo.environment[item.name.env], !raw.isEmpty {
            guard let value = T(argument: raw) else {
                let allowed = T.allValueStrings.isEmpty ? "" : " (expected: \(T.allValueStrings.joined(separator: ", ")))"
                throw .wrongArgument(name: item.fullname, message: "invalid value '\(raw)'\(allowed)")
            }
            self[keyPath: keyPath] = value
        }
        else if let `default` {
            self[keyPath: keyPath] = `default`
        }
        else {
            throw .wrongArgument(name: item.fullname, message: "missing")
        }
    }
}
