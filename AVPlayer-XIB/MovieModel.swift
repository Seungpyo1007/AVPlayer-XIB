//
//  MovieModel.swift
//  AVPlayer-XIB
//
//  Created by 홍승표 on 11/6/25.
//

import Foundation

// MARK: - 영화 응답

/// TMDB API 영화 목록 응답 구조 (페이징 정보 포함)
struct MovieResponse: Codable {
    let results: [Movie]
    let page: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case results, page
        case totalPages = "total_pages"
    }
}

// MARK: - 영화

/// 개별 영화 정보
struct Movie: Codable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let voteAverage: Double
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case posterPath = "poster_path"
        case voteAverage = "vote_average"
    }
    
    /// 포스터 이미지의 전체 URL 생성
    /// - Returns: TMDB 이미지 서버의 포스터 URL (w500 크기)
    var fullPosterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
}

// MARK: - 예고편 응답

/// TMDB API 예고편 목록 응답 구조
struct TrailerResponse: Codable {
    let id: Int
    let results: [Trailer]
}

// MARK: - 예고편

/// 영화 예고편 정보
struct Trailer: Codable {
    let key: String      // YouTube 영상 ID
    let site: String     // 동영상 플랫폼 (YouTube, Vimeo 등)
    let type: String     // 영상 타입 (Trailer, Teaser 등)
    
    /// YouTube 영상 URL 생성 (Trailer 또는 Teaser만 해당)
    /// - Returns: YouTube 시청 URL
    var youtubeURL: URL? {
        guard site == "YouTube" else { return nil }
        guard type == "Trailer" || type == "Teaser" else { return nil }
        
        return URL(string: "https://www.youtube.com/watch?v=\(key)")
    }
}
