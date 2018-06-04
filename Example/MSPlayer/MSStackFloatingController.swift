//
//  MSStackFloatingController.swift
//  MSPlayer
//
//  Created by Mason on 2018/5/29.
//

import Foundation
import UIKit

public class MSStackFloatingController: MSFloatingController {
    
    public override var type: MSFloatingType {
        get {
            return .stack
        }
        set(value) {
            self.type = value
        }
    }
    
    override public class func shared() -> MSFloatingController {
        if self.sharedInstance == nil {
            self.sharedInstance = MSStackFloatingController()
        }
        return self.sharedInstance ?? MSStackFloatingController()
    }
    
    internal var floatNavigationController: UINavigationController?
    internal var panGestureDirection: UIPanGestureRecognizerDirection?
    internal var touchPositionStartY: CGFloat?
    internal var touchPositionStartX: CGFloat?
    
    enum UIPanGestureRecognizerDirection {
        case Undefined
        case Up
        case Down
        case Left
        case Right
    }
    
    override public func show(_ animated: Bool, frame: CGRect, floatableVC: MSFloatableViewController) {
        
        if self.floatNavigationController == nil {
            
            guard let floatableViewController = floatableVC as? UIViewController else { return }
            self.floatNavigationController = UINavigationController(rootViewController: floatableViewController)
            self.floatableType = floatableVC
            self.windowOriginFrame = frame
            self.state = .normal
            self.setGesture()
            changePlayerBackImage(toDown: true)
            
            guard
                let msplayerWindow = createCustomWindowWith(frame),
                let floatableVC = floatableType as? UIViewController else {
                    return
            }
            // set connection between controller and VC
            msplayerWindow.rootViewController = self.floatNavigationController
            floatableType?.floatingController = self
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
            
            switch state {
                
            case .minimum:
                expand()
                fallthrough
            case .normal:
                guard let floatableViewController = floatableVC as? UIViewController else {
                    print("fail")
                    return
                }
                self.floatNavigationController?.pushViewController(floatableViewController, animated: true)
                self.floatableType = floatableVC
                self.floatableType?.floatingController = self
            default:
                break
            }
        }
    }
    
    func setGesture() {
        //MARK: - shrink window
        //        let changeFrameGesture = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        //        self.floatableType?.floatingView.addGestureRecognizer(changeFrameGesture)
    }
    
    @objc func panAction(_ recognizer: UIPanGestureRecognizer) {
        let yPlayerLocation = recognizer.location(in: UIApplication.shared.keyWindow).y
        
        switch recognizer.state {
        case .began:
            onRecognizerStateBegan(yPlayerLocation: yPlayerLocation, recognizer: recognizer)
            break
        case .changed:
            onRecognizerStateChanged(yPlayerLocation: yPlayerLocation, recognizer: recognizer)
            break
        default:
            onRecognizerStateEnded(yPlayerLocation: yPlayerLocation, recognizer: recognizer)
        }
    }
    
    func onRecognizerStateBegan(yPlayerLocation: CGFloat, recognizer: UIPanGestureRecognizer) {
        self.floatableType?.player.closeControlViewAndRemoveGesture()
        panGestureDirection = UIPanGestureRecognizerDirection.Undefined
        
        let velocity = recognizer.velocity(in: recognizer.view)
        detectPanDirection(velocity: velocity)
        
        touchPositionStartY = recognizer.location(in: self.floatableType?.player).y
        touchPositionStartX = recognizer.location(in: self.floatableType?.player).x
    }
    
    func onRecognizerStateChanged(yPlayerLocation: CGFloat, recognizer: UIPanGestureRecognizer) {
        if (panGestureDirection == UIPanGestureRecognizerDirection.Down ||
            panGestureDirection == UIPanGestureRecognizerDirection.Up) {
            let trueOffset = yPlayerLocation - touchPositionStartY!
            let xOffset = trueOffset * 0.35
            print("trueOffset:", trueOffset, "xOffset:", xOffset)
            adjustViewOnVerticalPan(yPlayerLocation: yPlayerLocation, trueOffset: trueOffset, xOffset: xOffset, recognizer: recognizer)
            
        }
    }
    
    func onRecognizerStateEnded(yPlayerLocation: CGFloat, recognizer: UIPanGestureRecognizer) {
        if (panGestureDirection == UIPanGestureRecognizerDirection.Down ||
            panGestureDirection == UIPanGestureRecognizerDirection.Up) {
            if ((self.msplayerWindow?.frame.origin.y)! < 0) {
                expandViews()
                recognizer.setTranslation(CGPoint.zero, in: recognizer.view)
                return
                
            } else {
                if ((self.msplayerWindow?.frame.origin.y)! > (UIScreen.main.bounds.height / 2)) {
                    shrinkViews()
                    recognizer.setTranslation(CGPoint.zero, in: recognizer.view)
                    return
                } else {
                    expandViews()
                    recognizer.setTranslation(CGPoint.zero, in: recognizer.view)
                }
            }
        }
    }
    
    func adjustViewOnVerticalPan(yPlayerLocation: CGFloat, trueOffset: CGFloat, xOffset: CGFloat, recognizer: UIPanGestureRecognizer) {
        
        //Use this offset to adjust the position of your view accordingly
        let changePosition = CGPoint(x: xOffset, y: trueOffset)
        
        var windowFrame = self.windowOriginFrame
        windowFrame.size.width = windowFrame.width - xOffset
        windowFrame.size.height = windowFrame.height - trueOffset
        windowFrame.origin = changePosition
        
        var floatingViewFrame = self.floatableType?.player.frame ?? CGRect.zero
        floatingViewFrame.size.width = self.windowOriginFrame.width - xOffset
        floatingViewFrame.size.height = floatingViewFrame.size.width * 9 / 16
        
        UIView.animate(withDuration: 0.09, delay: 0.0, options: .curveEaseInOut, animations: {
            self.floatableType?.player.frame = floatingViewFrame
            self.msplayerWindow?.frame = windowFrame
            
        }, completion: nil)
        
        recognizer.setTranslation(CGPoint.zero, in: recognizer.view)
    }
    
    func detectPanDirection(velocity: CGPoint) {
        let isVerticalGesture = fabs(velocity.y) > fabs(velocity.x)
        
        if (isVerticalGesture) {
            
            if (velocity.y > 0) {
                panGestureDirection = UIPanGestureRecognizerDirection.Down
            } else {
                panGestureDirection = UIPanGestureRecognizerDirection.Up
            }
            
        } else {
            
            if (velocity.x > 0) {
                panGestureDirection = UIPanGestureRecognizerDirection.Right
            } else {
                panGestureDirection = UIPanGestureRecognizerDirection.Left
            }
        }
    }
    
    //MARK: - you can use this to pop from nav
    public func popFromNav() {
        self.closeFloatingVC?()
        self.floatNavigationController?.popViewController(animated: true)
        // 前一個controller
        if let floatableVC =  self.floatNavigationController?.viewControllers.last as? MSFloatableViewController {
            self.setToCurrentFloatingVC(floatableVC)
        }
    }
    
    //MARK: - when ur using type is stack, you must call this to vc.viewWillAppear to change current floatingController's floatingVC
    public func setToCurrentFloatingVC(_ currentVC: MSFloatableViewController) {
        self.floatableType = currentVC
    }
}

