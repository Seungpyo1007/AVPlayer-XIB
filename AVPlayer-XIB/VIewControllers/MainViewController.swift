//
//  MainViewController.swift
//  AVPlayer-XIB
//
//  Created by 홍승표 on 11/5/25.
//

import UIKit

final class MainViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!

    private var movies: [Movie] = []
    private let networkManager = NetworkManager()

    private enum Layout {
        static let itemsPerRow: CGFloat = 2
        static let spacing: CGFloat = 12
        static let inset: CGFloat = 12
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        searchBar.delegate = self
        loadPopularMovies()
    }

    private func configureCollectionView() {
        let nib = UINib(nibName: "CollectionViewXibCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "CollectionViewXibCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = Layout.spacing
        layout.minimumLineSpacing = Layout.spacing
        layout.sectionInset = UIEdgeInsets(top: Layout.inset, left: Layout.inset, bottom: Layout.inset, right: Layout.inset)
        collectionView.setCollectionViewLayout(layout, animated: false)
    }

    private func loadPopularMovies(page: Int = 1) {
        networkManager.fetchPopularMovies(page: page) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.movies = response.results
                    self?.collectionView.reloadData()
                case .failure(let error):
                    self?.showAlert(message: error.localizedDescription)
                }
            }
        }
    }

    private func searchMovies(query: String, page: Int = 1) {
        networkManager.searchMovies(query: query, page: page) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.movies = response.results
                    self?.collectionView.reloadData()
                case .failure(let error):
                    self?.showAlert(message: error.localizedDescription)
                }
            }
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let xibCell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewXibCell", for: indexPath) as! CollectionViewXibCell
        let movie = movies[indexPath.item]
        xibCell.configure(with: movie)
        return xibCell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing = (Layout.itemsPerRow - 1) * Layout.spacing + (Layout.inset * 2)
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / Layout.itemsPerRow)
        return CGSize(width: itemWidth, height: itemWidth * 1.5)
    }

    // 클릭
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let detailVC = MovieDetailViewController(nibName: "MovieDetailViewController", bundle: nil)

        if indexPath.item < movies.count {
            detailVC.movie = movies[indexPath.item]
        }

        if let nav = navigationController {
            nav.pushViewController(detailVC, animated: true)
        } else {
            present(detailVC, animated: true)
        }
    }
}

extension MainViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        let text = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if text.isEmpty {
            loadPopularMovies()
        } else {
            searchMovies(query: text)
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        loadPopularMovies()
    }
}
