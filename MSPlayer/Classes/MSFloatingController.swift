//
//  MSFloatingController.swift
//  MSPlayer
//
//  Created by Mason on 2018/5/14.
//

import Foundation
import UIKit

public class MSFloatingController: NSObject {
    
    open var type: MSFloatingType = .normal
    
    open class func shared() -> MSFloatingController {
        if self.sharedInstance == nil {
            self.sharedInstance = MSFloatingController()
        }
        return self.sharedInstance ?? MSFloatingController()
    }
    
    //MARK: Shared Instance
    internal static var sharedInstance: MSFloatingController?
    
    //MARK: MSFloatingViewController floating state
    public enum FloatingState {
        case animation
        case normal
        case minimum
    }
    
    // Avoid init
    internal override init() { }
    
    //MARK: Local Variable
    var floatableType: MSFloatableViewController? {
        didSet {
            if floatableType == nil {
                self.gestureManager = nil
                MSFloatingController.sharedInstance = nil
                MSPM.shared().msFloatingWindow = nil
            }
        }
    }
    
    internal var gestureManager: MSFloatingGestureManager?
    public var msplayerWindow: UIWindow?
    public var closeFloatingVC: (() -> (Void))?
    public var shrinkFloatingVC: (() -> (Void))?
    public var expandFloatingVC: (() -> (Void))?
    public var state: FloatingState = .normal
    
    // FloatingView Setting
    public var floatingMinimizedSize = MSPM.shared().floatingViewMinSize
    public var windowOriginFrame = CGRect.zero
    public var windowMinimizedFrame = CGRect.zero
    public var floatingViewOriginFrame = CGRect.zero
    public var floatingViewMinimizedFrame = CGRect.zero
    internal var floatingViewTapGesture: UITapGestureRecognizer?
    
    //MARK: - Previous Window Status
    internal var mainWindowStatusBarStyle: UIStatusBarStyle = UIApplication.shared.statusBarStyle
    internal var floatingWindowStatusBarStyle: UIStatusBarStyle = .lightContent
    
    // status
    fileprivate var isFullScreen: Bool {
        get {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
    
    public func show(_ animated: Bool, frame: CGRect = UIScreen.main.bounds, floatableVC: MSFloatableViewController) {
        
        saveMainWindowStatus()
        
        if floatableType == nil {
            
            self.floatableType = floatableVC
            self.windowOriginFrame = frame
            self.state = .normal
            guard
                let msplayerWindow = createCustomWindowWith(frame),
                let floatableVC = floatableType as? UIViewController else {
                    return
            }
            // Set connection between controller and vc
            msplayerWindow.rootViewController = floatableVC
            floatableType?.floatingController = self
            addObserver()
            changePlayerBackImage(toDown: true)
            
            if animated {
                let screenBounds = UIScreen.main.bounds
                floatableVC.view.frame = CGRect(x: screenBounds.size.width,
                                                y: screenBounds.size.height,
                                                width: msplayerWindow.frame.size.width,
                                                height: msplayerWindow.frame.size.height)
                floatableVC.view.alpha = 0
                floatableVC.view.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                
                UIView.animate(withDuration: 0.5, animations: {
                    floatableVC.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    floatableVC.view.alpha = 1
                    floatableVC.view.frame = CGRect(x: 0,
                                                    y: 0,
                                                    width: msplayerWindow.frame.size.width,
                                                    height: msplayerWindow.frame.size.height)
                }) { (finish) in
                    
                }
            } else {
                floatableVC.view.frame = CGRect(x: 0,
                                                y: 0,
                                                width: msplayerWindow.frame.size.width,
                                                height: msplayerWindow.frame.size.height)
            }
            
        } else {
            
            //MARK: 如果已經存在則先判斷現在的狀態，如果是min則還原成normal，如果是normal則切換當前vc
            switch state {
                
            case .minimum:
                //MARK: - expand current VC
                expand()
                fallthrough
            case .normal:
                //MARK: - replace current VC
                self.closeFloatingVC?()
                self.floatableType = floatableVC
                if let floatableVC = floatableType as? UIViewController {
                    self.msplayerWindow?.rootViewController = floatableVC
                    self.floatableType?.floatingController = self
                }
            default:
                break
            }
        }
    }
    
    //MARK: - close current vc
    public func close(_ animated: Bool = true) {
        self.closeFloatingVC?()
        self.floatableType = nil
        self.msplayerWindow = nil
    }
    
    //MARK: - shrink current vc
    public func shrink() {
        //MARK: - 如果 floatableVC 在畫面上，以及目前狀態不等於縮小化狀態，才可以放大
        if floatableType != nil && self.state != .minimum {
            shrinkViews()
            prepareToShrink()
        }
    }
    
    //MARK: - expand current vc
    public func expand() {
        if floatableType != nil && self.state != .normal {
            expandViews()
            prepareToExpand()
        }
    }
    
    //MARK: - Do something when you shrink
    internal func prepareToShrink() {
        self.floatableType?.floatingPlayer.closeControlViewAndRemoveGesture()
        shrinkFloatingVC?()
        returnToMainWindowStatus()
    }
    
    func returnToMainWindowStatus() {
        // Save floatingWindow status
        self.floatingWindowStatusBarStyle = UIApplication.shared.statusBarStyle
        // Change to mainWindowStatusBarStyle
        UIApplication.shared.statusBarStyle = self.mainWindowStatusBarStyle
    }
    
    func returnToFloatingWindowStatus() {
        UIApplication.shared.statusBarStyle = self.floatingWindowStatusBarStyle
    }
    
    func saveMainWindowStatus() {
        self.mainWindowStatusBarStyle = UIApplication.shared.statusBarStyle
    }
    
    //MARK: - Do something when you shrink
    internal func prepareToExpand() {
        self.floatableType?.floatingPlayer.openControlViewAndSetGesture()
        expandFloatingVC?()
        returnToFloatingWindowStatus()
    }
    
    //MARK: - change MSPlayer setting
    internal func changePlayerBackImage(toDown: Bool) {
        self.floatableType?.floatingPlayer.changeControlViewBackButtonImage(toDown: toDown)
    }
    
    
    //MARK: - create floating window
    internal final func createCustomWindowWith(_ frame: CGRect) -> UIWindow? {
        msplayerWindow = UIWindow(frame: frame)
        if let msplayerWindow = msplayerWindow {
            // Set Window setting
            msplayerWindow.tag = 777
            msplayerWindow.translatesAutoresizingMaskIntoConstraints = false
            msplayerWindow.isHidden = false
            msplayerWindow.windowLevel = UIWindowLevelStatusBar - 1
        }
        MSPM.shared().msFloatingWindow = msplayerWindow
        return msplayerWindow
    }
    
    fileprivate func setSlideGesture() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(gestureManager?.panAction(_:)))
        floatableType?.floatingPlayer.addGestureRecognizer(gesture)
    }
    
    @objc fileprivate func onOrientationChanged() {
        //MARK: - fullScreen and change backImage To back
        if UIApplication.shared.statusBarOrientation.isLandscape {
            changePlayerBackImage(toDown: false)
        } else {
            changePlayerBackImage(toDown: true)
        }
        updateFrame()
    }
    
    func updateFrame() {
        if isFullScreen && self.state == .minimum {
            expand()
        }
    }
    
    func addObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onOrientationChanged),
                                               name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation,
                                               object: nil)
    }
    
    func removeObserver() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation,
                                                  object: nil)
    }
    
    func prepareToDealloc() {
        removeObserver()
    }
    
    deinit {
        prepareToDealloc()
        print("class: \(self.classForCoder) dealloc")
    }
}

extension MSFloatingController {
    
    internal final func expandViews(isAnimation: Bool = true) {
        //MARK: - set state at animation
        if isAnimation {
            self.state = .animation
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                self.floatableType?.floatingPlayer.frame = self.floatingViewOriginFrame
                self.msplayerWindow?.frame = self.windowOriginFrame
                self.floatableType?.floatingPlayer.alpha = 1.0
                self.floatableType?.floatingPlayer.layer.borderWidth = 0
            }) { (finished) in
                if let floatingGesture = self.floatingViewTapGesture {
                    self.floatableType?.floatingPlayer.removeGestureRecognizer(floatingGesture)
                }
                self.floatingViewTapGesture = nil
                self.state = .normal
            }
        } else {
            self.floatableType?.floatingPlayer.frame = self.floatingViewOriginFrame
            self.msplayerWindow?.frame = self.windowOriginFrame
            self.floatableType?.floatingPlayer.alpha = 1.0
            self.floatableType?.floatingPlayer.layer.borderWidth = 0
            if let floatingGesture = self.floatingViewTapGesture {
                self.floatableType?.floatingPlayer.removeGestureRecognizer(floatingGesture)
            }
            self.floatingViewTapGesture = nil
            self.state = .normal
        }
    }
    
    internal final func shrinkViews() {
        
        // 縮小前將originFrame設定好
        self.floatingViewOriginFrame = self.floatableType?.floatingPlayer.frame ?? CGRect.zero
        
        //
        self.floatableType?.floatingPlayer.translatesAutoresizingMaskIntoConstraints = true
        
        let yOffset = windowOriginFrame.size.height - self.floatingMinimizedSize.height
        let xOffset = windowOriginFrame.size.width - self.floatingMinimizedSize.width
        
        windowMinimizedFrame.origin.y = yOffset
        windowMinimizedFrame.origin.x = xOffset
        windowMinimizedFrame.size.width = self.floatingMinimizedSize.width
        windowMinimizedFrame.size.height = self.floatingMinimizedSize.height
        
        //MARK: - 定義浮動視窗的長度
        floatingViewMinimizedFrame.size.width = self.floatingMinimizedSize.width
        floatingViewMinimizedFrame.size.height = self.floatingMinimizedSize.height
        
        //MARK: - set state at animation
        self.state = .animation
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            self.floatableType?.floatingPlayer.frame = self.floatingViewMinimizedFrame
            self.msplayerWindow?.frame = self.windowMinimizedFrame
            self.floatableType?.floatingPlayer.layer.borderWidth = 1
            self.floatableType?.floatingPlayer.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        }) { (finished) in
            if let floatingGesture = self.floatingViewTapGesture {
                self.floatableType?.floatingPlayer.removeGestureRecognizer(floatingGesture)
            }
            self.floatingViewTapGesture = nil
            self.floatingViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.expand))
            self.floatableType?.floatingPlayer.addGestureRecognizer(self.floatingViewTapGesture!)
            self.gestureManager = MSFloatingGestureManager(floatingController: self)
            self.gestureManager?.setSlideGesture()
            
            self.state = .minimum
            self.floatableType?.floatingPlayer.layoutIfNeeded()
        }
    }
}
