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
        guard Self.supportedExtensions.contains(url.asURL.pathExtension.lowercased()) else {
            return nil
        }
        guard let tags = Self.tags(of: url, for: media.mediaURL) else {
            return nil
        }

        let tokens = tags
            .split(whereSeparator: { ". _-".contains($0) })
            .map { $0.lowercased() }
        let flags = Set(tokens).intersection(Self.hiFlags)
        let candidates = tokens.filter { !Self.hiFlags.contains($0) }

        if let lang = candidates.lazy.compactMap({ Lang(rawValue: $0) }).first {
            self.lang = lang
            self.isHI = !flags.isEmpty
        }
        else if flags == ["hi"], candidates.isEmpty, let hindi = Lang(rawValue: "hi") {
            // "Movie.hi.srt": a lone "hi" is Hindi, not hearing impaired
            self.lang = hindi
            self.isHI = false
        }
        else if candidates.isEmpty, let english = Lang(rawValue: "en") {
            // "Movie.srt" or "Movie.sdh.srt": no language given
            self.lang = english
            self.isHI = !flags.isEmpty
        }
        else {
            Log.w("Subtitle", "Couldn't identify language for \(url.asURL.lastPathComponent), skipping subtitle file")
            return nil
        }
        self.url = url
    }

    // The descriptive part of the subtitle's name, or nil if it doesn't belong to this media.
    private static func tags(of sub: FileURL, for media: FileURL) -> String? {
        let mediaStem = media.asURL.deletingPathExtension().lastPathComponent.lowercased()
        let mediaDir  = media.asURL.deletingLastPathComponent().standardizedFileURL.path.lowercased()
        let subStem   = sub.asURL.deletingPathExtension().lastPathComponent
        let subDir    = sub.asURL.deletingLastPathComponent().standardizedFileURL.path.lowercased()

        // "Movie.srt", "Movie.en.srt", "Movie.en.sdh.srt"
        if subDir == mediaDir {
            let lower = subStem.lowercased()
            if lower == mediaStem { return "" }
            if lower.hasPrefix(mediaStem + ".") { return String(subStem.dropFirst(mediaStem.count + 1)) }
            return nil
        }

        // "Subs/English.srt", "Subs/2_English.srt", "Subs/Episode/3_French.srt"
        let subsDir = mediaDir + "/subs"
        if subDir == subsDir || subDir == subsDir + "/" + mediaStem {
            return subStem
        }
        return nil
    }
}

extension MediaSubtitle {
    static func candidateURLs(for media: Media) throws(AppError) -> [FileURL] {
        guard let parent = media.mediaURL.parent else { return [] }
        return try candidateURLs(in: parent, insideSubs: false)
    }

    private static func candidateURLs(in folder: FileURL, insideSubs: Bool) throws(AppError) -> [FileURL] {
        var results: [FileURL] = []
        for child in try FileManager.default.children(at: folder, ignoringUnderscores: false) {
            if child.isDirectory {
                if insideSubs || child.asURL.lastPathComponent.lowercased() == "subs" {
                    results += try candidateURLs(in: child, insideSubs: true)
                }
            }
            else if supportedExtensions.contains(child.asURL.pathExtension.lowercased()) {
                results.append(child)
            }
        }
        return results
    }
}

extension MediaSubtitle {
    static let supportedExtensions: Set<String> = ["srt"]
    private static let hiFlags: Set<String> = ["hi", "sdh", "cc"]
}
