//
//  FloatingPlayerViewController2.swift
//  MSPlayer_Example
//
//  Created by Mason on 2018/5/21.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import MSPlayer

class FloatingPlayerViewController2: UIViewController, MSFloatableViewController {
    
    weak var floatingController: MSFloatingController? =  MSFloatingController.shared()
    
    var floatingView: UIView = MSPlayer()
    
    let createAnotherVCButton = UIButton(type: UIButtonType.system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.view.addSubview(floatingView)
        floatingView.translatesAutoresizingMaskIntoConstraints = false
        floatingView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        floatingView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        floatingView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        floatingView.heightAnchor.constraint(equalTo: self.floatingView.widthAnchor, multiplier: (9/16)).isActive = true
        self.view.addSubview(createAnotherVCButton)
        createAnotherVCButton.translatesAutoresizingMaskIntoConstraints = false
        createAnotherVCButton.topAnchor.constraint(equalTo: self.floatingView.bottomAnchor).isActive = true
        createAnotherVCButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        createAnotherVCButton.widthAnchor.constraint(equalToConstant: 250.0).isActive = true
        createAnotherVCButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        
        createAnotherVCButton.setTitle("Go To first Video", for: .normal)
//        createAnotherVCButton.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        createAnotherVCButton.addTarget(self, action: #selector(createAnotherVC), for: .touchUpInside)
        
        
        MSPlayerConfig.playerPanSeekRate = 0.5
        MSPlayerConfig.playerBrightnessChangeRate = 2.0
        MSPlayerConfig.playerVolumeChangeRate = 0.5
        let asset = MSPlayerResource(url: URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!)
        
        if let player = floatingView as? MSPlayer {
            player.setVideoBy(asset)
        }
        self.floatingController?.closeFloatingVC = { [weak self] in
            if let player = self?.floatingView as? MSPlayer {
                player.prepareToDealloc()
            }
        }
        
        self.floatingController?.shrinkFloatingVC = { [weak self] in
            if let player = self?.floatingView as? MSPlayer {
                player.closeControlViewAndRemoveGesture()
            }
            self?.createAnotherVCButton.isHidden = true
        }
        
        self.floatingController?.expandFloatingVC = { [weak self] in
            if let player = self?.floatingView as? MSPlayer {
                player.openControlViewAndSetGesture()
            }
            self?.createAnotherVCButton.isHidden = false
        }
    }
    
    func createAnotherVC() {
        let floatingPlayerVC = FloatingPlayerViewController()
        MSFloatingController.shared().show(true, floatableVC: floatingPlayerVC)
    }
    
    
    deinit {
        print("class", self.classForCoder, "dealloc")
    }
}
