//
//  FileManager+SY.swift
//  Higitus
//
//  Created by syan on 20/09/2026.
//

import Foundation

extension FileManager {
    func children(at url: FileURL, ignoringUnderscores: Bool) -> [FileURL] {
        try! self.contentsOfDirectory(at: url.asURL, includingPropertiesForKeys: nil, options: [])
            .map {
                FileURL(url: $0)
            }
            .filter {
                if ignoringUnderscores && $0.asURL.lastPathComponent.first == "_" {
                    return false
                }
                return true
            }
    }
}

// MARK: Cleanup
extension FileManager {
    func cleanup(at url: FileURL) {
        guard url.isDirectory else { return }
        
        for child in self.children(at: url, ignoringUnderscores: true) {
            if child.isDirectory {
                cleanup(at: url)
            }
            else if child.isCleanupable {
                try! self.removeItem(at: child.asURL)
            }
        }
        
        if self.children(at: url, ignoringUnderscores: false).count == 0 {
            try! self.removeItem(at: url.asURL)
        }
    }
}
