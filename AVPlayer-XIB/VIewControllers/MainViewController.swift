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

    private let itemsPerRow: CGFloat = 2
    private let spacing: CGFloat = 12
    private let inset: CGFloat = 12

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        configureLayout()
    }

    private func setupCollectionView() {
        let nib = UINib(nibName: "CollectionViewXibCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "CollectionViewXibCell")
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    private func configureLayout() {
        let layout = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout) ?? UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
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
        let totalSpacing = (itemsPerRow - 1) * spacing + (inset * 2)
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / itemsPerRow)
        return CGSize(width: itemWidth, height: itemWidth * 1.5)
    }
}
