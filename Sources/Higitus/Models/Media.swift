//
//  Media.swift
//  Higitus
//
//  Created by syan on 20/09/2026.
//

import Foundation

struct Media {
    init(url: FileURL) throws(AppError) {
        self.url = url
        guard Media.supportedExtensions.contains(url.asURL.pathExtension) else {
            throw .notAMediaFile(url)
        }
    }
    
    // MARK: Properties
    let url: FileURL
}

extension Media {
    static var supportedExtensions: [String] {
        ["mkv", "mp4", "m4v", "avi"]
    }
}

extension Media {
    func findSubtitles() -> [FileURL] {
        let languageLessSubtitleURL = url.replacingExtension(with: "srt")
        if languageLessSubtitleURL.exists {
            let newSubtitleURL = languageLessSubtitleURL.replacingExtension(with: "en.srt")
            try! FileManager.default.moveItem(at: languageLessSubtitleURL.asURL, to: newSubtitleURL.asURL)
        }
        
        guard let parent = url.parent else { return [] }
        
        let pattern = url.asURL.deletingPathExtension().path(percentEncoded: false) + ".*.srt"
        return FileManager.default.children(at: parent, ignoringUnderscores: false).filter {
            $0.matchesPattern(pattern)
        }
    }
}
