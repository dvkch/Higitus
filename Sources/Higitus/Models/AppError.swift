//
//  AppError.swift
//  Higitus
//
//  Created by syan on 03/09/2026.
//

import Foundation

enum AppError {
    case transmissionConfigNotFound(FileURL)
    case transmissionConfigNotUpdatable(FileURL, Error)
    case fileNotFound(FileURL)
    case fileNotHashable(FileURL)
    case openSubtitlesRequestFailed(String)
    case hunchError(String)
    case couldntGeneratePath(FileURL, HunchResult)
    case notAMediaFile(FileURL)
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .transmissionConfigNotFound(let url): "Couldn't find transmission config at \(url.asPath)"
            
        case .transmissionConfigNotUpdatable(let url, let error): "Couldn't update transmission config at \(url.asPath): \(error.localizedDescription)"
            
        case .fileNotFound(let url): "Couldn't find file at \(url.asPath)"
            
        case .fileNotHashable(let url): "File at \(url.asPath) is not hashable"
            
        case .openSubtitlesRequestFailed(let message): "OpenSubtitles request failed: \(message)"
            
        case .hunchError(let message): message
            
        case .couldntGeneratePath(let url, let result): "Couldn't generate a proper filename for \(url.asPath): \(result)"
            
        case .notAMediaFile(let url): "File at \(url.asPath) is not a media file"
        }
    }
}
