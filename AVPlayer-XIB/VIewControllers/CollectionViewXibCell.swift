//
//  CollectionViewXibCell.swift
//  AVPlayer-XIB
//
//  Created by 홍승표 on 11/6/25.
//

import UIKit

class CollectionViewXibCell: UICollectionViewCell {
    @IBOutlet weak var posterImageView: UIImageView!
    
    private var currentTask: URLSessionDataTask?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.backgroundColor = .systemGray5
        posterImageView.layer.cornerRadius = 12
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentTask?.cancel()
        currentTask = nil
        posterImageView.image = nil
        posterImageView.backgroundColor = .systemGray4
    }

    func configure(with movie: Movie) {
        loadPosterImage(from: movie.fullPosterURL)
    }

    private func loadPosterImage(from url: URL?) {
        guard let url = url else {
            showPlaceholder()
            return
        }
        posterImageView.backgroundColor = .clear
        currentTask = ImageLoader.shared.loadImage(from: url) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleImageLoadResult(result)
            }
        }
    }

    private func handleImageLoadResult(_ result: Result<UIImage, Error>) {
        switch result {
        case .success(let image):
            posterImageView.image = image
        case .failure:
            showPlaceholder()
        }
    }

    private func showPlaceholder() {
        posterImageView.image = nil
        posterImageView.backgroundColor = .systemGray4
    }
}
