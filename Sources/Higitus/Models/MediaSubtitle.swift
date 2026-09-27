//
//  MediaSubtitle.swift
//  Higitus
//
//  Created by syan on 27/09/2026.
//

import Foundation

struct MediaSubtitle {
    let url: FileURL
    let lang: Lang
    let isHI: Bool
}

extension MediaSubtitle {
    init?(url: FileURL, for media: Media) {
        guard MediaSubtitle.supportedExtensions.contains(url.asURL.pathExtension.lowercased()) else {
            return nil
        }

        // Format: "MovieName.lang.ext"
        let mediaURLWithoutExtension = media.mediaURL.replacingExtension(with: nil).asPath
        if url.asPath.lowercased().hasPrefix(mediaURLWithoutExtension.lowercased()) {
            let subtitleName = url.asPath.replacingOccurrences(
                of: mediaURLWithoutExtension + ".", with: "", options: .caseInsensitive
            ).lowercased()

            var language = subtitleName.split(separator: ".").first ?? "en"
            if language == "srt" { language = "en" }
            
            guard let lang = Lang(rawValue: String(language)) else {
                Log.w("Subtitle", "Unknown language code: \(language), skipping subtitle file")
                return nil
            }

            self.url = url
            self.lang = lang
            self.isHI = false
            return
        }
        
        // Format: "Subs/Language.ext" or "Subs/SDH.lang.HI.ext"
        let pathRelativeToMediaParent = url.asPath(relativeTo: FileURL(url: media.mediaURL.asURL.deletingLastPathComponent()))
        if pathRelativeToMediaParent.lowercased().hasPrefix("subs/") {
            var subtitleNameParts = url.asURL.deletingPathExtension().lastPathComponent.split(separator: ".")
            if subtitleNameParts.count > 1 && subtitleNameParts.last == "HI" {
                self.isHI = true
                subtitleNameParts.removeLast()
            }
            else {
                self.isHI = false
            }
            guard let langBestGuess = subtitleNameParts.reversed().compactMap({ Lang(rawValue: String($0)) }).first else {
                Log.w("Subtitle", "Couldn't identify language for \(pathRelativeToMediaParent), skipping subtitle file")
                return nil
            }
            self.url = url
            self.lang = langBestGuess
            return
        }

        return nil
    }
}

extension MediaSubtitle {
    static var supportedExtensions: [String] {
        ["srt"]
    }
}
