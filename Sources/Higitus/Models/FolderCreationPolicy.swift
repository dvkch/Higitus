//
//  FolderCreationPolicy.swift
//  Higitus
//
//  Created by syan on 21/09/2026.
//

import Foundation
import ArgumentParser

enum FolderCreationPolicy: String, CaseIterable, ExpressibleByArgument {
    // Create any missing folder in the suggested path.
    case always

    // Only auto-create a trailing "Season N" folder — every other missing
    // folder (typically the show's own top-level folder) is an error, so a
    // brand-new show never gets a folder auto-generated from a possibly-wrong
    // parse; only a new season of a show you already have a folder for does.
    case seasonOnly
}
