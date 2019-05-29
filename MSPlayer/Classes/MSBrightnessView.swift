//
//  MSBrightnessView.swift
//  MSPlayer
//
//  Created by Mason on 2018/4/25.
//

import Foundation
import UIKit

protocol MSBrightnessView {
    func updateBrightnessLevelWith(_ brightnessLevel: CGFloat)
    func removeBrightnessView()
}

class BrightnessView: UIView, MSBrightnessView {
    
    private static var sharedInstance: BrightnessView?
    
    private var backImageView = UIImageView()
    private var titleLabel = UILabel()
    private var brightnessLevelView = UIView()
    private var tipArray = NSMutableArray()
    private var timer: Timer? = Timer()
    
    private var screenWidth: CGFloat {
        return UIScreen.main.bounds.size.width
    }
    private var screenHeight: CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    @discardableResult
    static func shared() -> BrightnessView {
        if let sharedInstance = self.sharedInstance {
            return sharedInstance
        } else {
            let brightnessView = BrightnessView()
            brightnessView.tag = 200
            self.sharedInstance = brightnessView
            return brightnessView
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        frame = CGRect(x: screenWidth * 0.5,
                       y: screenHeight * 0.5,
                       width: 155,
                       height: 155)
        layer.cornerRadius = 10
        layer.masksToBounds = true
        
        // 毛玻璃效果
        let toolbar = UIToolbar(frame: bounds)
        toolbar.barTintColor = UIColor(red: 199.0/255.0,
                                       green: 199.0/255.0,
                                       blue: 203.0/255.0,
                                       alpha: 1.0)
        addSubview(toolbar)
        addSubview(backImageView)
        addSubview(titleLabel)
        addSubview(brightnessLevelView)
        
        titleLabel = UILabel(frame: CGRect(x: 0, y: 5, width: bounds.size.width, height: 30))
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = UIColor(red: 0.25,
                                       green: 0.22,
                                       blue: 0.21,
                                       alpha: 1.0)
        titleLabel.textAlignment = .center
        titleLabel.text = MSPlayerConfig.brightnessTitle
        
        backImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 79, height: 76))
        backImageView.image = MSPlayerConfig.brightnessImage
        
        brightnessLevelView = UIView(frame: CGRect(x: 13, y: 132, width: bounds.size.width - 26, height: 7))
        brightnessLevelView.backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.21, alpha: 1.0)
        addSubview(titleLabel)
        addSubview(backImageView)
        addSubview(brightnessLevelView)
        createTips()
        addStatucBarNotification()
        alpha = 0.0
    }
    
    // 建立 Tips
    private func createTips() {
        self.tipArray = NSMutableArray(capacity: 16)
        let tipW = (brightnessLevelView.bounds.size.width - 17) / 16
        let tipH: CGFloat = 5
        let tipY: CGFloat = 1
        
        for index in 0..<16 {
            let tipX = CGFloat(index) * (tipW + 1) + 1
            let tipImageView = UIImageView()
            tipImageView.backgroundColor = UIColor.white
            tipImageView.frame = CGRect(x: tipX, y: tipY, width: tipW, height: tipH)
            brightnessLevelView.addSubview(tipImageView)
            tipArray.add(tipImageView)
        }
        setInitialBrightnessLevelWith(UIScreen.main.brightness)
    }
    
    private func setInitialBrightnessLevelWith(_ brightnessLevel: CGFloat) {
        let stage: CGFloat = 1 / 15.0
        let level: Int =  Int(brightnessLevel / stage)
        for index in 0..<tipArray.count {
            guard let tipImageView = tipArray[index] as? UIImageView else { return }
            if index <= level {
                tipImageView.isHidden = false
            } else {
                tipImageView.isHidden = true
            }
        }
    }
    
    open func updateBrightnessLevelWith(_ brightnessLevel: CGFloat) {
        // show UI and reset timer(remove previous and add new one)
        showBrightnessView()
        // change UI
        let stage: CGFloat = 1 / 15.0
        let level: Int =  Int(brightnessLevel / stage)
        for index in 0..<tipArray.count {
            guard let tipImageView = tipArray[index] as? UIImageView else { return }
            if index <= level {
                tipImageView.isHidden = false
            } else {
                tipImageView.isHidden = true
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let currentOrientation = UIApplication.shared.statusBarOrientation
        switch currentOrientation {
        case .portraitUpsideDown, .portrait:
            center = CGPoint(x: screenWidth * 0.5,
                             y: (screenHeight - 10) * 0.5)
        case .landscapeRight, .landscapeLeft:
            center = CGPoint(x: screenWidth * 0.5,
                             y: screenHeight * 0.5)
        default: break
        }
        backImageView.center = CGPoint(x: 155 * 0.5,
                                       y: 155 * 0.5)
        superview?.bringSubviewToFront(self)
    }
    
    private func addStatucBarNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationNotification(_:)),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }
    
    // statusBar change notify
    @objc private func statusBarOrientationNotification(_ notify: NSNotification) {
        setNeedsLayout()
    }
    
    // Brightness 顯示 隱藏
    private func showBrightnessView() {
        removeTimer()
        UIView.animate(withDuration: 0.2, animations: {
            if MSPM.shared().msFloatingWindow != nil {
                if let brightnessView = BrightnessView.sharedInstance {
                    MSPM.shared().msFloatingWindow?.addSubview(brightnessView)
                }
            } else {
                if let brightnessView = BrightnessView.sharedInstance {
                    UIApplication.shared.keyWindow?.addSubview(brightnessView)
                }
            }
            self.alpha = 1.0
        }) { [weak self](finished) in
            self?.addTimer()
        }
    }
    
    @objc private func disappearBrightnessView() {
        if self.alpha == 1.0 {
            UIView.animate(withDuration: 0.5, animations: {
                self.alpha = 0.0
            }, completion: { [weak self](finished) in
                BrightnessView.sharedInstance?.removeFromSuperview()
                self?.removeTimer()
            })
        }
    }
    
    open func removeBrightnessView() {
        BrightnessView.sharedInstance?.removeFromSuperview()
        removeTimer()
    }
    
    private func addTimer() {
        if let _ = self.timer {
            // already have one and don't add twice
        } else {
            let timer = Timer(timeInterval: 2,
                              target: self,
                              selector: #selector(disappearBrightnessView),
                              userInfo: nil,
                              repeats: false)
            self.timer = timer
            RunLoop.main.add(timer,
                             forMode: RunLoop.Mode.default)
        }
    }
    
    private func removeTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        UIScreen.main.removeObserver(self, forKeyPath: "brightness")
        NotificationCenter.default.removeObserver(self)
        print(classForCoder.self, "dealloc - MSPlayer")
    }
}
