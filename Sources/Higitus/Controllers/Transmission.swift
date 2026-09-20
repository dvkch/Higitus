//
//  Transmission.swift
//  Higitus
//
//  Created by syan on 03/09/2026.
//

import Foundation

struct Transmission {
    init(configURL: FileURL) {
        self.configURL = configURL
    }
    
    let configURL: FileURL
    
    func setPostDownloadHook(to hook: String) throws(AppError) {
        guard let data = try? Data(contentsOf: configURL.asURL),
              var json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw AppError.transmissionConfigNotFound(configURL)
        }

        json["script-torrent-done-enabled"] = true
        json["script-torrent-done-filename"] = hook

        let newData = try! JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])

        do {
            try newData.write(to: configURL.asURL)
            Log.i("Transmission", "Enabled '\(hook)' as torrent done script")
        } catch {
            throw AppError.transmissionConfigNotUpdatable(configURL, error)
        }
    }
}
