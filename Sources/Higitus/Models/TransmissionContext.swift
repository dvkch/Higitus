//
//  TransmissionContext.swift
//  Higitus
//
//  Created by syan on 21/09/2026.
//

import Foundation

struct TransmissionContext {
    let torrentName: String?
    let torrentDir: FileURL?
    let torrentHash: String?
    let labels: [String]?

    static var current: TransmissionContext {
        let env = ProcessInfo.processInfo.environment
        return TransmissionContext(
            torrentName: env["TR_TORRENT_NAME"],
            torrentDir: env["TR_TORRENT_DIR"].map(FileURL.init(path:)),
            torrentHash: env["TR_TORRENT_HASH"],
            labels: env["TR_TORRENT_LABELS"]?.split(separator: ",").map(String.init)
        )
    }
}
