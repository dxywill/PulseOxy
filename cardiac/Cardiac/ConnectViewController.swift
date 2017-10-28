//
//  ConnectViewController.swift
//  Cardiac
//
//  Created by Eileen Guo on 4/18/17.
//  Copyright © 2017 Eileen Guo. All rights reserved.
//

import Foundation
import UIKit


class ConnectViewController: UIViewController {
    let directoryModel = DirectoryModel.sharedInstance
    let connectivityManager = ConnectivityManager.sharedInstance
    
    let FINISHED_CONNECTING = "finishedConnecting"
    
    @IBOutlet weak var phoneModeLabel: UILabel!
    @IBOutlet weak var connectionsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connectivityManager.delegate = self

    }
    
    override func  viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startApp() {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "home")
        DispatchQueue.main.async {
            self.show(controller!, sender: self)
        }
    }
    
    @IBAction func onPress(_ sender: Any) {
        connectivityManager.send(message: ["action": FINISHED_CONNECTING])
        startApp()
    }
}


extension ConnectViewController : ConnectivityManagerDelegate {
    func didReceive(message: [String:Any]) {
        switch message["action"] as! String {
        case FINISHED_CONNECTING:
            startApp()
        default:
            print("ConnectViewController was unable to parse message")
        }
    }
    
    func connectedDevicesChanged(manager: ConnectivityManager, connectedDevices: [String]) {
        DispatchQueue.main.async {
            self.connectionsLabel.text = "Connections: \(connectedDevices)"
        }
    }
}

