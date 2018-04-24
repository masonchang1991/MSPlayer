//
//  MSTimeSlider.swift
//  MSPlayer_Example
//
//  Created by Mason on 2018/4/18.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit

public class MSTimeSlider: UISlider {
    override open func trackRect(forBounds bounds: CGRect) -> CGRect {
        let trackHeigt:CGFloat = bounds.height * 2 / 25
        let position = CGPoint(x: 0 , y: (bounds.height - 1) / 2 - trackHeigt / 2)
        let customBounds = CGRect(origin: position, size: CGSize(width: bounds.size.width, height: trackHeigt))
        super.trackRect(forBounds: customBounds)
        return customBounds
    }
    
    override open func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let rect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        let newx = rect.origin.x - (bounds.width * 0.02)
        let width = bounds.height / 2
        let height = bounds.height / 2
        let newRect = CGRect(x: newx, y: bounds.height / 4, width: width, height: height)
        return newRect
    }
}
