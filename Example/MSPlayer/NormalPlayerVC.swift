//
//  ViewController.swift
//  MSPlayer
//
//  Created by masonchang1991 on 04/18/2018.
//  Copyright (c) 2018 masonchang1991. All rights reserved.
//

import UIKit
import MSPlayer
import MediaPlayer
import AVKit

class NormalPlayerVC: UIViewController {

    lazy var player =  {
        return MSPlayer()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        setupView()
        setupPlayer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.player.seekByAddValue(100)
        }
    }
    
    func setupView() {
        view.addSubview(player)
        player.translatesAutoresizingMaskIntoConstraints = false
        player.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        player.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        player.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        player.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 9 / 16).isActive = true
        
    }
    
    func setupPlayer() {
        player.delegate = self
        
        MSPlayerConfig.shouldAutoPlay = true
        MSPlayerConfig.playerPanSeekRate = 0.5
        MSPlayerConfig.playerBrightnessChangeRate = 2.0
        MSPlayerConfig.playerVolumeChangeRate = 0.5
        let asset = MSPlayerResource(
            url: URL(string: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!,
            name: "test",
            coverURL: URL(string: "https://i.ytimg.com/vi/MhQKe-aERsU/maxresdefault.jpg")!,
            coverURLRequestHeaders: nil)
        
        player.setVideoBy(asset, videoIdForRecord: "001")
        
        player.backBlock = { [weak self] (isFullScreen) in
            guard let self = self else { return }
            if isFullScreen == true { return }
            self.navigationController?.popViewController(animated: false)
        }
    }
    
    deinit {
        print(classForCoder, "dealloc")
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

