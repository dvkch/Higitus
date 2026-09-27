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
        guard let parent = mediaURL.parent else { return [] }
        let mediaURLWithoutExtension = mediaURL.replacingExtension(with: nil).asPath
        
        var subtitles = [MediaSubtitle]()
        
        for file in try FileManager.default.children(at: parent, ignoringUnderscores: false) {
            guard MediaSubtitle.supportedExtensions.contains(file.asURL.pathExtension.lowercased()) else { continue }
            guard file.asPath.lowercased().hasPrefix(mediaURLWithoutExtension.lowercased()) else { continue }
            
            let subtitleName = file.asPath.replacingOccurrences(of: mediaURLWithoutExtension + ".", with: "", options: .caseInsensitive).lowercased()
            var language = subtitleName.split(separator: ".").first ?? "en"
            if language == "srt" { language = "en" }
            
            guard let lang = Lang(rawValue: String(language)) else {
                Log.w("Media", "Unknown language code: \(language), skipping subtitle file")
                continue
            }
            
            subtitles.append(MediaSubtitle(path: file, lang: lang))
        }
        
        return subtitles
    }
}

extension Media {
    func move(to suggestedURL: FileURL, folderCreation: FolderCreationPolicy) throws(AppError) {
        let adaptedURL = try suggestedURL.adapted(folderCreation: folderCreation)
        try mediaURL.move(to: adaptedURL)

        for subtitle in try findSubtitles() {
            let newSubtitleURL = adaptedURL.replacingExtension(with: "\(subtitle.lang).srt")
            try subtitle.path.move(to: newSubtitleURL)
        }
    }
}
