//
//  FloatingPlayerViewController2.swift
//  MSPlayer_Example
//
//  Created by Mason on 2018/5/21.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import MSPlayer

class StackFloatingPlayerVC2: UIViewController, MSFloatableViewController, UIGestureRecognizerDelegate {
    
    weak var floatingController: MSFloatingController? =  MSStackFloatingController.shared()
    
    var player = MSPlayer()
    
    let createAnotherVCButton = UIButton(type: UIButtonType.system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.setupView()
        createAnotherVCButton.addTarget(self, action: #selector(createAnotherVC), for: .touchUpInside)
        self.setupPlayer()
        
        // setup popNav gesture
        let target = self.navigationController?.interactivePopGestureRecognizer?.delegate
        let pan = UIPanGestureRecognizer(target: target,
                                         action: Selector(("handleNavigationTransition:")))
        pan.delegate = self
        self.view.addGestureRecognizer(pan)
        //同时禁用系统原先的侧滑返回功能
        self.navigationController?.interactivePopGestureRecognizer!.isEnabled = false
    }
  
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //MARK: - set this vc to be current (must), if you don't setToCurrent, then you can do anything about this floatingVC
        if let stackFloatingController = self.floatingController as? MSStackFloatingController {
            stackFloatingController.setToCurrentFloatingVC(self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
    }
    
    func setupView() {
        self.view.backgroundColor = UIColor.white
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.view.addSubview(player)
        player.translatesAutoresizingMaskIntoConstraints = false
        player.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        player.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        player.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        player.heightAnchor.constraint(equalTo: self.player.widthAnchor, multiplier: (9/16)).isActive = true
        
        self.view.addSubview(createAnotherVCButton)
        createAnotherVCButton.translatesAutoresizingMaskIntoConstraints = false
        createAnotherVCButton.topAnchor.constraint(equalTo: self.player.bottomAnchor).isActive = true
        createAnotherVCButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        createAnotherVCButton.widthAnchor.constraint(equalToConstant: 250.0).isActive = true
        createAnotherVCButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        
        createAnotherVCButton.setTitle("Go To Second Video", for: .normal)
    }
    
    func setupPlayer() {
        MSPlayerConfig.playerPanSeekRate = 0.5
        MSPlayerConfig.playerBrightnessChangeRate = 2.0
        MSPlayerConfig.playerVolumeChangeRate = 0.5
        let asset = MSPlayerResource(url: URL(string: "http://184.72.239.149/vod/smil:BigBuckBunny.smil/playlist.m3u8")!)
        
        player.setVideoBy(asset)
        
        //MARK: - Do something when floatingVC being closed
        self.floatingController?.closeFloatingVC = { [weak self] in
            
        }
        
        //MARK: - Do something when floatingVC being shrinked
        self.floatingController?.shrinkFloatingVC = { [weak self] in
            self?.createAnotherVCButton.isHidden = true
        }
        
        //MARK: - Do something when floatingVC being expanded
        self.floatingController?.expandFloatingVC = { [weak self] in
            self?.createAnotherVCButton.isHidden = false
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if self.navigationController?.viewControllers.count == 1 {
            return false
        } else {
            return true
        }
    }
    
    func createAnotherVC() {
        let floatingPlayerVC = StackFloatingPlayerVC()
        MSFloatingController.shared().show(true, floatableVC: floatingPlayerVC)
    }
    
    deinit {
        print("class", self.classForCoder, "dealloc")
    }
}
