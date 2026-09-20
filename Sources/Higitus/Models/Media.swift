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
    func findSubtitles() throws -> [String: FileURL] {
        guard let parent = mediaURL.parent else { return [:] }
        let mediaURLWithoutExtension = mediaURL.asURL.deletingPathExtension().path(percentEncoded: false)
        
        var subtitles = [String: FileURL]()
        
        for file in try FileManager.default.children(at: parent, ignoringUnderscores: false) {
            guard file.asURL.pathExtension.lowercased() == "srt" else { continue }
            guard file.asPath.hasPrefix(mediaURLWithoutExtension) else { continue }
            
            let subtitleName = file.asPath.replacingOccurrences(of: mediaURLWithoutExtension + ".", with: "", options: .caseInsensitive).lowercased()
            var language = subtitleName.split(separator: ".").first ?? "en"
            if language == "srt" { language = "en" }
            subtitles[String(language)] = file
        }
        
        return subtitles
    }
}
