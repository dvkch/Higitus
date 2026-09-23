//
//  FFmpeg.swift
//  Higitus
//
//  Created by syan on 23/09/2026.
//

import Foundation

struct FFmpeg {
    static func embeddedSubtitleLocales(for media: FileURL) throws(AppError) -> Set<Lang> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "ffprobe",
            "-v", "error",
            "-print_format", "json",
            "-show_entries", "stream_tags=language",
            "-select_streams", "s",
            media.asURL.path
        ]

        let stdout = Pipe()
        process.standardOutput = stdout
        process.standardError = Pipe()

        do {
            try process.run()
        }
        catch {
            throw .ffprobeFailed("Couldn't launch ffprobe: \(error.localizedDescription)")
        }
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw .ffprobeFailed("ffprobe exited with status \(process.terminationStatus)")
        }

        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        let output: FFprobeOutput
        do {
            output = try JSONDecoder().decode(FFprobeOutput.self, from: data)
        }
        catch {
            Log.d("FFProbe", "\(error)")
            throw .ffprobeFailed("Malformed ffprobe output: \(error.localizedDescription)")
        }

        let rawTags = output.streams.compactMap(\.tags?.language)
        return Set(rawTags.compactMap { Lang(rawValue: $0) })
    }
}

private struct FFprobeOutput: Decodable {
    let streams: [FFprobeStream]
}

private struct FFprobeStream: Decodable {
    let tags: FFprobeTags?
}

private struct FFprobeTags: Decodable {
    let language: String?
}
