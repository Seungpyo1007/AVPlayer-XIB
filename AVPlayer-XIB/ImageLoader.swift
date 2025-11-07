//
//  ImageLoader.swift
//  AVPlayer-XIB
//
//  Created by 홍승표 on 11/7/25.
//

import UIKit

/// 이미지 다운로드 및 캐싱을 담당하는 싱글톤 클래스
class ImageLoader {
    
    // MARK: - 싱글톤
    
    static let shared = ImageLoader()
    
    // MARK: - 프로퍼티
    
    /// 다운로드한 이미지를 메모리에 캐싱
    private let imageCache = NSCache<NSString, UIImage>()
    
    /// 진행 중인 다운로드 작업 추적 (중복 요청 방지)
    private var runningRequests: [String: URLSessionDataTask] = [:]
    
    // MARK: - 초기화
    
    private init() {}
    
    // MARK: - 공개 메서드
    
    /// URL에서 이미지를 로드 (캐시 우선, 없으면 다운로드)
    /// - Parameters:
    ///   - url: 이미지 URL
    ///   - completion: 완료 핸들러 (Result<UIImage, Error>)
    /// - Returns: URLSessionDataTask (취소 가능)
    @discardableResult
    func loadImage(from url: URL,
                   completion: @escaping (Result<UIImage, Error>) -> Void) -> URLSessionDataTask? {
        
        let urlString = url.absoluteString
        
        // 1. 캐시에서 이미지 확인
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            completion(.success(cachedImage))
            return nil
        }
        
        // 2. 이미 다운로드 중인지 확인 (중복 요청 방지)
        if let existingTask = runningRequests[urlString] {
            return existingTask
        }
        
        // 3. 새로운 다운로드 요청 생성
        let task = createDownloadTask(for: url, urlString: urlString, completion: completion)
        task.resume()
        
        runningRequests[urlString] = task
        return task
    }
    
    /// 특정 URL의 이미지 다운로드 취소
    /// - Parameter url: 취소할 이미지 URL
    func cancelLoading(for url: URL) {
        let urlString = url.absoluteString
        
        if let task = runningRequests[urlString] {
            task.cancel()
            runningRequests.removeValue(forKey: urlString)
        }
    }
    
    // MARK: - 비공개 메서드
    
    /// 이미지 다운로드 작업 생성
    private func createDownloadTask(for url: URL,
                                    urlString: String,
                                    completion: @escaping (Result<UIImage, Error>) -> Void) -> URLSessionDataTask {
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            
            // 작업 완료 시 목록에서 제거
            defer { self?.runningRequests.removeValue(forKey: urlString) }
            
            // 에러 처리
            if let error = error {
                // 사용자가 취소한 경우는 completion 호출 안 함
                if (error as NSError).code != NSURLErrorCancelled {
                    completion(.failure(error))
                }
                return
            }
            
            // 이미지 데이터 검증 및 변환
            guard let data = data,
                  let image = UIImage(data: data) else {
                let error = NSError(
                    domain: "ImageLoaderError",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "유효하지 않은 이미지 데이터"]
                )
                completion(.failure(error))
                return
            }
            
            // 캐시에 저장 및 완료 처리
            self?.imageCache.setObject(image, forKey: urlString as NSString)
            completion(.success(image))
        }
        
        return task
    }
}
