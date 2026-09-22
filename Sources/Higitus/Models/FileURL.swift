//
//  FileURL.swift
//  Higitus
//
//  Created by syan on 03/09/2026.
//

import Foundation
import ArgumentParser

#if canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Darwin)
import Darwin
#endif


struct FileURL {
    private let url: URL
    
    init(url: URL) {
        self.url = url.standardizedFileURL
    }
    
    init(path: String) {
        self.url = URL(filePath: (path as NSString).expandingTildeInPath).standardizedFileURL
    }
    
    var asURL: URL { url }
    var asPath: String { url.path(percentEncoded: false) }
    func asPath(relativeTo root: FileURL) -> String {
        let rootComponents = root.asURL.pathComponents
        let ourComponents = asURL.pathComponents
        guard ourComponents.starts(with: rootComponents) else { return asPath }
        return ourComponents.dropFirst(rootComponents.count).joined(separator: "/")
    }
    var asNSURL: NSURL { url as NSURL }
    var asMedia: Media? { try? Media(self) }
}

extension FileURL {
    static let lockFile = FileURL(path: "/var/tmp/organize_lock")
    static let runAgainFlag = FileURL(path: "/var/tmp/organize_runagain")
}

extension FileURL: ExpressibleByArgument {
    init?(argument: String) {
        self.init(path: argument)
    }
}

extension FileURL: Hashable, Equatable, Comparable {
    static func < (lhs: FileURL, rhs: FileURL) -> Bool {
        return lhs.asPath < rhs.asPath
    }
}

extension FileURL {
    static var higitusURL: FileURL {
        #if os(Linux)
        FileURL(url: URL(fileURLWithPath: "/proc/self/exe").resolvingSymlinksInPath())
        #else
        FileURL(path: Bundle.main.executablePath!)
        #endif
    }
}

extension FileURL {
    var isDirectory: Bool {
        return (try? asURL.resourceValues(forKeys: Set([.isDirectoryKey])).isDirectory) == true
    }
    
    var exists: Bool {
        return FileManager.default.fileExists(atPath: asPath)
    }

    func touch(contents: String? = nil) {
        if !FileManager.default.fileExists(atPath: asPath) {
            _ = FileManager.default.createFile(atPath: asPath, contents: contents?.data(using: .utf8))
        }
    }
    
    func move(to newURL: FileURL) throws(AppError) {
        do {
            try FileManager.default.moveItem(at: asURL, to: newURL.asURL)
        }
        catch {
            throw .fileError(self, error)
        }
    }
    
    func delete() throws(AppError) {
        do {
            try FileManager.default.removeItem(at: asURL)
        }
        catch {
            throw .fileError(self, error)
        }
    }

    func matchesPattern(_ pattern: String) -> Bool {
        let patternParts = pattern.split(separator: "/").map(String.init)
        guard asURL.pathComponents.count >= patternParts.count else { return false }
        return zip(asURL.pathComponents.suffix(patternParts.count), patternParts)
                .allSatisfy { fnmatch($1, $0, 0) == 0 }
    }
    
    var isCleanupable: Bool {
        let patterns = [
            "*.nfo", "*orrent*.txt", "*.sfv", "RARBG*",
            "Screens/*.jpg", "Screens/*.png", "Ozlem.png",
            ".DS_Store", "*.sample.*", "WWW.YTS.*.jpg",
            "Screenshots/*.jpg", "Other/AhaShare.com.txt",
            "WWW.YIFY*.jpg", "sample-*.mkv", "sample-*.mp4",
            "To keep us going please read.txt",
            "*www.ETTV.tv*.txt", "WWW.VPPV.LA*.txt",
            "www.YTS.AM.*", "*www.ettv.to*.txt", "source.txt",
            "YTSProxies.com.txt", "NEW upcoming releases by Xclusive*",
            "YTSYifyUP*", "YIFYStatus*",
        ]
        return patterns.contains(where: { self.matchesPattern($0) })
    }
    
    func replacingExtension(with ext: String) -> FileURL {
        FileURL(url: asURL.deletingPathExtension().appendingPathExtension(ext))
    }
    
    var parent: FileURL? {
        guard asURL.deletingLastPathComponent() != asURL else {
            return nil
        }
        return FileURL(url: asURL.deletingLastPathComponent())
    }
}

extension FileURL {
    func openSubtitlesHash() throws(AppError) -> String {
        guard let handle = FileHandle(forReadingAtPath: asPath) else {
            throw .fileNotFound(self)
        }
        defer { handle.closeFile() }

        guard let fileSize = try? asURL.resourceValues(forKeys: Set([.fileSizeKey])).fileSize else {
            throw .fileNotFound(self)
        }

        let chunkSize: UInt64 = 65536
        guard fileSize >= chunkSize else {
            throw .fileNotHashable(self)
        }

        var hash = UInt64(fileSize)

        func addChunk(at offset: UInt64) {
            handle.seek(toFileOffset: offset)
            let data = handle.readData(ofLength: Int(chunkSize))
            data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
                let words = raw.bindMemory(to: UInt64.self)
                for word in words {
                    hash = hash &+ UInt64(littleEndian: word)
                }
            }
        }

        addChunk(at: 0)
        addChunk(at: UInt64(fileSize) - chunkSize)

        return String(hash, radix: 16).leftPadded(to: 16, with: "0")
    }
}

extension FileURL {
    func suggestURL(using hunch: HunchResult, moviesRoot: FileURL, seriesRoot: FileURL) throws(AppError) -> FileURL {
        switch hunch.type {
        case .episode:
            guard let title = hunch.title, let season = hunch.season, let episode = hunch.episode, episode.values.count > 0 else {
                throw .couldntGeneratePath(self, hunch)
            }
            var filename = "S" + String(format: "%02d", season) +
                episode.values.map { "E\(String(format: "%02d", $0))" }.joined(separator: "")

            if let episodeTitle = hunch.episodeTitle {
                filename += " " + episodeTitle
            }
            filename += "." + asURL.pathExtension

            var result = seriesRoot.asURL
            result.append(path: title, directoryHint: .isDirectory)
            result.append(path: "Season \(season)", directoryHint: .isDirectory)
            result.append(path: filename, directoryHint: .notDirectory)
            return .init(url: result)
            
        case .movie:
            guard let title = hunch.title, let year = hunch.year else {
                throw .couldntGeneratePath(self, hunch)
            }
            var filename = title + " (\(year))"
            filename += "." + asURL.pathExtension

            var result = moviesRoot.asURL
            result.append(path: filename, directoryHint: .notDirectory)
            return .init(url: result)

        default:
            throw .couldntGeneratePath(self, hunch)
        }
    }
}

extension FileURL {
    func adapted(folderCreation: FolderCreationPolicy) throws(AppError) -> FileURL {
        let folders = asURL.deletingLastPathComponent().pathComponents.dropFirst()

        var current = FileURL(path: "/")
        for (index, folder) in folders.enumerated() {
            let siblings = try FileManager.default.children(at: current, ignoringUnderscores: false)
            if let existing = siblings.first(where: { Self.fuzzyMatches($0.asURL.lastPathComponent, folder) }) {
                current = existing
                continue
            }

            let canCreate: Bool
            switch folderCreation {
            case .always:
                canCreate = true
                
            case .seasonOnly:
                let isLastFolder = index == folders.count - 1
                canCreate = (isLastFolder && folder.lowercased().hasPrefix("season"))
            }

            current = FileURL(url: current.asURL.appendingPathComponent(folder, isDirectory: true))

            guard canCreate else {
                throw .directoryMissing(current)
            }

            do { try FileManager.default.createDirectory(at: current.asURL, withIntermediateDirectories: false) }
            catch { throw .fileError(current, error) }
        }

        return FileURL(url: current.asURL.appendingPathComponent(asURL.lastPathComponent, isDirectory: false))
    }

    private static func fuzzyMatches(_ existing: String, _ candidate: String) -> Bool {
        if existing == candidate || existing.lowercased() == candidate.lowercased() { return true }
        let noQuotes: (String) -> String = { $0.replacingOccurrences(of: "'", with: "") }
        if noQuotes(existing) == noQuotes(candidate) { return true }
        let noDots: (String) -> String = { $0.replacingOccurrences(of: ".", with: "") }
        return noDots(existing) == noDots(candidate)
    }
}
