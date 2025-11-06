//
//  NetworkManager.swift
//  AVPlayer-XIB
//
//  Created by 홍승표 on 11/6/25.
//

import Foundation

/// TMDB API 통신을 담당하는 네트워크 매니저
class NetworkManager {
    
    // MARK: - 상수
    
    private enum API {
        static let baseURL = "https://api.themoviedb.org/3"
        static let bearerToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2NDk0ZTI3ZmVhOGFjOTJhM2IyZDQ2YjlkZjI4OTc2MiIsIm5iZiI6MTc2MTcwMDE3Mi45ODUsInN1YiI6IjY5MDE2OTRjNTJiOWMwMDdmYmM0NjA0YiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EEEH1P8JcEUazWnkc4jHSz9PmtFmuLj-RZ4sq-BCAKY"
        static let language = "ko-KR"
        static let timeout: TimeInterval = 10
    }
     
    // MARK: - 네트워크 에러
    
    enum NetworkError: Error {
        case invalidURL
        case noData
        case decodingFailed(Error)
        case apiError(String)
        case httpError(Int)
        
        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "유효하지 않은 URL입니다."
            case .noData:
                return "데이터를 수신하지 못했습니다."
            case .decodingFailed(let error):
                return "데이터 디코딩 실패: \(error.localizedDescription)"
            case .apiError(let message):
                return "API 오류: \(message)"
            case .httpError(let code):
                return code == 401 ? "인증 오류 (401). Bearer Token을 확인하세요." : "HTTP 오류 코드: \(code)"
            }
        }
    }
    
    // MARK: - 공개 메서드
    
    /// 인기 영화 목록 가져오기
    /// - Parameters:
    ///   - page: 페이지 번호
    ///   - completion: 결과 핸들러
    func fetchPopularMovies(page: Int,
                           completion: @escaping (Result<MovieResponse, NetworkError>) -> Void) {
        let urlString = "\(API.baseURL)/movie/popular?page=\(page)&language=\(API.language)"
        
        guard let request = createRequest(for: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        performRequest(request, completion: completion)
    }

    /// 영화 검색
    /// - Parameters:
    ///   - query: 검색어
    ///   - page: 페이지 번호
    ///   - completion: 결과 핸들러
    func searchMovies(query: String,
                     page: Int,
                     completion: @escaping (Result<MovieResponse, NetworkError>) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(.failure(.invalidURL))
            return
        }
        
        let urlString = "\(API.baseURL)/search/movie?query=\(encodedQuery)&page=\(page)&language=\(API.language)"
        
        guard let request = createRequest(for: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        performRequest(request, completion: completion)
    }
    
    /// 영화 예고편 가져오기
    /// - Parameters:
    ///   - movieID: 영화 ID
    ///   - completion: 결과 핸들러
    func fetchMovieTrailer(movieID: Int,
                          completion: @escaping (Result<Trailer, NetworkError>) -> Void) {
        let urlString = "\(API.baseURL)/movie/\(movieID)/videos?language=\(API.language)"
        
        guard let request = createRequest(for: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        performTrailerRequest(request, completion: completion)
    }
    
    // MARK: - 비공개 메서드
    
    /// URLRequest 생성 (Bearer Token 포함)
    private func createRequest(for urlString: String) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = API.timeout
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "Authorization": "Bearer \(API.bearerToken)"
        ]
        
        return request
    }
    
    /// 영화 목록 API 요청 실행
    private func performRequest(_ request: URLRequest,
                               completion: @escaping (Result<MovieResponse, NetworkError>) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // 에러 처리
            if let error = error {
                if (error as NSError).code != NSURLErrorCancelled {
                    completion(.failure(.apiError(error.localizedDescription)))
                }
                return
            }
            
            // 응답 검증
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.noData))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.httpError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            // 데이터 디코딩
            do {
                let movieResponse = try JSONDecoder().decode(MovieResponse.self, from: data)
                completion(.success(movieResponse))
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
        }
        
        task.resume()
    }
    
    /// 예고편 API 요청 실행
    private func performTrailerRequest(_ request: URLRequest,
                                      completion: @escaping (Result<Trailer, NetworkError>) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // 에러 처리
            if let error = error {
                if (error as NSError).code != NSURLErrorCancelled {
                    completion(.failure(.apiError(error.localizedDescription)))
                }
                return
            }
            
            // 응답 검증
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion(.failure(.httpError(statusCode)))
                return
            }
            
            // 데이터 디코딩 및 YouTube Trailer 찾기
            do {
                let trailerResponse = try JSONDecoder().decode(TrailerResponse.self, from: data)
                
                if let trailer = self.findYouTubeTrailer(from: trailerResponse.results) {
                    completion(.success(trailer))
                } else {
                    completion(.failure(.noData))
                }
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
        }
        
        task.resume()
    }
    
    /// YouTube Trailer 또는 Teaser 찾기
    private func findYouTubeTrailer(from trailers: [Trailer]) -> Trailer? {
        return trailers.first { trailer in
            trailer.site == "YouTube" && (trailer.type == "Trailer" || trailer.type == "Teaser")
        }
    }
}
