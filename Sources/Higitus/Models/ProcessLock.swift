//
//  ProcessLock.swift
//  Higitus
//
//  Created by syan on 03/09/2026.
//

import Foundation
#if canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Darwin)
import Darwin
#endif

struct ProcessLock {
    init(url: FileURL) {
        self.url = url
    }

    private let url: FileURL

    func acquire() -> Bool {
        if url.exists {
            guard isStale else {
                Log.i("Lock", "Command is already running, skipping this run")
                return false
            }
            Log.w("Lock", "Stale lock file found, deleting")
            try? FileManager.default.removeItem(atPath: url.asPath)
        }

        url.touch(contents: String(ProcessInfo.processInfo.processIdentifier))
        return true
    }

    func release() {
        try? FileManager.default.removeItem(atPath: url.asPath)
    }

    private var isStale: Bool {
        guard let contents = try? String(contentsOf: url.asURL, encoding: .utf8),
              let pid = pid_t(contents.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return true
        }
        // Signal 0 doesn't actually signal anything — standard liveness check.
        guard kill(pid, 0) == 0 else { return true }

        // Alive isn't proof it's still *our* process — the PID could have
        // been reused by something else. Confirm it's actually Higitus.
        guard let runningExecutable = Self.executablePath(forPID: pid) else {
            return false // couldn't verify — assume it's still ours to be safe
        }
        return FileURL(path: runningExecutable).asPath != FileURL.higitusURL.asPath
    }

    private static func executablePath(forPID pid: pid_t) -> String? {
        #if os(Linux)
        return URL(fileURLWithPath: "/proc/\(pid)/exe").resolvingSymlinksInPath().path
        #elseif os(macOS)
        let maxPathSize = 4 * 1024 // PROC_PIDPATHINFO_MAXSIZE = 4 * MAXPATHLEN, see proc_info.h
        var buffer = [CChar](repeating: 0, count: maxPathSize)
        let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return nil }
        return String(cString: buffer)
        #else
        return nil
        #endif
    }}
