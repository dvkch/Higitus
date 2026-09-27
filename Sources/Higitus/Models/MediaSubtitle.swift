//
//  MediaSubtitle.swift
//  Higitus
//
//  Created by syan on 27/09/2026.
//

import Foundation

struct MediaSubtitle {
    let path: FileURL
    let lang: Lang
}

extension MediaSubtitle {
    static var supportedExtensions: [String] {
        ["srt"]
    }
}
