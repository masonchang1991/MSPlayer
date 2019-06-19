//
//  CustomPlayNextView.swift
//  MSPlayer_Example
//
//  Created by Mason on 2019/6/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import MSPlayer

class TapExampleView: UIView {
    
    @IBOutlet weak var goNextImageView: UIImageView!
    @IBOutlet weak var imageTextLabel: UILabel!
    @IBOutlet weak var bottomTextLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        nibSetup()
        setupViews()
        setupGestures()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
        setupGestures()
    }
    
    private func nibSetup() {
        let view = loadViewFromNib()
        view.frame = bounds
        addSubview(view)
    }
    
    private func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "TapExampleView", bundle: bundle)
        let nibView = nib.instantiate(withOwner: self, options: nil).first as! UIView
        
        return nibView
    }
    
    func setupViews() {
        imageTextLabel.textAlignment = .center
        bottomTextLabel.textAlignment = .center
        
        imageTextLabel.font = UIFont(name: "PingFangTC-Semibold",
                                     size:  13)
        imageTextLabel.textColor = UIColor.white
        bottomTextLabel.font = UIFont(name: "PingFangTC-Regular",
                                      size: 13)
        bottomTextLabel.textColor = UIColor.white
    }
    
    func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tap)
    }
    
    @objc func handleTap() {
        print()
    }
}

class PlayNextView: TapExampleView, MSPlayNext {
    
    var playNext: (() -> ())?
    
    override func setupViews() {
        super.setupViews()
        imageTextLabel.text = "Go"
        bottomTextLabel.text = "點擊觀看下一部"
    }
    
    @objc override func handleTap() {
        super.handleTap()
        playNext?()
    }
    
    func startPreparing() {
        
    }
    
    func pausePreparing() {
        
    }
}
