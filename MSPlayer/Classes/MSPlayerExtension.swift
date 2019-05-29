//
//  MSPlayerExtension.swift
//  MSPlayer_Example
//
//  Created by Mason on 2018/4/19.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

public enum ConstraintAnchorType {
    case leading2Leading(CGFloat, priority: Float)
    case leading2Trailing(CGFloat, priority: Float)
    case trailing2Trailing(CGFloat, priority: Float)
    case trailing2Leading(CGFloat, priority: Float)
    case top2Top(CGFloat, priority: Float)
    case top2Bottom(CGFloat, priority: Float)
    case bottom2Bottom(CGFloat, priority: Float)
    case bottom2Top(CGFloat, priority: Float)
    case centerX2CenterX(CGFloat, priority: Float)
    case centerY2CenterY(CGFloat, priority: Float)
    case height(CGFloat, priority: Float)
    case width(CGFloat, priority: Float)
    case height2Height(Double, priority: Float)
    case height2Width(Double, priority: Float)
    case width2Width(Double, priority: Float)
    case width2Height(Double, priority: Float)
    case edge2Edge
}

extension UIView {
    open func addConstraintWithOther(_ otherView: UIView, anchorTypes: [ConstraintAnchorType], active: Bool = true) {
        
        anchorTypes.forEach({
            switch $0 {
            case .bottom2Bottom(let constant, let priority):
                let cs = bottomAnchor.constraint(equalTo: otherView.bottomAnchor, constant: constant)
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .bottom2Top(let constant, let priority):
                let cs = bottomAnchor.constraint(equalTo: otherView.topAnchor, constant: constant)
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .leading2Leading(let constant, let priority):
                let cs = leadingAnchor.constraint(equalTo: otherView.leadingAnchor, constant: constant)
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .leading2Trailing(let constant, let priority):
                let cs = leadingAnchor.constraint(equalTo: otherView.trailingAnchor, constant: constant)
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .top2Top(let constant, let priority):
                let cs = topAnchor.constraint(equalTo: otherView.topAnchor, constant: constant)
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .top2Bottom(let constant, let priority):
                let cs = topAnchor.constraint(equalTo: otherView.bottomAnchor, constant: constant)
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .trailing2Trailing(let constant, let priority):
                let cs = trailingAnchor.constraint(equalTo: otherView.trailingAnchor, constant: constant)
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .trailing2Leading(let constant, let priority):
                let cs = trailingAnchor.constraint(equalTo: otherView.leadingAnchor, constant: constant)
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .centerX2CenterX(let constant, let priority):
                let cs = centerXAnchor.constraint(equalTo: otherView.centerXAnchor, constant: constant)
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .centerY2CenterY(let constant, let priority):
                let cs = centerYAnchor.constraint(equalTo: otherView.centerYAnchor, constant: constant)
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .height(let constant, let priority):
                let cs = heightAnchor.constraint(equalToConstant: constant)
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .width(let constant, let priority):
                let cs = widthAnchor.constraint(equalToConstant: constant)
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .height2Height(let mutiplier, let priority):
                let cs = heightAnchor.constraint(equalTo: otherView.heightAnchor, multiplier: CGFloat(mutiplier))
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .height2Width(let mutiplier, let priority):
                let cs = heightAnchor.constraint(equalTo: otherView.widthAnchor, multiplier: CGFloat(mutiplier))
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .width2Width(let mutiplier, let priority):
                let cs = widthAnchor.constraint(equalTo: otherView.widthAnchor, multiplier: CGFloat(mutiplier))
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .width2Height(let mutiplier, let priority):
                let cs = widthAnchor.constraint(equalTo: otherView.heightAnchor, multiplier: CGFloat(mutiplier))
                cs.priority = UILayoutPriority(rawValue: priority)
                cs.isActive = active
            case .edge2Edge:
                bottomAnchor.constraint(equalTo: otherView.bottomAnchor).isActive = active
                topAnchor.constraint(equalTo: otherView.topAnchor).isActive = active
                leadingAnchor.constraint(equalTo: otherView.leadingAnchor).isActive = active
                trailingAnchor.constraint(equalTo: otherView.trailingAnchor).isActive = active
            }
        })
    }
}
