//
//  Lang.swift
//  Higitus
//
//  Created by syan on 22/09/2026.
//

import Foundation

struct Lang: RawRepresentable, Hashable {
    init?(rawValue: String) {
        let input = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let code = Locale.LanguageCode(input.lowercased()).shortestIdentifier {
            self.rawValue = code
            return
        }
        
        if let code = Lang.nameToCode[input.noCaseNoDiacritics] {
            self.rawValue = code
            return
        }
        
        return nil
    }
    
    let rawValue: String
}

extension Lang {
    private static let nameToCode: [String: String] = {
        let english = Locale(identifier: "en")
        var map: [String: String] = [:]

        for code in Locale.LanguageCode.isoLanguageCodes {
            guard let short = code.shortestIdentifier else { continue }
            let id = code.identifier

            let names = [
                english.localizedString(forLanguageCode: id),                  // "French"
                Locale(identifier: id).localizedString(forLanguageCode: id),   // "français"
            ].compactMap { $0 }

            for name in names {
                map[name.noCaseNoDiacritics] = short
            }
        }
        return map
    }()
}

extension Locale.LanguageCode {
    fileprivate var shortestIdentifier: String? {
        identifier(.alpha2) ?? identifier(.alpha3)
    }
}

extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: Lang) {
        appendLiteral(value.rawValue)
    }
}
