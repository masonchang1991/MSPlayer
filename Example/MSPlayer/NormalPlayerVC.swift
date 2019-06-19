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
        
        MSPlayerConfig.shouldAutoPlay = true
        MSPlayerConfig.playerPanSeekRate = 0.5
        MSPlayerConfig.playerBrightnessChangeRate = 2.0
        MSPlayerConfig.playerVolumeChangeRate = 0.5
        
        let playNextView = PlayNextView(frame: CGRect(origin: .zero, size: CGSize(width: 118, height: 56)))
//        MSPlayerConfig.playNextView = playNextView
        
        setupView()
        setupPlayer()
        
        
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
        
        let urlR = URLRequest(url: URL(string: "https://i.ytimg.com/vi/MhQKe-aERsU/maxresdefault.jpg")!)
        
        let d1 = MSPlayerResourceDefinition(videoId: "123",
                                            videoName: "aaa",
                                            url: URL(string: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!,
                                            definition: "test",
                                            coverURLRequest: urlR)
        
        let d2 = MSPlayerResourceDefinition(videoId: "wwwwweeqe",
                                            videoName: "aaa2",
                                            url: URL(string: "http://184.72.239.149/vod/smil:BigBuckBunny.smil/playlist.m3u8")!,
                                            definition: "test",
                                            coverURLRequest: urlR)
        
        let asset = MSPlayerResource(definitions: [d1, d2])
        
        player.setVideoBy(asset)
        
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

