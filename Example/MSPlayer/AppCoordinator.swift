//
//  AppCoordinator.swift
//  MSPlayer_Example
//
//  Created by Mason on 2019/5/29.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

class AppCoordinator: Coordinator {
    
    var childCoordinator: [Coordinator] = []
    var navigationController: UINavigationController
    
    private var isBuilding: Bool = true
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.navigationController.setNavigationBarHidden(true, animated: false)
    }
    
    func start() {
        if isBuilding {
            let normalPlayerCoordinator = NormalPlayerCoordinator(navigationController: navigationController)
            childCoordinator.append(normalPlayerCoordinator)
            normalPlayerCoordinator.didFinish = { [weak self, weak normalPlayerCoordinator] in
                guard let self = self,
                    let normalPlayerCoordinator = normalPlayerCoordinator else { return }
                
                for (index, coordinator) in self.childCoordinator.enumerated() {
                    if let coordinator = coordinator as? NormalPlayerCoordinator,
                        coordinator === normalPlayerCoordinator {
                        self.childCoordinator.remove(at: index)
                        coordinator.navigationController.popViewController(animated: false)
                    }
                }
            }
            normalPlayerCoordinator.start()
        } else {
            
        }
    }
    
}
