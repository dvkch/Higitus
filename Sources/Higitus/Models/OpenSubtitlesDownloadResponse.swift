//
//  OpenSubtitlesDownloadResponse.swift
//  Higitus
//
//  Created by syan on 17/09/2026.
//

import Foundation

struct OpenSubtitlesDownloadResponse: Codable {
    let link: String
    let fileName: String?
    let requests: Int?
    let remaining: Int?
}
