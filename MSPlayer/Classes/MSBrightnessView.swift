//
//  MSBrightnessView.swift
//  MSPlayer
//
//  Created by Mason on 2018/4/25.
//

import Foundation
import UIKit

class BrightnessView: UIView {
    
    private static var sharedInstance: BrightnessView?
    
    var backImageView = UIImageView()
    var titleLabel = UILabel()
    var brightnessLevelView = UIView()
    var tipArray = NSMutableArray()
    var timer: Timer? = Timer()
    
    var screenWidth: CGFloat {
        return UIScreen.main.bounds.size.width
    }
    var screenHeight: CGFloat {
        return UIScreen.main.bounds.size.height
    }
    var systemVersion: Float {
        guard let version = Float(UIDevice.current.systemVersion) else {
            return 1.0
        }
        return version
    }
    
    @discardableResult
    static func shared() -> BrightnessView? {
        if self.sharedInstance == nil {
            self.sharedInstance = BrightnessView()
            self.sharedInstance?.tag = 200
        }
        return sharedInstance
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.frame = CGRect(x: screenWidth * 0.5,
                            y: screenHeight * 0.5,
                            width: 155,
                            height: 155)
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        
        // 毛玻璃效果
        let toolbar = UIToolbar(frame: self.bounds)
        toolbar.barTintColor = UIColor(red: 199.0/255.0,
                                       green: 199.0/255.0,
                                       blue: 203.0/255.0,
                                       alpha: 1.0)
        self.addSubview(toolbar)
        
        self.addSubview(self.backImageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.brightnessLevelView)
        
        self.titleLabel = UILabel(frame: CGRect(x: 0, y: 5, width: self.bounds.size.width, height: 30))
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        self.titleLabel.textColor = UIColor(red: 0.25,
                                            green: 0.22,
                                            blue: 0.21,
                                            alpha: 1.0)
        self.titleLabel.textAlignment = .center
        self.titleLabel.text = MSPlayerConfig.brightnessTitle
        
        self.backImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 79, height: 76))
        self.backImageView.image = MSPlayerConfig.brightnessImage
        
        self.brightnessLevelView = UIView(frame: CGRect(x: 13, y: 132, width: self.bounds.size.width - 26, height: 7))
        self.brightnessLevelView.backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.21, alpha: 1.0)
        self.addSubview(self.titleLabel)
        self.addSubview(self.backImageView)
        self.addSubview(self.brightnessLevelView)
        self.createTips()
        self.addStatucBarNotification()
        self.addKVOObserver()
        self.alpha = 0.0
    }
    
    // 建立 Tips
    func createTips() {
        
        self.tipArray = NSMutableArray(capacity: 16)
        let tipW = (self.brightnessLevelView.bounds.size.width - 17) / 16
        let tipH: CGFloat = 5
        let tipY: CGFloat = 1
        
        for index in 0..<16 {
            let tipX = CGFloat(index) * (tipW + 1) + 1
            let tipImageView = UIImageView()
            tipImageView.backgroundColor = UIColor.white
            tipImageView.frame = CGRect(x: tipX, y: tipY, width: tipW, height: tipH)
            self.brightnessLevelView.addSubview(tipImageView)
            self.tipArray.add(tipImageView)
        }
        self.updateBrightnessLevelWith(UIScreen.main.brightness)
    }
    
    func updateBrightnessLevelWith(_ brightnessLevel: CGFloat) {
        let stage: CGFloat = 1 / 15.0
        let level: Int =  Int(brightnessLevel / stage)
        for index in 0..<self.tipArray.count {
            guard let tipImageView = self.tipArray[index] as? UIImageView else { return }
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
        case .portrait:
            fallthrough
        case .portraitUpsideDown:
            self.center = CGPoint(x: screenWidth * 0.5,
                                  y: (screenHeight - 10) * 0.5)
            break
        case .landscapeLeft:
            fallthrough
        case .landscapeRight:
            self.center = CGPoint(x: screenWidth * 0.5,
                                  y: screenHeight * 0.5)
            break
        default:
            break
        }
        self.backImageView.center = CGPoint(x: 155 * 0.5,
                                            y: 155 * 0.5)
        self.superview?.bringSubviewToFront(self)
    }
    
    func addStatucBarNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationNotification(_:)),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }
    
    func addKVOObserver() {
        UIScreen.main.addObserver(self,
                                  forKeyPath: "brightness",
                                  options: NSKeyValueObservingOptions.new,
                                  context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard
            let dic = change,
            let levelValue = dic[NSKeyValueChangeKey.newKey] as? Float else {
                return
        }
        self.removeTimer()
        self.appearBrightnessView()
        self.updateBrightnessLevelWith(CGFloat(levelValue))
    }
    
    // statusBar change notify
    @objc func statusBarOrientationNotification(_ notify: NSNotification) {
        self.setNeedsLayout()
    }
    
    // Brightness 顯示 隱藏
    func appearBrightnessView() {
        UIView.animate(withDuration: 0.2, animations: {
            if MSPM.shared().msFloatingWindow != nil {
                MSPM.shared().msFloatingWindow?.addSubview(BrightnessView.sharedInstance ?? BrightnessView())
            } else {
                UIApplication.shared.keyWindow?.addSubview(BrightnessView.sharedInstance ?? BrightnessView())
            }
            self.alpha = 1.0
        }) { (finished) in
            self.addTimer()
        }
    }
    
    @objc func disappearBrightnessView() {
        if self.alpha == 1.0 {
            UIView.animate(withDuration: 0.5, animations: {
                self.alpha = 0.0
            }, completion: { (finished) in
                for subview in UIApplication.shared.windows.first?.subviews ?? [] {
                    if subview.tag == 200 {
                        subview.removeFromSuperview()
                    }
                }
                self.removeTimer()
            })
        }
    }
    
    open func removeBrightnessView() {
        for subview in UIApplication.shared.windows.first?.subviews ?? [] {
            if subview.tag == 200 {
                subview.removeFromSuperview()
            }
        }
        self.removeTimer()
    }
    
    func addTimer() {
        if self.timer != nil { return }
        self.timer = Timer(timeInterval: 2,
                           target: self,
                           selector: #selector(disappearBrightnessView),
                           userInfo: nil,
                           repeats: false)
        RunLoop.main.add(self.timer ?? Timer(),
                         forMode: RunLoop.Mode.default)
    }
    
    func removeTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    deinit {
        UIScreen.main.removeObserver(self, forKeyPath: "brightness")
        NotificationCenter.default.removeObserver(self)
        print(classForCoder.self, "dealloc - MSPlayer")
    }
}
