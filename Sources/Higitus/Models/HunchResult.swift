//
//  HunchResult.swift
//  Higitus
//
//  Created by syan on 17/09/2026.
//

import Foundation

struct HunchResult: Codable {

    // MARK: Structural
    let mimetype: String?
    let type: MediaType?
    let title: String?
    let season: Int?
    let episode: SingleOrArray<Int>?
    let year: Int?
    let date: String?
    let container: String?

    // MARK: Video
    let videoCodec: String?
    let screenSize: String?
    let frameRate: String?
    let colorDepth: String?
    let videoProfile: String?
    let videoApi: String?
    let aspectRatio: String?

    // MARK: Audio
    let audioCodec: String?
    let audioChannels: String?
    let audioProfile: String?
    let audioBitRate: String?
    let videoBitRate: String?

    // MARK: Source & Edition
    let source: String?
    let streamingService: String?
    let edition: String?
    let other: SingleOrArray<String>?

    // MARK: Release metadata
    let releaseGroup: String?
    let website: String?
    let crc32: String?
    let uuid: String?
    let size: String?
    let properCount: Int?
    let version: FlexibleString?

    // MARK: Episode details
    let episodeTitle: String?
    let filmTitle: String?
    let alternativeTitle: String?
    let bonus: Int?
    let bonusTitle: String?
    let episodeDetails: String?
    let episodeFormat: String?
    let episodeCount: FlexibleString?
    let seasonCount: FlexibleString?
    let absoluteEpisode: FlexibleString?
    let week: FlexibleString?
    let film: Int?
    let disc: Int?
    let cd: FlexibleString?
    let cdCount: FlexibleString?
    let part: Int?

    // MARK: Language
    let language: String?
    let subtitleLanguage: String?
    let country: String?

    enum MediaType: String, Codable {
        case movie
        case episode
        case extra
    }

    enum CodingKeys: String, CodingKey {
        // Structural
        case mimetype = "mimetype"
        case title = "title"
        case season = "season"
        case episode = "episode"
        case year = "year"
        case date = "date"
        case container = "container"
        case type = "type"

        // Video
        case videoCodec = "video_codec"
        case screenSize = "screen_size"
        case frameRate = "frame_rate"
        case colorDepth = "color_depth"
        case videoProfile = "video_profile"
        case videoApi = "video_api"
        case aspectRatio = "aspect_ratio"

        // Audio
        case audioCodec = "audio_codec"
        case audioChannels = "audio_channels"
        case audioProfile = "audio_profile"
        case audioBitRate = "audio_bit_rate"
        case videoBitRate = "video_bit_rate"

        // Source & Edition
        case source = "source"
        case streamingService = "streaming_service"
        case edition = "edition"
        case other = "other"

        // Release metadata
        case releaseGroup = "release_group"
        case website = "website"
        case crc32 = "crc32"
        case uuid = "uuid"
        case size = "size"
        case properCount = "proper_count"
        case version = "version"

        // Episode details
        case episodeTitle = "episode_title"
        case filmTitle = "film_title"
        case alternativeTitle = "alternative_title"
        case bonus = "bonus"
        case bonusTitle = "bonus_title"
        case episodeDetails = "episode_details"
        case episodeFormat = "episode_format"
        case episodeCount = "episode_count"
        case seasonCount = "season_count"
        case absoluteEpisode = "absolute_episode"
        case week = "week"
        case film = "film"
        case disc = "disc"
        case cd = "cd"
        case cdCount = "cd_count"
        case part = "part"

        // Language
        case language = "language"
        case subtitleLanguage = "subtitle_language"
        case country = "country"
    }
}

