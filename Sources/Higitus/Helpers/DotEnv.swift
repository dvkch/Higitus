//
//  DotEnv.swift
//  Higitus
//
//  Created by syan on 21/09/2026.
//

import Foundation

enum DotEnv {
    static func load(path: String = ".env") {
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else { return }

        for line in contents.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#"),
                  let separator = trimmed.firstIndex(of: "=") else { continue }

            let key = String(trimmed[..<separator]).trimmingCharacters(in: .whitespaces)
            var value = String(trimmed[trimmed.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
            if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
                value = String(value.dropFirst().dropLast())
            }

            // 0 = don't overwrite a real env var
            setenv(key, value, 0)
        }
    }
}
