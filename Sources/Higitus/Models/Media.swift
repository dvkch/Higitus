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
        guard Media.supportedExtensions.contains(url.asURL.pathExtension.lowercased()) else {
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
        
        let groupedSubtitles = subtitles.reduce(into: [Lang: [MediaSubtitle]]()) { groups, sub in
            groups[sub.lang, default: []].append(sub)
        }
        return groupedSubtitles.values.compactMap { subs in
            // TODO: allow the user to prefer HI over regular via env var
            subs.min(by: { sub1, sub2 in
                if !sub1.isHI && sub2.isHI { return true }
                if sub1.isHI && !sub2.isHI { return false }
                return sub1.url.fileSize > sub2.url.fileSize
            })
        }
    }
}

extension Media {
    func move(to suggestedURL: FileURL, folderCreation: FolderCreationPolicy) throws(AppError) {
        let subtitles = try findSubtitles()

        let adaptedURL = try suggestedURL.adapted(folderCreation: folderCreation)
        try mediaURL.move(to: adaptedURL)

        for subtitle in subtitles {
            let newSubtitleURL = adaptedURL.replacingExtension(with: "\(subtitle.lang).srt")
            do {
                try subtitle.url.move(to: newSubtitleURL)
            }
            catch {
                Log.w("Subtitle", "Couldn't move \(subtitle.url.asPath): \(error.localizedDescription)")
            }
        }
    }
}
