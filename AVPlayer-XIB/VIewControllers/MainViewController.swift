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

    private enum Layout {
        static let itemsPerRow: CGFloat = 2
        static let spacing: CGFloat = 12
        static let inset: CGFloat = 12
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
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
}

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 10 }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewXibCell", for: indexPath) as! CollectionViewXibCell
        cell.contentView.backgroundColor = indexPath.item % 2 == 0 ? .systemBlue : .systemGreen
        return cell
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

        if let nav = navigationController {
            nav.pushViewController(detailVC, animated: true)
        } else {
            present(detailVC, animated: true)
        }
    }
}
