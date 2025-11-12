//
//  PasscodeLockVIewController.swift
//  AVPlayer-XIB
//
//  Created by 홍승표 on 11/11/25.
//

import UIKit
import LocalAuthentication

class PasscodeLockVIewController: UIViewController {
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
    @IBOutlet weak var twelveButton: UIButton!
    
    private let passcode: [String] = ["1","0","0","7","1","2"]
    private var entered: [String] = []
    private var digitButtons: [UIButton] { [oneButton, twoButton, threeButton, fourButton, fiveButton, sixButton, sevenButton, eightButton, nineButton, tenButton, elevenButton].compactMap { $0 } }
    // twelveButton is delete
    
    private var isFaceIDAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) == false {
            return false
        }
        return context.biometryType == .faceID
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtons()
        randomizeKeypad()
        attemptFaceIDIfAvailable()
    }
    
    private func configureButtons() {
        // Assign targets for digit buttons
        for button in digitButtons {
            button.addTarget(self, action: #selector(didTapDigitButton(_:)), for: .touchUpInside)
        }
        // Delete button
        twelveButton.setTitle("⌫", for: .normal)
        twelveButton.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)
        twelveButton.accessibilityLabel = "Delete"
    }

    private func randomizeKeypad() {
        var items: [String] = Array(0...9).map { String($0) }
        if isFaceIDAvailable {
            items.append("FaceID")
        }
        var pool = items.shuffled()
        if pool.count > 11 {
            pool = Array(pool.prefix(11))
        } else if pool.count < 11 {
            let extras = Array(0...9).map { String($0) }.shuffled()
            for v in extras where pool.count < 11 { pool.append(v) }
        }
        for (button, value) in zip(digitButtons, pool) {
            if value == "FaceID" {
                button.setTitle(isFaceIDAvailable ? value : "", for: .normal)
                button.isHidden = !isFaceIDAvailable
                button.isEnabled = isFaceIDAvailable
                button.accessibilityLabel = isFaceIDAvailable ? "Face ID" : nil
            } else {
                button.setTitle(value, for: .normal)
                button.isHidden = false
                button.isEnabled = true
                button.accessibilityLabel = value
            }
        }
    }

    @objc private func didTapDigitButton(_ sender: UIButton) {
        guard sender.isEnabled, !sender.isHidden, let value = sender.currentTitle else { return }
        if value == "FaceID" {
            authenticateWithFaceID()
            return
        }
        // Append digit
        entered.append(value)
        checkProgress()
    }

    @objc private func didTapDelete() {
        if !entered.isEmpty { _ = entered.popLast() }
    }

    private func checkProgress() {
        // Trim to max passcode length
        if entered.count > passcode.count {
            entered = Array(entered.prefix(passcode.count))
        }
        // If full length, validate
        if entered.count == passcode.count {
            if entered == passcode {
                passcodeSucceeded()
            } else {
                passcodeFailed()
            }
        }
    }

    private func passcodeSucceeded() {
        // Instantiate MainViewController from XIB (not storyboard)
        let mainVC = MainViewController(nibName: "MainViewController", bundle: nil)
        if let nav = self.navigationController {
            nav.setViewControllers([mainVC], animated: true)
        } else {
            mainVC.modalPresentationStyle = .fullScreen
            self.present(mainVC, animated: true)
        }
    }

    private func passcodeFailed() {
        // Shake animation feedback
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-10, 10, -8, 8, -5, 5, 0]
        view.layer.add(animation, forKey: "shake")
        // Reset input and randomize again
        entered.removeAll()
        randomizeKeypad()
    }

    private func attemptFaceIDIfAvailable() {
        if isFaceIDAvailable {
            authenticateWithFaceID()
        }
    }

    private func authenticateWithFaceID() {
        let context = LAContext()
        context.localizedReason = "Unlock with Face ID"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock with Face ID") { [weak self] success, _ in
            DispatchQueue.main.async {
                if success {
                    self?.passcodeSucceeded()
                } else {
                    // If Face ID fails, keep UI as-is
                }
            }
        }
    }
}

