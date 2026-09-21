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
    func findSubtitles() throws(AppError) -> [String: FileURL] {
        guard let parent = mediaURL.parent else { return [:] }
        let mediaURLWithoutExtension = mediaURL.asURL.deletingPathExtension().path(percentEncoded: false)
        
        var subtitles = [String: FileURL]()
        
        for file in try FileManager.default.children(at: parent, ignoringUnderscores: false) {
            guard file.asURL.pathExtension.lowercased() == "srt" else { continue }
            guard file.asPath.lowercased().hasPrefix(mediaURLWithoutExtension.lowercased()) else { continue }
            
            let subtitleName = file.asPath.replacingOccurrences(of: mediaURLWithoutExtension + ".", with: "", options: .caseInsensitive).lowercased()
            var language = subtitleName.split(separator: ".").first ?? "en"
            if language == "srt" { language = "en" }
            subtitles[String(language)] = file
        }
        
        return subtitles
    }
}

extension Media {
    func move(to suggestedURL: FileURL, folderCreation: FolderCreationPolicy) throws(AppError) {
        let adaptedURL = try suggestedURL.adapted(folderCreation: folderCreation)
        try mediaURL.move(to: adaptedURL)

        for (language, subtitleURL) in try findSubtitles() {
            let newSubtitleURL = adaptedURL.replacingExtension(with: "\(language).srt")
            try subtitleURL.move(to: newSubtitleURL)
        }
    }
}
