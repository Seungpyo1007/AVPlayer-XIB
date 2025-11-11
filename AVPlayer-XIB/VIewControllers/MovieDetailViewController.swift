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
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var overviewLabel: UITextView!
    @IBOutlet weak var trailerButton: UIButton!

    // MARK: - Dependencies
    private let networkManager = NetworkManager()
    
    private var posterLoadTask: URLSessionDataTask?

    // MARK: - Rating Label
    private func configureRatingLabel() {
        guard let ratingLabel = ratingLabel else { return }
//        ratingLabel.font = .systemFont(ofSize: 18, weight: .semibold)
//        ratingLabel.textColor = .systemOrange
        if let voteAverage = movie?.voteAverage {
            ratingLabel.text = "⭐️ \(String(format: "%.1f", voteAverage)) / 10"
        } else {
            ratingLabel.text = ""
        }
    }

    private func configureView() {
        configureRatingLabel()
        overviewLabel?.text = movie?.overview
        configurePosterAppearance()
        loadPosterImage(from: movie?.fullPosterURL)
    }

    private func configurePosterAppearance() {
        guard let posterImageView = posterImageView else { return }
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.backgroundColor = .systemGray5
        posterImageView.layer.cornerRadius = 12
    }

    private func loadPosterImage(from url: URL?) {
        posterLoadTask?.cancel()
        posterLoadTask = nil

        guard let url = url else {
            showPosterPlaceholder()
            return
        }
        posterImageView?.backgroundColor = .clear
        posterLoadTask = ImageLoader.shared.loadImage(from: url) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self?.posterImageView?.image = image
                case .failure:
                    self?.showPosterPlaceholder()
                }
            }
        }
    }

    private func showPosterPlaceholder() {
        posterImageView?.image = nil
        posterImageView?.backgroundColor = .systemGray4
    }
    
    var movie: Movie? {
        didSet {
            if isViewLoaded {
                configureView()
            }
        }
    }
    
    @IBAction func trailerButton(_ sender: Any) {
        playTrailerFlow()
    }
    
    @objc private func playTrailerFlow() {
        guard let movie else {
            showAlert(message: "영화 정보가 없습니다.")
            return
        }
        networkManager.fetchMovieTrailer(movieID: movie.id) { [weak self] result in
            self?.handleTrailerFetchResult(result)
        }
    }

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

    private func openTrailer(_ trailer: Trailer) {
        guard let youtubeURL = trailer.youtubeURL else {
            showAlert(message: "유효한 YouTube 예고편을 찾을 수 없습니다.")
            return
        }
        resolveYouTubeStreamURL(from: youtubeURL) { [weak self] result in
            switch result {
            case .success(let streamURL):
                self?.presentPlayer(with: streamURL)
            case .failure(let error):
                DispatchQueue.main.async { [weak self] in
                    self?.showAlert(message: "예고편 재생 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    private func presentPlayer(with url: URL) {
        DispatchQueue.main.async { [weak self] in
            let player = AVPlayer(url: url)
            let playerVC = AVPlayerViewController()
            playerVC.player = player
            playerVC.modalPresentationStyle = .fullScreen
            self?.present(playerVC, animated: true) {
                player.play()
            }
        }
    }

    private struct NoPlayableStreamError: LocalizedError {
        var errorDescription: String? { "재생 가능한 스트림을 찾을 수 없습니다." }
    }

    private func resolveYouTubeStreamURL(from youtubeURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        Task {
            do {
                let video = YouTube(url: youtubeURL)
                let streams = try await video.streams
                if let best = streams.filterVideoAndAudio().filter({ $0.isNativelyPlayable }).highestResolutionStream() {
                    completion(.success(best.url))
                    return
                }
                if let fallback = streams.filterVideoAndAudio().highestResolutionStream() {
                    completion(.success(fallback.url))
                    return
                }
                if let audioOnly = streams.filterAudioOnly().highestAudioBitrateStream() {
                    completion(.success(audioOnly.url))
                    return
                }
                completion(.failure(NoPlayableStreamError()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overviewLabel.isEditable = false
        overviewLabel.isSelectable = true
        overviewLabel.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        overviewLabel.font = .systemFont(ofSize: 15)
        overviewLabel.textColor = .label
        overviewLabel.text = movie?.overview
        configureRatingLabel()
        
        configurePosterAppearance()
        loadPosterImage(from: movie?.fullPosterURL)
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
