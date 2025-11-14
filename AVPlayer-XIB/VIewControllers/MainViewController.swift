//
//  MainViewController.swift
//  AVPlayer-XIB
//
//  Created by 홍승표 on 11/5/25.
//

import UIKit

final class MainViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - 상태 및 의존성
    private var movies: [Movie] = [] // 영화 데이터 배열
    private var currentPage = 1 // 현재 페이지
    private var totalPages = 1 // 전체 페이지 수 (서버 응답 기반)
    private var isLoading = false // 네트워크 중복 요청 방지
    private var query: String? = nil // 검색어 (nil이면 인기 영화 목록 요청)
    private let networkManager = NetworkManager()

    // MARK: - Layout Constants (레이아웃 상수)
    private enum Layout {
        // 한 줄에 표시할 아이템 개수
        static let itemsPerRow: CGFloat = 2
        // 아이템 간격 및 줄 간격
        static let spacing: CGFloat = 12
        // 컬렉션 뷰 안쪽 간격
        static let inset: CGFloat = 12
    }

    // 화면 초기 구성
    override func viewDidLoad() {
        super.viewDidLoad()
        // 컬렉션 뷰 레이아웃, 데이터소스, 셀 설정
        configureCollectionView()
        // 검색 이벤트를 받기 위해 지정
        searchBar.delegate = self
        // 초기화
        reloadFromStart()
    }

    // 컬렉션 뷰 설정: 셀 등록, 델리게이트 연결, 레이아웃 구성.
    private func configureCollectionView() {
        let nib = UINib(nibName: "CollectionViewXibCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "CollectionViewXibCell") /// 셀 등록
        collectionView.delegate = self
        collectionView.dataSource = self

        // 구성을 위한 플로우 레이아웃
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical /// 세로 스크롤
        layout.minimumInteritemSpacing = Layout.spacing /// 아이템 간 최소 가로 간격
        layout.minimumLineSpacing = Layout.spacing ///  아이템 간 최소 세로 간격
        layout.sectionInset = UIEdgeInsets(top: Layout.inset, left: Layout.inset, bottom: Layout.inset, right: Layout.inset) /// 섹션 여백
        collectionView.collectionViewLayout = layout /// 레이아웃 적용
    }

    // 지정한 페이지의 영화를 로드합니다.
    private func load(page: Int, replace: Bool) {
        /// 중복 네트워크 요청 방지 (현재 로딩 중이면 중단)
        guard !isLoading else { return }
        isLoading = true /// 구문 통과 후 로딩 중 설정

        // NetworkManager 처리 함수
        let completion: (Result<MovieResponse, NetworkManager.NetworkError>) -> Void = { [weak self] result in
            /// 메인스레드 전환 & 메모리 안정성 확보 및 로딩 상태 해제
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let response):
                    /// 페이지네이션 상태 업데이트 (여러 페이지)
                    self.currentPage = page /// 요청한 페이지 번호 = page
                    self.totalPages = response.totalPages
                    if replace {
                        self.movies = response.results
                        /// replace가 true인 경우 데이터 교체
                    } else {
                        self.movies += response.results
                        /// replace가 false인 경우 데이터 이어붙이기
                    }
                    self.collectionView.reloadData() // 호출
                case .failure(let error):
                    self.showAlert(message: String(describing: error))
                }
            }
        }
        // 검색어가 있으면 검색 API, 없으면 인기 영화 API 호출
        if let q = query {
            networkManager.searchMovies(query: q, page: page, completion: completion)
        } else {
            networkManager.fetchPopularMovies(page: page, completion: completion)
        }
    }

    // 페이지네이션 (여러 페이지)을 초기화하고 첫 페이지부터 로드합니다.
    private func reloadFromStart() {
        currentPage = 1
        totalPages = 1
        // 첫 페이지 데이터로 현재 목록 교체
        load(page: 1, replace: true)
    }

    // 네트워크 오류가 발생했을때 간단한 알림을 표시합니다.
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // 개수 지정
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count // 영화 아이템 개수
    }
    
    // 객체 Cell 구성
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewXibCell", for: indexPath) as? CollectionViewXibCell else {
            return UICollectionViewCell() // CollectionViewXibCell 가져오기, 가져오지 못하면 반환
        }
        let movie = movies[indexPath.item]
        cell.configure(with: movie) // 셀 데이터 바인딩 (연결)
        return cell // 반환
    }

    // 레이아웃 itemsPerRow(한줄에 들어갈 아이템 개수)가 들어가도록 크기 계산
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing = (Layout.itemsPerRow - 1) * Layout.spacing + (Layout.inset * 2)
        /// 한 줄의 모든 간격(아이템 간 간격 + 섹션 인셋)의 총합을 계산
        let availableWidth = collectionView.bounds.width - totalSpacing
        /// 전체 컬렉션 뷰 너비에서 총 여백을 제외하고 순수하게 아이템에 할당할 수 있는 너비를 계산
        let itemWidth = floor(availableWidth / Layout.itemsPerRow)
        /// 사용 가능한 너비를 아이템 개수로 나누고, 소수점 이하를 버려 개별 아이템의 너비를 확정
        return CGSize(width: itemWidth, height: itemWidth * 1.5)
        /// 계산된 너비와, 너비의 1.5배 비율을 적용한 높이를 반환 (포스터 비율)
    }
    
    // 화면
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // 끝에서 4개 남았을 때 다음 페이지 미리 로드
        let thresholdIndex = max(movies.count - 4, 0)
        // 페이지가 끝에 도달했는지 확인을 하고 끝에 도달했으면 현재 페이지에 이어붙이는 코드
        if indexPath.item == thresholdIndex, currentPage < totalPages {
            load(page: currentPage + 1, replace: false)
        }
    }

    // 아이템 선택
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 포스터를 누르면 MovieDetailViewCOntroller를 켜지게 만드는 로직
        let detailVC = MovieDetailViewController(nibName: "MovieDetailViewController", bundle: nil)
        detailVC.movie = movies[indexPath.item]

        // 이동을 위한 navigationController
        if let nav = navigationController {
            /// 내비게이션 스택이 있을 경우: Push 방식으로 가로방향으로 상세 화면 전환 (계층적 이동)
            nav.pushViewController(detailVC, animated: true)
        } else {
            /// 내비게이션 스택이 없을 경우: Present 방식으로 상세 화면 전환
            /// 모달 방식 : 다른 화면을 현재 화면 위로 present 해서 표현하는 방식
            present(detailVC, animated: true)
        }
    }
}

// MARK: - UISearchBarDelegate
extension MainViewController: UISearchBarDelegate {
    // 검색 버튼
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        /// 키보드 내리기
        searchBar.resignFirstResponder()
        /// 공백 제거 후 검색어 설정 및 재로딩
        let text = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        query = text.isEmpty ? nil : text
        reloadFromStart() /// 초기화하고 다시 로드
    }
    // 취소 버튼
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        /// 텍스트 초기화 및 키보드 내리기
        searchBar.text = nil
        searchBar.resignFirstResponder()
        /// 검색어 초기화 후 재로딩
        query = nil
        reloadFromStart() /// 초기화하고 다시 로드
    }
}

