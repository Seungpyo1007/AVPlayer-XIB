import UIKit

final class CollectionViewXibCell: UICollectionViewCell {
    
    @IBOutlet private weak var posterImageView: UIImageView!
    
    // MARK: - 상태 및 의존성
    private var currentTask: URLSessionDataTask? /// 웹 서버 데이터를 요청하고 받아올때 사용
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // 기본 이미지 뷰 설정: 잘린 영역은 숨기고, 모서리 둥글게 처리
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.layer.cornerRadius = 12
        showPlaceholder() /// 초기 상태는 showPlaceholder
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // 진행 중인 이미지 로딩 작업 취소 및 초기화
        currentTask?.cancel()
        currentTask = nil
        showPlaceholder()
    }

    func configure(with movie: Movie) {
        loadPosterImage(from: movie.fullPosterURL) // MovieModel에서 이미지 가져오기
    }

    // 주어진 URL로부터 포스터 이미지를 비동기 로딩
    private func loadPosterImage(from url: URL?) {
        if let url {
            /// 배경을 투명하게 하여 둥근 모서리가 깔끔하게 보이게 처리
            posterImageView.backgroundColor = .clear
            /// 중복 요청을 막기 위해 기존 작업은 취소
            currentTask?.cancel()
            /// 이미지 로더를 통해 비동기 다운로드 요청 시작
            currentTask = ImageLoader.shared.loadImage(from: url) { [weak self] result in
                /// UI 업데이트를 위해 메인 스레드로 전환
                DispatchQueue.main.async {
                    /// 다운로드 결과를 처리하는 함수 호출
                    self?.handleImageLoadResult(result)
                }
            }
        } else {
            showPlaceholder()
            return
        }
    }

    // 이미지 로딩 결과를 처리합니다.
    private func handleImageLoadResult(_ result: Result<UIImage, Error>) {
        switch result {
        case .success(let image):
            posterImageView.image = image
        case .failure:
            showPlaceholder()
        }
    }

    // 상태를 표시
    private func showPlaceholder() {
        posterImageView.image = nil
        posterImageView.backgroundColor = .systemGray /// 없으면 회색으로 표시
    }
}
