//
//  NormalFloatingPlayerVC.swift
//  MSPlayer_Example
//
//  Created by Mason on 2018/6/4.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//


import UIKit
import MSPlayer

class NormalFloatingPlayerVC: UIViewController, MSFloatableViewController, UIGestureRecognizerDelegate {
    
    weak var floatingController: MSFloatingController? =  MSFloatingController.shared()
    
    lazy var floatingView: UIView = MSPlayer()
    
    let createAnotherVCButton = UIButton(type: UIButtonType.system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        createAnotherVCButton.addTarget(self, action: #selector(createAnotherVC), for: .touchUpInside)
        self.setupPlayer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let player = self.floatingView as? MSPlayer {
            player.pause()
        }
    }
    
    func setupView() {
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
        
        createAnotherVCButton.setTitle("Go To Second Video", for: .normal)
    }
    
    func setupPlayer() {
        MSPlayerConfig.playerPanSeekRate = 0.5
        MSPlayerConfig.playerBrightnessChangeRate = 2.0
        MSPlayerConfig.playerVolumeChangeRate = 0.5
        let asset = MSPlayerResource(url: URL(string: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!)
        
        if let player = floatingView as? MSPlayer {
            player.setVideoBy(asset)
        }
        
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
        let floatingPlayerVC = NormalFloatingPlayerVC2()
        MSFloatingController.shared().show(true, floatableVC: floatingPlayerVC)
    }
    
    deinit {
        print("class", self.classForCoder, "dealloc")
    }
}
