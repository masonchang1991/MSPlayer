//
//  MSFloatingGestureManager.swift
//  MSPlayer
//
//  Created by Mason on 2018/5/17.
//

import Foundation

class MSFloatingGestureManager: NSObject {
    
    enum PanDirection {
        case `unknown`
        case up
        case down
        case left
        case right
    }
    
    weak var floatingController: MSFloatingController!
    
    var panDirection: PanDirection?
    var touchPositionStartY: CGFloat = 0.0
    var touchPositionStartX: CGFloat = 0.0
    var floatingView: UIView?
    var panGesture: UIPanGestureRecognizer?
    
    init(floatingController: MSFloatingController) {
        self.floatingController = floatingController
    }
    
    func setSlideGesture() {
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        self.floatingController.floatableType?.floatingView.addGestureRecognizer(self.panGesture!)
    }
    
    @objc func panAction(_ recognizer: UIPanGestureRecognizer) {
        // 根據外面 Keywindow
        let floatinViewLocation = recognizer.location(in: UIApplication.shared.keyWindow)
        let a = recognizer.location(in: recognizer.view)
        
        switch recognizer.state {
        case .began:
            panActionBeganWith(location: floatinViewLocation, recognizer: recognizer)
        case .changed:
            panActionStateChanged(location: floatinViewLocation, recognizer: recognizer)
        case .ended:
            panActionStateEnded(location: floatinViewLocation, recognizer: recognizer)
        default:
            break
        }
    }
    
    func panActionBeganWith(location: CGPoint, recognizer: UIPanGestureRecognizer) {
        //TODO: - 通知外面滑動開始
        
        panDirection = PanDirection.unknown
        
        let velocity = recognizer.velocity(in: recognizer.view)
        detectPanDirection(velocity: velocity)
        
        touchPositionStartY = recognizer.location(in: self.floatingView).y
        touchPositionStartX = recognizer.location(in: self.floatingView).x
    }
    
    func panActionStateChanged(location: CGPoint, recognizer: UIPanGestureRecognizer) {
        //TODO: - 通知外面滑動變更
        
        // floatingView的原點 == 你點擊的位置 - 點擊在floatingView上面的y
        var nextYPosition: CGFloat = 0.0
        if (location.y - touchPositionStartY) <= 5 {
            nextYPosition = 5.0
        } else if (location.y - touchPositionStartY + floatingController.windowMinimizedFrame.height) > UIScreen.main.bounds.height {
            nextYPosition = UIScreen.main.bounds.height - floatingController.windowMinimizedFrame.height - 5.0
        } else {
            nextYPosition = location.y - touchPositionStartY
        }
        
        var nextXPosition: CGFloat = 0.0
        if (location.x - touchPositionStartX) <= 5 {
            nextXPosition = 5.0
        } else if (location.x - touchPositionStartX + floatingController.windowMinimizedFrame.width) > UIScreen.main.bounds.width {
            nextXPosition = UIScreen.main.bounds.width - floatingController.windowMinimizedFrame.width - 5.0
        } else {
            nextXPosition = location.x - touchPositionStartX
        }
        
        let nextLocation = CGPoint(x: nextXPosition, y: nextYPosition)
        adjustPanWith(location: location, nextLocation: nextLocation, recognizer: recognizer)
    }
    
    func panActionStateEnded(location: CGPoint, recognizer: UIPanGestureRecognizer) {

        let velocity = recognizer.velocity(in: UIApplication.shared.keyWindow)
        let adjustVelocity = CGPoint(x: velocity.x / 4, y: velocity.y / 4)
        var toBeDissmiss: Bool = false
        
        var nextYPosition: CGFloat = 0.0
        if fabs(adjustVelocity.y) > 850 {
            toBeDissmiss = true
            nextYPosition = location.y + adjustVelocity.y
        } else if (location.y + adjustVelocity.y - touchPositionStartY) <= 5 {
            nextYPosition = 5.0
        } else if (location.y + adjustVelocity.y - touchPositionStartY + floatingController.windowMinimizedFrame.height) > UIScreen.main.bounds.height {
            nextYPosition = UIScreen.main.bounds.height - floatingController.windowMinimizedFrame.height - 5.0
        } else {
            nextYPosition = location.y + adjustVelocity.y - touchPositionStartY
        }
        
        var nextXPosition: CGFloat = 0.0
        if fabs(adjustVelocity.x) > 850 {
            toBeDissmiss = true
            nextXPosition = location.x + adjustVelocity.x
        } else if (location.x + adjustVelocity.x - touchPositionStartX) <= 5 {
            nextXPosition = 5.0
        } else if (location.x + adjustVelocity.x - touchPositionStartX + floatingController.windowMinimizedFrame.width) > UIScreen.main.bounds.width {
            nextXPosition = UIScreen.main.bounds.width - floatingController.windowMinimizedFrame.width - 5.0
        } else {
            nextXPosition = location.x + adjustVelocity.x - touchPositionStartX
        }
        
        let nextLocation = CGPoint(x: nextXPosition, y: nextYPosition)
        endPanAnimation(endLoaction: nextLocation, recognizer: recognizer, isDissmiss: toBeDissmiss)
    }
    
    func adjustPanWith(location: CGPoint, nextLocation: CGPoint, recognizer: UIPanGestureRecognizer) {
        
        //Use this to adjust the position of your view accordingly
        floatingController.windowMinimizedFrame.origin = nextLocation
        UIView.animate(withDuration: 0.1, delay: 0.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            self.floatingController.msplayerWindow?.frame = self.floatingController.windowMinimizedFrame
            //TODO: - change alpha
        }, completion: nil)
        
        recognizer.setTranslation(CGPoint.zero, in: recognizer.view)
    }
    
    func endPanAnimation(endLoaction: CGPoint, recognizer: UIPanGestureRecognizer, isDissmiss: Bool) {
        
        //Use this to adjust the position of your view accordingly
        floatingController.windowMinimizedFrame.origin = endLoaction
        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.floatingController.msplayerWindow?.frame = self.floatingController.windowMinimizedFrame
            //TODO: - change alpha
        }, completion: { (_) in
            if isDissmiss {
                self.floatingController.close()
            }
        })
        recognizer.setTranslation(CGPoint.zero, in: recognizer.view)
    }
    
    func detectHorizontalPanViewAlpha(x: CGFloat, velocity: CGPoint) -> CGFloat {
        let percentage = x / self.floatingController.windowOriginFrame.size.width
        
        if panDirection == PanDirection.left {
            return percentage
        } else {
            if velocity.x > 0 {
                return 1.0 - percentage
            } else {
                return percentage
            }
        }
    }
    
    func detectPanDirection(velocity: CGPoint) {
        
        let isVertical = fabs(velocity.y) > fabs(velocity.x)
        if (isVertical) {
            
            if velocity.y > 0 {
                panDirection = PanDirection.down
            } else {
                panDirection = PanDirection.up
            }
            
        } else {
            
            if velocity.x > 0 {
                panDirection = PanDirection.right
            } else {
                panDirection = PanDirection.left
            }
        }
    }
    
    func animateViewToRightOrLeft(recognizer: UIPanGestureRecognizer) {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.floatingController.msplayerWindow?.frame = self.floatingController.windowMinimizedFrame
            if let floatingVC = self.floatingController.floatableType as? UIViewController {
                floatingVC.view.alpha = 1.0
            }
        }, completion: nil)
        
        recognizer.setTranslation(CGPoint.zero, in: recognizer.view)
    }
    
    deinit {
        print("class: \(self.classForCoder) dealloc")
    }
}
