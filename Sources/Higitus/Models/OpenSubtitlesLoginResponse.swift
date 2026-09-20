//
//  OpenSubtitlesLoginResponse.swift
//  Higitus
//
//  Created by syan on 17/09/2026.
//

import Foundation

struct OpenSubtitlesLoginResponse: Codable {
    let token: String
    let status: Int
    let user: User?

    struct User: Codable {
        let userId: Int?
        let allowedDownloads: Int?
        let level: String?
        let vip: Bool?
    }
}
