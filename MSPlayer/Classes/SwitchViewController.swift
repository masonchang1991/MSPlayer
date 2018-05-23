//
//  SwitchViewController.swift
//  MSPlayer_Example
//
//  Created by Mason on 2018/5/17.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import MSPlayer

class SwitchViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func showFloatingPlayer(_ sender: Any) {
        
        // Create VC
        let floatingPlayerVC = FloatingPlayerViewController()
        MSFloatingController.shared().show(true, floatableVC: floatingPlayerVC)
        
    }
}
