//
//  MSFloatingViewController.swift
//  MSPlayer
//
//  Created by Mason on 2018/5/16.
//

import Foundation
import UIKit
public protocol MSFloatableViewController {
    var floatingController: MSFloatingController? { get set }
    var floatingPlayer: MSPlayer { get set }
}


