//
//  MSFloatingController.swift
//  MSPlayer
//
//  Created by Mason on 2018/5/14.
//

import Foundation

public class MSFloatingController: NSObject {
    
    open static func shared() -> MSFloatingController {
        if self.sharedInstance == nil {
            self.sharedInstance = MSFloatingController()
        }
        return self.sharedInstance ?? MSFloatingController()
    }
    
    //MARK: Shared Instance
    private static var sharedInstance: MSFloatingController?
    
    //MARK: MSFloatingViewController floating state
    public enum FloatingState {
        case animation
        case normal
        case minimum
    }
    
    // Avoid init
    private override init() { }
    
    //MARK: Local Variable
    var floatableType: MSFloatableViewController? {
        didSet {
            if floatableType == nil {
                self.gestureManager = nil
                MSPM.shared().isUsingFloatingControl = false
                MSFloatingController.sharedInstance = nil
            } else {
                MSPM.shared().isUsingFloatingControl = true
            }
        }
    }
    
    var gestureManager: MSFloatingGestureManager?
    public var msplayerWindow: UIWindow?
    public var closeFloatingVC: (() -> (Void))?
    public var shrinkFloatingVC: (() -> (Void))?
    public var expandFloatingVC: (() -> (Void))?
    public var state: FloatingState = .normal
    
    // FloatingView Setting
    public var floatingMinimizedFrame = CGSize(width: 144, height: 81)
    public var windowOriginFrame = CGRect.zero
    public var windowMinimizedFrame = CGRect.zero
    public var floatingViewOriginFrame = CGRect.zero
    public var floatingViewMinimizedFrame = CGRect.zero
    internal var floatingViewTapGesture: UITapGestureRecognizer?
    
    // status
    fileprivate var isFullScreen: Bool {
        get {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
    
    public func show(_ animated: Bool, frame: CGRect = UIScreen.main.bounds, floatableVC: MSFloatableViewController) {
        
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
            self.gestureManager = MSFloatingGestureManager(floatingController: self)
            addObserver()
            
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
            
            self.closeFloatingVC?()
            self.floatableType = nil
            self.floatableType = floatableVC
            if let floatableVC = floatableType as? UIViewController {
                self.msplayerWindow?.rootViewController = floatableVC
                self.floatableType?.floatingController = self
                self.gestureManager = MSFloatingGestureManager(floatingController: self)
            }
            
            //TODO: 如果已經存在則先判斷現在的狀態，如果是min則還原成normal，如果是normal則切換當前vc
            switch state {
                
            case .minimum:
            //TODO: - expand current VC
                expand()
            case .normal:
            //TODO: - change current VC
                print("")
            default:
                break
            }
        }
    }
    
    public func close(_ animated: Bool = true) {
        self.closeFloatingVC?()
        self.floatableType = nil
        self.msplayerWindow = nil
    }
    
    public func shrink() {
        //MARK: - 如果 floatableVC 在畫面上，以及目前狀態不等於縮小化狀態，才可以放大
        if floatableType != nil && self.state != .minimum {
            shrinkViews()
            shrinkFloatingVC?()
        }
    }
    
    public func expand() {
        if floatableType != nil && self.state != .normal {
            expandViews()
            expandFloatingVC?()
        }
    }
    
    private func createCustomWindowWith(_ frame: CGRect) -> UIWindow? {
        msplayerWindow = UIWindow(frame: frame)
        if let msplayerWindow = msplayerWindow {
            // Set Window setting
            msplayerWindow.tag = 777
            msplayerWindow.translatesAutoresizingMaskIntoConstraints = false
            msplayerWindow.isHidden = false
            msplayerWindow.windowLevel = UIWindowLevelStatusBar + 1
        }
        return msplayerWindow
    }
    
    fileprivate func setSlideGesture() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(gestureManager?.panAction(_:)))
        floatableType?.floatingView.addGestureRecognizer(gesture)
    }
    
    @objc fileprivate func onOrientationChanged() {
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
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    func prepareToDealloc() {
        removeObserver()
    }
    
    deinit {
        print("class: \(self.classForCoder) dealloc")
    }
}

extension MSFloatingController {
    
    fileprivate func expandViews(isAnimation: Bool = true) {
        //MARK: - set state at animation
        if isAnimation {
            self.state = .animation
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
                self.floatableType!.floatingView.frame = self.floatingViewOriginFrame
                self.floatableType?.floatingView.translatesAutoresizingMaskIntoConstraints = false
                self.msplayerWindow?.frame = self.windowOriginFrame
                self.floatableType!.floatingView.alpha = 1.0
                self.floatableType?.floatingView.layer.borderWidth = 0
            }) { (finished) in
                if let floatingGesture = self.floatingViewTapGesture {
                    self.floatableType!.floatingView.removeGestureRecognizer(floatingGesture)
                }
                self.floatingViewTapGesture = nil
                self.state = .normal
            }
        } else {
            self.floatableType!.floatingView.frame = self.floatingViewOriginFrame
            self.floatableType?.floatingView.translatesAutoresizingMaskIntoConstraints = false
            self.msplayerWindow?.frame = self.windowOriginFrame
            self.floatableType!.floatingView.alpha = 1.0
            self.floatableType?.floatingView.layer.borderWidth = 0
            if let floatingGesture = self.floatingViewTapGesture {
                self.floatableType!.floatingView.removeGestureRecognizer(floatingGesture)
            }
            self.floatingViewTapGesture = nil
            self.state = .normal
        }
    }
    
    fileprivate func shrinkViews() {
        
        // 縮小前將originFrame設定好
        self.floatingViewOriginFrame = self.floatableType?.floatingView.frame ?? CGRect.zero
        
        let yOffset = windowOriginFrame.size.height - self.floatingMinimizedFrame.height
        let xOffset = windowOriginFrame.size.width - self.floatingMinimizedFrame.width
        
        windowMinimizedFrame.origin.y = yOffset
        windowMinimizedFrame.origin.x = xOffset
        windowMinimizedFrame.size.width = self.floatingMinimizedFrame.width
        windowMinimizedFrame.size.height = self.floatingMinimizedFrame.height
        
        //MARK: - 定義浮動視窗的長度
        floatingViewMinimizedFrame.size.width = self.floatingMinimizedFrame.width
        floatingViewMinimizedFrame.size.height = self.floatingMinimizedFrame.height
        
        //MARK: - set state at animation
        self.state = .animation
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            self.floatableType?.floatingView.translatesAutoresizingMaskIntoConstraints = true
            self.floatableType!.floatingView.frame = self.floatingViewMinimizedFrame
            self.msplayerWindow?.frame = self.windowMinimizedFrame
            self.floatableType?.floatingView.layer.borderWidth = 1
            self.floatableType?.floatingView.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        }) { (finished) in
            if let floatingGesture = self.floatingViewTapGesture {
                self.floatableType?.floatingView.removeGestureRecognizer(floatingGesture)
            }
            self.floatingViewTapGesture = nil
            self.floatingViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.expand))
            self.floatableType?.floatingView.addGestureRecognizer(self.floatingViewTapGesture!)
            self.gestureManager?.setSlideGesture()
            
            self.state = .minimum
        }
    }
}






