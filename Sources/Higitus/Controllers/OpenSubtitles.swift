//
//  OpenSubtitles.swift
//  Higitus
//
//  Created by syan on 17/09/2026.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


final class OpenSubtitlesClient {

    init(apiKey: String, username: String, password: String) {
        self.apiKey = apiKey
        self.username = username
        self.password = password
    }

    private let baseURL = URL(string: "https://api.opensubtitles.com/api/v1/")!
    private let apiKey: String
    private let username: String
    private let password: String
    private var token: String?

    // MARK: API Calls
    func login() throws(AppError) {
        let response: OpenSubtitlesLoginResponse = try requestCodable(
            "login", method: "POST", body: ["username": username, "password": password]
        )
        self.token = response.token
    }

    func search(hunch: HunchResult, hash: String?, language: String) throws(AppError) -> OpenSubtitlesFile? {
        if let hash, let file = try searchByHash(hash, language: language) {
            return file
        }
        return try searchByMetadata(hunch, language: language)
    }

    private func searchByHash(_ hash: String, language: String) throws(AppError) -> OpenSubtitlesFile? {
        let response: OpenSubtitlesSearchResponse = try requestCodable(
            "subtitles", query: ["languages": language, "moviehash": hash]
        )
        return response.data.first?.attributes.files.first
    }

    private func searchByMetadata(_ hunch: HunchResult, language: String) throws(AppError) -> OpenSubtitlesFile? {
        var query: [String: String] = ["languages": language]
        switch hunch.type {
        case .movie:
            query["type"] = "movie"
            query["query"] = hunch.title
            query["year"] = hunch.year.map(String.init)
        case .episode:
            query["type"] = "episode"
            query["query"] = hunch.title
            query["season_number"] = hunch.season.map(String.init)
            query["episode_number"] = hunch.episode?.values.first.map(String.init)
        default:
            break
        }
        let response: OpenSubtitlesSearchResponse = try requestCodable("subtitles", query: query)
        return response.data.first?.attributes.files.first
    }

    func download(_ file: OpenSubtitlesFile, to destination: FileURL) throws(AppError) {
        let download: OpenSubtitlesDownloadResponse = try requestCodable(
            "download", method: "POST", body: ["file_id": file.fileId], authenticated: true
        )
        guard let link = URL(string: download.link) else {
            throw .openSubtitlesRequestFailed("Malformed download link: \(download.link)")
        }
        guard let subtitleData = try? Data(contentsOf: link) else {
            throw .openSubtitlesRequestFailed("Couldn't download subtitle file")
        }
        do { try subtitleData.write(to: destination.asURL) }
        catch { throw .openSubtitlesRequestFailed("Couldn't save subtitle file") }
    }

    // MARK: Generic
    private func request(
        _ path: String,
        method: String = "GET",
        query: [String: String] = [:],
        body: [String: Any]? = nil,
        authenticated: Bool = false
    ) throws(AppError) -> Data {
        // Build request
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if query.isNotEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.setValue("Higitus v1.0", forHTTPHeaderField: "User-Agent") 
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authenticated, let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            }
            catch {
                throw .notSerializable(body)
            }
        }

        // Run request synchronously
        nonisolated(unsafe) var resultData: Data?
        nonisolated(unsafe) var resultError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, _, error in
            resultData = data
            resultError = error
            semaphore.signal()
        }.resume()
        semaphore.wait()

        // Check result
        if let resultError {
            throw .openSubtitlesRequestFailed(resultError.localizedDescription)
        }
        guard let resultData else {
            throw .openSubtitlesRequestFailed(path)
        }
        return resultData
    }
    
    private func requestCodable<T: Decodable>(
        _ path: String,
        method: String = "GET",
        query: [String: String] = [:],
        body: [String: Any]? = nil,
        authenticated: Bool = false
    ) throws(AppError) -> T {
        let data = try request(path, method: method, query: query, body: body, authenticated: authenticated)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(T.self, from: data)
        }
        catch {
            if let jsonError = try? decoder.decode(OpenSubtitlesErrorResponse.self, from: data) {
                throw .openSubtitlesRequestFailed(jsonError.message)
            }
            else {
                Log.d("OpenSubtitles", String(data: data, encoding: .utf8)!)
                Log.d("OpenSubtitles", "\(error)")
                throw .openSubtitlesRequestFailed("Malformed JSON response: \(error.localizedDescription)")
            }
        }
    }
}
