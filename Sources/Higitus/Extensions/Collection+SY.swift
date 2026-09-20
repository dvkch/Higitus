//
//  Collection+SY.swift
//  Higitus
//
//  Created by syan on 21/09/2026.
//

import Foundation

extension Collection {
    var nilIfEmpty: Self? {
        if isEmpty {
            return nil
        }
        return self
    }
    
    var isNotEmpty: Bool {
        return !isEmpty
    }
}
