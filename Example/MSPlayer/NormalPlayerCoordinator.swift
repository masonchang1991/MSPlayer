//
//  NormalPlayerCoordinator.swift
//  MSPlayer_Example
//
//  Created by Mason on 2019/5/29.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

class NormalPlayerCoordinator: Coordinator {
    
    var didFinish: (() -> ())?
    
    var childCoordinator: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let normalVC = NormalPlayerVC()
        self.navigationController.pushViewController(normalVC, animated: false)
    }
}
