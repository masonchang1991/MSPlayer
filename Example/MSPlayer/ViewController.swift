//
//  ViewController.swift
//  MSPlayer
//
//  Created by masonchang1991 on 04/18/2018.
//  Copyright (c) 2018 masonchang1991. All rights reserved.
//

import UIKit


class ViewController: UIViewController {

    let player = MSPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        self.view.addSubview(player)
        player.translatesAutoresizingMaskIntoConstraints = false
        player.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        player.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        player.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        player.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        let asset = MSPlayerResource(url: URL(string: "https://bplay01.com/static2/JDXA_56877.m3u8?data=NDI2ZFGhCNqTvfLZFs1UiZ4Uqm9nquCK-0i6_IayWQCZd2rUMTNi&token=zVVEPpvRW9tXx1gC-s_CgQ&expires=1524553640")!)
        player.setVideoBy(asset)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

