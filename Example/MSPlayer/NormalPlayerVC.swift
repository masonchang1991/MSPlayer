//
//  ViewController.swift
//  MSPlayer
//
//  Created by masonchang1991 on 04/18/2018.
//  Copyright (c) 2018 masonchang1991. All rights reserved.
//

import UIKit
//import MSPlayer
import MediaPlayer
import AVKit

class NormalPlayerVC: UIViewController {

    lazy var player =  {
        return MSPlayer()
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.view.addSubview(player)
        player.delegate = self
        player.translatesAutoresizingMaskIntoConstraints = false
        player.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        player.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        player.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        player.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 9 / 16).isActive = true
        MSPlayerConfig.playerPanSeekRate = 0.5
        MSPlayerConfig.playerBrightnessChangeRate = 2.0
        MSPlayerConfig.playerVolumeChangeRate = 0.5
        let asset = MSPlayerResource(url: URL(string: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!)
        player.setVideoBy(asset)
        
        player.backBlock = { [weak self] (isFullScreen) in
            if isFullScreen == true { return }
            self?.navigationController?.popViewController(animated: false)
        }
        player.showBlock = { [weak self] (sure) in
            UIApplication.shared.keyWindow?.rootViewController?.navigationController?.pushViewController(self!, animated: true)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        print("viewController dealloc")
    }

}

extension NormalPlayerVC: MSPlayerDelegate {
    func msPlayer(_ player: MSPlayer, stateDidChange state: MSPM.State) {
        
    }
    
    func msPlayer(_ player: MSPlayer, loadTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        
    }
    
    func msPlayer(_ player: MSPlayer, playTimeDidChange current: TimeInterval, total: TimeInterval) {
        
    }
    
    func msPlayer(_ player: MSPlayer, isPlaying: Bool) {
        
    }
    
    func msPlayer(_ player: MSPlayer, orientChanged isFullScreen: Bool) {
        
    }
    
    
}

