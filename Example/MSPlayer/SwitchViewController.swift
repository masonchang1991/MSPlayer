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

    @IBOutlet weak var tableView: UITableView!

    enum PlayerType: String {
        case onlyPlayer = "Player"
        case normalFloating = "Floating Player"
        case stackFloating = "Floating Player with Navigation Controller"
    }
    
    let types: [PlayerType] = [.onlyPlayer, .normalFloating, .stackFloating]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
}

extension SwitchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return types.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        cell.textLabel?.text = types[indexPath.row].rawValue
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch types[indexPath.row] {
        case .onlyPlayer:
            let normalPlayerVC = NormalPlayerVC()
            self.navigationController?.pushViewController(normalPlayerVC, animated: true)
        case .stackFloating:
            let floatingPlayerVC = StackFloatingPlayerVC()
            MSFloatingController.shared().show(true, floatableVC: floatingPlayerVC)
        default:
            break
        }
    }
    
    
    
}
