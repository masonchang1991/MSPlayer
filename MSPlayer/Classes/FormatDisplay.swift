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
        let min = Int(seconds / 60)
        let sec = Int(seconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", min, sec)
    }
}
