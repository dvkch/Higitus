//
//  SingleOrArray.swift
//  Higitus
//
//  Created by syan on 17/09/2026.
//

import Foundation

struct SingleOrArray<T: Codable>: Codable {
    let values: [T]

    var first: T? { values.first }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let array = try? container.decode([T].self) {
            values = array
        } else {
            values = [try container.decode(T.self)]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if values.count == 1 {
            try container.encode(values[0])
        } else {
            try container.encode(values)
        }
    }
}
