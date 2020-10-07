//
//  GestureView.swift
//  MSPlayer
//
//  Created by Mason on 2019/5/29.
//

import Foundation

public enum PanDirection: Equatable {
    public enum PanLocation: Equatable { case left, mid, right }
    public enum PanState: Equatable { case began(CGPoint), changed(CGFloat), ended }
    
    case horizontal
    case vertical(PanLocation)
    
    public static func ==(lhs: PanDirection, rhs: PanDirection) -> Bool {
        switch (lhs, rhs) {
        case let (.vertical(a), .vertical(b)):
            return a == b
        case (.horizontal, .horizontal):
            return true
        default:
            return false
        }
    }
}

public protocol GestureView {
    func verticalPanEvent(_ state: PanDirection.PanState, location: PanDirection.PanLocation)
    func horizontalPanEvent(_ state: PanDirection.PanState)
    func disableGesture()
    func resumeGesture()
}

open class MSGestureView: UIView, GestureView {
    
    typealias PanState = PanDirection.PanState
    typealias PanLocation = PanDirection.PanLocation
    
    private var panGesture: UIPanGestureRecognizer?
    private var panDirection: PanDirection = .horizontal
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setGesture()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panDirection(_:)))
        self.panGesture = panGesture
        self.addGestureRecognizer(panGesture)
    }
    
    private func panEventWith(panState: PanDirection.PanState) {
        switch self.panDirection {
        case .horizontal:
            horizontalPanEvent(panState)
        case .vertical(let location):
            switch location {
            case .left:
                verticalPanEvent(panState, location: .left)
            case .mid:
                verticalPanEvent(panState, location: .mid)
            case .right:
                verticalPanEvent(panState, location: .right)
            }
        }
    }
    
    // MARK: - Action response
    @objc private func panDirection(_ pan: UIPanGestureRecognizer) {
        // 根據上次跟這次的移動，算出滑動速度以及方向
        // 根據在view上pan的位置，確定是條音量還是亮度
        let locationPoint = pan.location(in: self)
        // 水平移動更改進度條，垂直移動更改音量或亮度
        let velocityPoint = pan.velocity(in: self)
        
        switch pan.state {
        case .began:
            // 使用絕對值來判斷移動的方向
            let x = abs(velocityPoint.x)
            let y = abs(velocityPoint.y)
            
            // horizontal
            if x > y {
                panDirection = .horizontal
                panEventWith(panState: .began(locationPoint))
            } else {
                // vertical
                if locationPoint.x < self.bounds.size.width / 3 {
                    panDirection = .vertical(.left)
                } else if locationPoint.x > self.bounds.size.width / 3 && locationPoint.x < self.bounds.size.width * 2 / 3 {
                    panDirection = .vertical(.mid)
                } else {
                    panDirection = .vertical(.right)
                }
                panEventWith(panState: .began(locationPoint))
            }
            
        case .changed:
            switch self.panDirection {
            case .horizontal:
                panEventWith(panState: .changed(velocityPoint.x))
            case .vertical:
                panEventWith(panState: .changed(velocityPoint.y))
            }
            
        case .ended:
            panEventWith(panState: .ended)
        default:
            break
        }
    }
    
    open func verticalPanEvent(_ state: PanDirection.PanState, location: PanDirection.PanLocation) {
        
    }
    
    open func horizontalPanEvent(_ state: PanDirection.PanState) {
        
    }
    
    open func disableGesture() {
        if let panGesture = panGesture {
            panGesture.isEnabled = false
        }
    }
    
    open func resumeGesture() {
        if let panGesture = panGesture {
            panGesture.isEnabled = true
        }
    }
}
