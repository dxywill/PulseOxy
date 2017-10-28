//
//  ExperimentNavController.swift
//  Cardiac
//
//  Created by Eileen Guo on 4/20/17.
//  Copyright © 2017 Eileen Guo. All rights reserved.
//

import Foundation

class ExperimentNavController : NSObject {
    
    var delegate: ENCDelegate?
    let directoryModel = DirectoryModel.sharedInstance
    let connectivityManager = ConnectivityManager.sharedInstance
    static let sharedInstance = ExperimentNavController()
    
    override init() {        
        super.init()
        connectivityManager.delegate = self
    }
    
}

protocol  ENCDelegate {
    func performAction(actionDetails: [String:Any])
}

extension ExperimentNavController : ConnectivityManagerDelegate {
    func didReceive(message: [String:Any]) {
        print(self.delegate!)
//        self.delegate?.performAction(message: message)
    }
    
    func connectedDevicesChanged(manager: ConnectivityManager, connectedDevices: [String]) {
        print("Connections: \(connectedDevices)")
    }
}
