//
//  MSFloatingViewController.swift
//  MSPlayer
//
//  Created by Mason on 2018/5/16.
//

import Foundation

public protocol MSFloatableViewController {
    var floatingController: MSFloatingController? { get set }
    var floatingView: UIView { get set }
}
