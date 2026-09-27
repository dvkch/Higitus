//
//  String+SY.swift
//  Higitus
//
//  Created by syan on 27/09/2026.
//

import Foundation

extension String {
    var noCaseNoDiacritics: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
