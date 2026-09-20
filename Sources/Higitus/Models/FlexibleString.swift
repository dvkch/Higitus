//
//  FlexibleString.swift
//  Higitus
//
//  Created by syan on 17/09/2026.
//

import Foundation

struct FlexibleString: Codable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = String(int)
        } else {
            let double = try container.decode(Double.self)
            value = String(double)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
