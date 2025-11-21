//
//  PasscodeLockViewController.swift
//  AVPlayer-XIB
//
//  Created by 홍승표 on 11/11/25.
//

import UIKit
import LocalAuthentication

// 1. KeyPadView : 내장버전
// 2. KeyPadView : 스택뷰로 쌓아서 만든 외장 키패드
// 3. KeyBoardView : 그냥 제약 조건으로 맞춘 키패드
class PasscodeLockViewController: UIViewController {
    
    // MARK: - Outlets
    // 임시 키보드 생성 필드
    @IBOutlet weak var firstTextField: UITextField!
    @IBOutlet weak var secondTextField: UITextField!
    
    // PasscodeLockViewController에 있는 KeyPadView (숨겨진 상태)
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
    @IBOutlet weak var twelveButton: UIButton! /// 삭제(백스페이스) 버튼
    
    // MARK: - Test Outlets
//    @IBOutlet weak var testOneButton: UIButton!
//    @IBOutlet weak var testTwoButton: UIButton!
//    @IBOutlet weak var testThreeButton: UIButton!
//    @IBOutlet weak var testFourButton: UIButton!
//    @IBOutlet weak var testFiveButton: UIButton!
//    @IBOutlet weak var testSixButton: UIButton!
//    @IBOutlet weak var testsevenButton: UIButton!
//    @IBOutlet weak var testEightButton: UIButton!
//    @IBOutlet weak var testNineButton: UIButton!
//    @IBOutlet weak var testTenButton: UIButton!
//    @IBOutlet weak var testElevenButton: UIButton!
//    @IBOutlet weak var testTwelveButton: UIButton!

    // MARK: - 상태 및 의존성
    private let passcode: [String] = ["1","0","0","7","1","2"]
    private var entered: [String] = [] /// 사용자가 입력한 숫자 기록
    
    private var keyPadView: KeyPadView?
    private var keyBoardView: KeyBoardView?

    /// 숫자 키패드 버튼 모음 (12번은 삭제 버튼이므로 제외)
    private var digitButtons: [UIButton] {
        var buttons: [UIButton] = []
        // 1) KeyBoardView에 있는 숫자 버튼들
        if let keyboard = keyBoardView {
            buttons += [
                keyboard.oneButton, keyboard.twoButton, keyboard.threeButton,
                keyboard.fourButton, keyboard.fiveButton, keyboard.sixButton,
                keyboard.sevenButton, keyboard.eightButton, keyboard.nineButton,
                keyboard.tenButton, keyboard.elevenButton
            ].compactMap { $0 }
        }
        // 2) 외장 KeyPadView에 있는 숫자 버튼들
        if let keypad = keyPadView {
            buttons += [
                keypad.oneButton, keypad.twoButton, keypad.threeButton,
                keypad.fourButton, keypad.fiveButton, keypad.sixButton,
                keypad.sevenButton, keypad.eightButton, keypad.nineButton,
                keypad.tenButton, keypad.elevenButton
            ].compactMap { $0 }
        }
        // 3) 내장 아웃렛 숫자 버튼들
        buttons += [
            oneButton, twoButton, threeButton,
            fourButton, fiveButton, sixButton,
            sevenButton, eightButton, nineButton,
            tenButton, elevenButton
        ].compactMap { $0 }
        return buttons
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
        keyBoard()
        keyPad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        configureButtons()      // 버튼 타깃/라벨 설정
        randomizeKeypad()       // 키패드 랜덤 배치
        attemptFaceIDIfAvailable() // Face ID 자동 인증 시도
    }
    
    // 키보드 내리기
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - 키보드 테스트
    private func keyPad() {
        let myKeypad = Bundle.main.loadNibNamed("KeyPadView", owner: nil, options: nil)
        guard let keypad = myKeypad?.first as? KeyPadView else { return }
        self.keyPadView = keypad
        firstTextField.inputView = keypad
    }
    
    private func keyBoard() {
        let myKeyboard = Bundle.main.loadNibNamed("KeyBoardView", owner: nil, options: nil)
        guard let keyboard = myKeyboard?.first as? KeyBoardView else { return }
        self.keyBoardView = keyboard
        secondTextField.inputView = keyboard
    }

    // MARK: - UI 구성
    /// 키패드/삭제 버튼 타깃 및 접근성 라벨 설정
    private func configureButtons() {
        /// ?
        guard !digitButtons.isEmpty else { return }
        // 숫자 버튼: 공통 타깃 연결
        digitButtons.forEach {
            $0.addTarget(self, action: #selector(didTapDigitButton(_:)),
                         for: .touchUpInside) }
        
        
        // 삭제(백스페이스) 버튼 설정: 모든 소스에 대해 동시에 연결
        var deleteButtons: [UIButton] = []
        if let keyboard = keyBoardView, let del = keyboard.twelveButton { deleteButtons.append(del) }
        if let keypad = keyPadView, let del = keypad.twelveButton { deleteButtons.append(del) }
        if let del = twelveButton { deleteButtons.append(del) }

        deleteButtons.forEach { btn in
            btn.setTitle("⌫", for: .normal)
            btn.removeTarget(nil, action: nil, for: .allEvents)
            btn.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)
            btn.accessibilityLabel = "Delete"
        }
    }

    /// 키패드 숫자/Face ID 버튼을 랜덤 배치
    private func randomizeKeypad() {
        // 공통 아이템 풀 구성 (0~9 + FaceID 또는 빈칸)
        var items: [String] = (0...9).map { String($0) }
        if isFaceIDAvailable {
            items.append("FaceID")
        } else {
            items.append("")
        }

        // 버튼 배열에 셔플된 풀을 적용하는 헬퍼
        func applyPool(to buttons: [UIButton?]) {
            // 버튼 개수(11개)에 맞춰 셔플/자르기/채우기
            var pool = items.shuffled()
            if pool.count > 11 {
                pool = Array(pool.prefix(11))
            } else if pool.count < 11 {
                let extras = (0...9).map { String($0) }.shuffled()
                for v in extras where pool.count < 11 { pool.append(v) }
            }
            for (buttonOpt, value) in zip(buttons, pool) {
                guard let button = buttonOpt else { continue }
                if value == "FaceID" {
                    button.setTitle(value, for: .normal)
                    button.isHidden = false
                    button.isEnabled = true
                    button.accessibilityLabel = "Face ID"
                } else if value == "" {
                    // 빈칸 처리: 숨김
                    button.setTitle("", for: .normal)
                    button.isHidden = true
                    button.isEnabled = false
                    button.accessibilityLabel = nil
                } else {
                    // 숫자 처리
                    button.setTitle(value, for: .normal)
                    button.isHidden = false
                    button.isEnabled = true
                    button.accessibilityLabel = value
                }
            }
        }

        // 1) KeyBoardView 버튼들에 적용
        if let keyboard = keyBoardView {
            applyPool(to: [
                keyboard.oneButton, keyboard.twoButton, keyboard.threeButton,
                keyboard.fourButton, keyboard.fiveButton, keyboard.sixButton,
                keyboard.sevenButton, keyboard.eightButton, keyboard.nineButton,
                keyboard.tenButton, keyboard.elevenButton
            ])
        }
        
        // 2) KeyPadView 버튼들에 적용
        if let keypad = keyPadView {
            applyPool(to: [
                keypad.oneButton, keypad.twoButton, keypad.threeButton,
                keypad.fourButton, keypad.fiveButton, keypad.sixButton,
                keypad.sevenButton, keypad.eightButton, keypad.nineButton,
                keypad.tenButton, keypad.elevenButton
            ])
        }
        
        // 3) 내장 아웃렛 버튼들에 적용
        applyPool(to: [
            oneButton, twoButton, threeButton,
            fourButton, fiveButton, sixButton,
            sevenButton, eightButton, nineButton,
            tenButton, elevenButton
        ])
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

