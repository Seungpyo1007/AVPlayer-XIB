//
//  PasscodeLockVIewController.swift
//  AVPlayer-XIB
//
//  Created by 홍승표 on 11/11/25.
//

import UIKit
import LocalAuthentication

/// 간단한 비밀번호(패스코드) + Face ID 잠금 화면 컨트롤러
class PasscodeLockVIewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var oneButton: UIButton!
    @IBOutlet weak var twoButton: UIButton!
    @IBOutlet weak var threeButton: UIButton!
    @IBOutlet weak var fourButton: UIButton!
    @IBOutlet weak var fiveButton: UIButton!
    @IBOutlet weak var sixButton: UIButton!
    @IBOutlet weak var sevenButton: UIButton!
    @IBOutlet weak var eightButton: UIButton!
    @IBOutlet weak var nineButton: UIButton!
    @IBOutlet weak var tenButton: UIButton!
    @IBOutlet weak var elevenButton: UIButton!
    @IBOutlet weak var twelveButton: UIButton! // 삭제(백스페이스) 버튼

    // MARK: - 상태 및 의존성
    private let passcode: [String] = ["1","0","0","7","1","2"]
    private var entered: [String] = [] /// 사용자가 입력한 숫자 기록

    /// 숫자 키패드 버튼 모음 (12번은 삭제 버튼이므로 제외)
    private var digitButtons: [UIButton] {
        [oneButton, twoButton, threeButton,
         fourButton, fiveButton, sixButton,
         sevenButton, eightButton, nineButton,
         tenButton, elevenButton].compactMap { $0 }
    }

    /// Face ID 사용 가능 여부
    private var isFaceIDAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        // 생체인증(FaceID) 사용 가능 여부 확인
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return context.biometryType == .faceID
        } else {
            print(error!.localizedDescription)
            return false
        }
    }

    // MARK: - 생명주기 (앱의 실행)
    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtons()      // 버튼 타깃/라벨 설정
        randomizeKeypad()       // 키패드 랜덤 배치
        attemptFaceIDIfAvailable() // Face ID 자동 인증 시도
    }

    // MARK: - UI 구성
    /// 키패드/삭제 버튼 타깃 및 접근성 라벨 설정
    private func configureButtons() {
        // 숫자 버튼: 공통 타깃 연결
        digitButtons.forEach {
            $0.addTarget(self, action: #selector(didTapDigitButton(_:)),
                         for: .touchUpInside) }

        // 삭제(백스페이스) 버튼 설정
        twelveButton.setTitle("⌫", for: .normal)
        twelveButton.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)
        twelveButton.accessibilityLabel = "Delete"
    }

    /// 키패드 숫자/Face ID 버튼을 랜덤 배치
    private func randomizeKeypad() {
        var items: [String] = (0...9).map { String($0) } // 기본 숫자 0~9
        
        if isFaceIDAvailable {
            // Face ID 지원 시: FaceID 항목 추가
            items.append("FaceID")
        } else {
            // Face ID 미지원 시: 빈칸("") 항목 추가
            items.append("")
        }

        
        // 버튼 개수(11개)에 맞춰 셔플/자르기/채우기
        var pool = items.shuffled()
        
        if pool.count > 11 {
            pool = Array(pool.prefix(11))
        } else if pool.count < 11 {
            let extras = (0...9).map { String($0) }.shuffled()
            for v in extras where pool.count < 11 { pool.append(v) }
        }

        // 버튼에 값 반영
        for (button, value) in zip(digitButtons, pool) {
            if value == "FaceID" {
                button.setTitle(value, for: .normal)
                button.isHidden = false
                button.isEnabled = true
                button.accessibilityLabel = "Face ID"
                
            } else if value == "" {
                // 빈칸("") 할당 시: 버튼을 숨김 처리
                button.setTitle("", for: .normal)
                button.isHidden = true
                button.isEnabled = false
                button.accessibilityLabel = nil
                
            } else {
                // 숫자 버튼 처리
                button.setTitle(value, for: .normal)
                button.isHidden = false
                button.isEnabled = true
                button.accessibilityLabel = value
            }
        }
    }

    // MARK: - Actions
    /// 숫자 또는 Face ID 버튼 탭 처리
    @objc private func didTapDigitButton(_ sender: UIButton) {
        guard sender.isEnabled, !sender.isHidden, let value = sender.currentTitle else { return }

        // Face ID 버튼이라면 생체 인증 실행
        if value == "FaceID" {
            authenticateWithFaceID()
            return
        }
        // 숫자 입력 누적
        entered.append(value)
        checkProgress()
    }

    /// 마지막 입력 숫자 삭제
    @objc private func didTapDelete() {
        _ = entered.popLast()
    }

    // MARK: - 검증 테스트
    private func checkProgress() {
        // 최대 길이 초과 시 잘라내기
        if entered.count > passcode.count {
            entered = Array(entered.prefix(passcode.count))
        }
        // 길이가 맞으면 검증
        guard entered.count == passcode.count else { return }
        (entered == passcode) ? passcodeSucceeded() : passcodeFailed()
    }

    /// 인증 성공
    private func passcodeSucceeded() {
        let mainVC = MainViewController(nibName: "MainViewController", bundle: nil)
        if let nav = self.navigationController {
            nav.setViewControllers([mainVC], animated: true) /// 스택을 통째로 교체
        } else {
            mainVC.modalPresentationStyle = .fullScreen
            present(mainVC, animated: true) /// 모달 방식으로 실행
        }
    }

    /// 인증 실패: 흔들림 애니메이션 + 입력 초기화 + 키패드 재배치
    private func passcodeFailed() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-10, 10, -8, 8, -5, 5, 0]
        view.layer.add(animation, forKey: "shake")

        entered.removeAll()
        randomizeKeypad()
    }

    // MARK: - Face ID 인증
    private func attemptFaceIDIfAvailable() {
        if isFaceIDAvailable { authenticateWithFaceID() } /// Face ID 지원 시 자동으로 인증 시도
    }

    /// Face ID 인증 실행
    private func authenticateWithFaceID() {
        let context = LAContext()
        context.localizedReason = "Unlock with Face ID"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock with Face ID") { [weak self] success, _ in
            DispatchQueue.main.async {
                if success {
                    self?.passcodeSucceeded()
                } else {
                    // 실패 시 UI 유지(사용자가 숫자로 입력 가능)
                }
            }
        }
    }
}
