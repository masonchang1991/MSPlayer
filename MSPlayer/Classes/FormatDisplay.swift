//
//  FormatDisplay.swift
//  MSPlayer_Example
//
//  Created by Mason on 2018/4/19.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import Foundation

struct FormatDisplay {
    static func formatSecondsToString(_ seconds: TimeInterval) -> String {
        if seconds.isNaN {
            return "00:00"
        }
        let min = Int(floor(seconds) / 60)
        let sec = Int(floor(seconds).truncatingRemainder(dividingBy: 60))
        if min > 60 {
            let hour = Int(floor(Double(min)) / 60)
            let _min = Int(floor(Double(min)).truncatingRemainder(dividingBy: 60))
            return String(format: "%02d:%02d:%02d", hour, _min, sec)
        } else {
            return String(format: "%02d:%02d", min, sec)
        }
    }
}
