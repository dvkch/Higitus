//
//  FileManager+SY.swift
//  Higitus
//
//  Created by syan on 20/09/2026.
//

import Foundation

extension FileManager {
    func children(at url: FileURL, ignoringUnderscores: Bool) throws(AppError) -> [FileURL] {
        do {
            return try self.contentsOfDirectory(at: url.asURL, includingPropertiesForKeys: nil, options: [])
                .map {
                    FileURL(url: $0)
                }
                .filter {
                    if ignoringUnderscores && $0.asURL.lastPathComponent.first == "_" {
                        return false
                    }
                    return true
                }
                .sorted()
        }
        catch {
            throw .fileError(url, error)
        }
    }
    
    func mediaFiles(under url: FileURL) throws(AppError) -> [Media] {
        var results: [Media] = []
        for child in try children(at: url, ignoringUnderscores: true) {
            if child.isDirectory {
                results += try mediaFiles(under: child)
            } else if let media = child.asMedia {
                results.append(media)
            }
        }
        return results.sorted()
    }
}

// MARK: Cleanup
extension FileManager {
    func cleanup(at url: FileURL, isDeletable: Bool) throws(AppError) {
        guard url.isDirectory else { return }
        
        for child in try self.children(at: url, ignoringUnderscores: true) {
            if child.isDirectory {
                try cleanup(at: child, isDeletable: true)
            }
            else if child.isCleanupable {
                try child.delete()
            }
        }
        
        if isDeletable, try self.children(at: url, ignoringUnderscores: false).count == 0 {
            try url.delete()
        }
    }
}
