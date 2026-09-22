//
//  OpenSubtitlesErrorResponse.swift
//  Higitus
//
//  Created by syan on 21/09/2026.
//

import Foundation

struct OpenSubtitlesErrorResponse: Codable {
    let status: Int

    let message: String?
    let errors: [String]?
}

extension OpenSubtitlesErrorResponse {
    var description: String {
        if let message {
            return message
        }
        if let errors {
            return errors.joined(separator: ", ")
        }
        return "Status code \(status)"
    }
}
