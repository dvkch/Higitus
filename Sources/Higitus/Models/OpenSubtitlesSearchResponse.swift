//
//  OpenSubtitlesSearchResponse.swift
//  Higitus
//
//  Created by syan on 17/09/2026.
//

import Foundation

typealias OpenSubtitlesFile = OpenSubtitlesSearchResponse.Subtitle.Attributes.File

struct OpenSubtitlesSearchResponse: Codable {
    let totalPages: Int
    let totalCount: Int
    let page: Int
    let data: [Subtitle]

    struct Subtitle: Codable {
        let id: String
        let attributes: Attributes

        struct Attributes: Codable {
            let subtitleId: String?
            let language: String?
            let downloadCount: Int?
            let release: String?
            let files: [File]

            struct File: Codable {
                let fileId: Int
                let cdNumber: Int?
                let fileName: String?
            }
        }
    }
}
