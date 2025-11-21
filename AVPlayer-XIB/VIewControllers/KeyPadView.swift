//
//  KeyPadView.swift
//  AVPlayer-XIB
//
//  Created by 홍승표 on 11/19/25.
//

import UIKit


class KeyPadView: UIView {
    
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
    @IBOutlet weak var twelveButton: UIButton!
    
    private var digitButtons: [UIButton] {
        [oneButton, twoButton, threeButton,
         fourButton, fiveButton, sixButton,
         sevenButton, eightButton, nineButton,
         tenButton, elevenButton].compactMap { $0 }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

