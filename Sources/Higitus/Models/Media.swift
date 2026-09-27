//
//  Media.swift
//  Higitus
//
//  Created by syan on 20/09/2026.
//

import Foundation

struct Media {
    init(_ url: FileURL) throws(AppError) {
        self.mediaURL = url
        guard Media.supportedExtensions.contains(url.asURL.pathExtension) else {
            throw .notAMediaFile(url)
        }
    }
    
    // MARK: Properties
    let mediaURL: FileURL
}

extension Media: Comparable {
    static func < (lhs: Media, rhs: Media) -> Bool {
        lhs.mediaURL < rhs.mediaURL
    }
}

extension Media {
    static var supportedExtensions: [String] {
        ["mkv", "mp4", "m4v", "avi"]
    }
}

extension Media {
    func findSubtitles() throws(AppError) -> [MediaSubtitle] {
        let subtitles = try MediaSubtitle.candidateURLs(for: self).compactMap {
            MediaSubtitle(url: $0, for: self)
        }
        
        var groupedSubtitles = subtitles.reduce(into: [:]) { groups, sub in
            groups[sub.lang, default: []].append(sub)
        }
        for lang in groupedSubtitles.keys {
            groupedSubtitles[lang] = groupedSubtitles[lang]!.sorted(by: { sub1, sub2 in
                // TODO: allow the user to prefer HI over regular via env var
                if !sub1.isHI && sub2.isHI { return true }
                if sub1.isHI && !sub2.isHI { return false }
                return true
            })
        }
        return groupedSubtitles.values.compactMap { $0.first }
    }
}

extension Media {
    func move(to suggestedURL: FileURL, folderCreation: FolderCreationPolicy) throws(AppError) {
        let adaptedURL = try suggestedURL.adapted(folderCreation: folderCreation)
        try mediaURL.move(to: adaptedURL)

        for subtitle in try findSubtitles() {
            let newSubtitleURL = adaptedURL.replacingExtension(with: "\(subtitle.lang).srt")
            try subtitle.url.move(to: newSubtitleURL)
        }
    }
}
