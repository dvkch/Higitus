//
//  Lang.swift
//  Higitus
//
//  Created by syan on 22/09/2026.
//

import Foundation

struct Lang: RawRepresentable, Hashable {
    init?(rawValue: String) {
        guard let corrected = Locale.LanguageCode(rawValue.lowercased()).identifier(.alpha2) else {
            return nil
        }
        self.rawValue = corrected
    }
    
    let rawValue: String
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: Lang) {
        appendLiteral(value.rawValue)
    }
}
