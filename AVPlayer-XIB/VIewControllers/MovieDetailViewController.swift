//
//  MovieDetailViewController.swift
//  AVPlayer-XIB
//
//  Created by 홍승표 on 11/7/25.
//

import UIKit
import AVKit
import YouTubeKit

class MovieDetailViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var overviewLabel: UITextView!
    @IBOutlet weak var trailerButton: UIButton!

    // MARK: - 속성
    private let networkManager = NetworkManager()
    
    // 포스터 이미지 로딩 작업을 취소, 관리하기 위한 태스크 참조
    private var posterLoadTask: URLSessionDataTask?

    // MARK: - UI 설정
    // 평점 라벨을 구성
    private func configureRatingLabel() {
//        ratingLabel.font = .systemFont(ofSize: 18, weight: .semibold)
//        ratingLabel.textColor = .systemOrange
        if let voteAverage = movie?.voteAverage {
            ratingLabel.text = "⭐️ \(String(format: "%.1f", voteAverage)) / 10"
        } else {
            ratingLabel.text = ""
        }
    }

    // 화면을 현재 movie 데이터에 맞게 갱신
    private func configureView() {
        configureRatingLabel() // 평점 라벨 갱신
        overviewLabel?.text = movie?.overview // 줄거리 텍스트 설정
        configurePosterAppearance() // 포스터 뷰 코너, 배경 등 설정
        loadPosterImage(from: movie?.fullPosterURL) // 포스터 이미지 비동기 로드
    }

    // 포스터 이미지뷰의 모습을 설정
    private func configurePosterAppearance() {
        posterImageView.contentMode = .scaleAspectFill // 이미지 비율 유지하면서 채우기
        posterImageView.clipsToBounds = true // 둥근 모서리 밖으로 나가는 부분 잘라내기
        posterImageView.backgroundColor = .systemGray // 로딩 전 기본 배경색
        posterImageView.layer.cornerRadius = 12 // 모서리를 둥글게
    }

    // 포스터 이미지 로드
    private func loadPosterImage(from url: URL?) {
        // 이전에 진행 중이던 이미지 로딩 작업이 있으면 취소
        posterLoadTask?.cancel()
        posterLoadTask = nil

        // 유효한 URL이 없는 경우
        guard let url = url else {
            showPosterPlaceholder() /// 기본 배경
            return
        }
        // 실제 이미지가 들어가면 배경을 투명하게
        posterImageView?.backgroundColor = .clear
        // 비동기 이미지 로딩 시작
        posterLoadTask = ImageLoader.shared.loadImage(from: url) { [weak self] result in
            /// 메인 메서드 전환
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self?.posterImageView?.image = image /// 받아온 이미지
                case .failure:
                    self?.showPosterPlaceholder() /// 기본 배경
                }
            }
        }
    }

    // 기본 배경 (표시할수 없을 때)
    private func showPosterPlaceholder() {
        posterImageView?.image = nil
        posterImageView?.backgroundColor = .systemGray
    }
    
    // 현재 화면에 표시할 영화 모델. 값이 바뀌면 UI를 갱신
    var movie: Movie? {
        didSet {
            if isViewLoaded {
                configureView()
            }
        }
    }
    
    // 예고편 버튼 탭 시
    @IBAction func trailerButton(_ sender: Any) {
        playTrailerFlow() // 예고편 재생
    }
    
    // 예고편 재생 제어
    @objc private func playTrailerFlow() {
        guard let movie else {
            showAlert(message: "영화 정보가 없습니다.")
            return
        }
        // 영화 ID로 예고편 정보를 NetworkManager에서 가져옴
        networkManager.fetchMovieTrailer(movieID: movie.id) { [weak self] result in
            self?.handleTrailerFetchResult(result)
        }
    }

    // 예고편 네트워크 요청 결과를 메인 스레드에서 처리 & 메모리 안정성 확보
    private func handleTrailerFetchResult(_ result: Result<Trailer, NetworkManager.NetworkError>) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch result {
            case .success(let trailer):
                self.openTrailer(trailer)
            case .failure(let error):
                self.showAlert(message: "예고편 로드 실패: \(error.localizedDescription)")
            }
        }
    }

    // 트레일러 정보에서 YouTube URL을 가져와 실제 스트림 URL을 해석
    private func openTrailer(_ trailer: Trailer) {
        guard let youtubeURL = trailer.youtubeURL else {
            showAlert(message: "유효한 YouTube 예고편을 찾을 수 없습니다.")
            return
        }
        // YouTubeKit을 사용해 재생 가능한 스트림 URL을 비동기로 해석
        resolveYouTubeStreamURL(from: youtubeURL) { [weak self] result in
            switch result {
            case .success(let streamURL):
                self?.presentPlayer(with: streamURL) // AVPlayer로 재생 화면 표시
            case .failure(let error):
                DispatchQueue.main.async { [weak self] in
                    self?.showAlert(message: "예고편 재생 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    // AVPlayerViewController를 전체 화면으로 표시하고 재생
    private func presentPlayer(with url: URL) {
        DispatchQueue.main.async { [weak self] in
            // AVPlayer 인스턴스 생성
            let player = AVPlayer(url: url)
            // 플레이어 컨트롤러 생성
            let playerVC = AVPlayerViewController()
            playerVC.player = player
            playerVC.modalPresentationStyle = .fullScreen
            self?.present(playerVC, animated: true) {
                player.play() // 모달로 표시한 뒤 자동 재생
            }
        }
    }

    // YouTube URL에서 재생 가능한 스트림 URL을 비동기로 해석
    private func resolveYouTubeStreamURL(from youtubeURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        Task {
            do {
                /// YouTubeKit으로 비디오 객체 생성
                let video = YouTube(url: youtubeURL)
                /// 사용 가능한 스트림 목록을 가져오기
                let streams = try await video.streams
                /// iOS에서 네이티브로 재생 가능한 최고 해상도 스트림
                if let stream = streams.filterVideoAndAudio().filter({ $0.isNativelyPlayable }).highestResolutionStream() {
                    completion(.success(stream.url))
                    return
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    // 간단한 알림 창을 표시
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // 뷰 로드 시 초기 UI 설정 및 데이터 바인딩을 수행
    override func viewDidLoad() {
        super.viewDidLoad()
        overviewLabel.isEditable = false // 사용자가 편집하지 못하도록 X
        overviewLabel.isSelectable = true // 텍스트 선택 O
        overviewLabel.textColor = .label // 시스템 라벨 색상 사용
        overviewLabel.text = movie?.overview // 초기 줄거리 텍스트 바인딩
        configureRatingLabel() // 초기 평점 라벨
        
        configurePosterAppearance() // 포스터 모습 설정
        loadPosterImage(from: movie?.fullPosterURL) // 포스터 이미지 로드
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    

}

