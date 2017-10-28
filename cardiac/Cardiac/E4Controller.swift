//
//  E4ViewController.swift
//  EmpaticaAPIDemo_iOS
//
//  Created by John Politz on 4/26/17.
//  Copyright © 2017 Maurizio Garbarino. All rights reserved.
//

import UIKit

class E4Controller: NSObject, E4Delegate {
    
    let e4 = E4()
    let edm = EmpaticaDeviceManager()
    static let sharedInstance = E4Controller()
    var E4Connected = false
    var apiConnected = false
    var delegate:E4ControllerDelegate?
    var connectDelegate: E4ConnectDelegate?
    
    override init() {
        super.init()
        e4.delegate = self
    }
    
    func authenticate() {
        EmpaticaAPI.authenticate(withAPIKey: "da0c22f6aac74d4d8032be206c64dc34", andCompletionHandler: { (success: Bool, description: String?) -> (Void) in
            if success {
                print("GREAT SUCCESS")
                self.apiConnected = true
                self.connectDelegate?.authSuccess(authenticated: true)
            } else {
                print("FAIL")
                self.apiConnected = false
                self.connectDelegate?.authSuccess(authenticated: false)
            }
        })
    }
    
    func connect() {
        EmpaticaAPI.discoverDevices(with: e4)
    }
    
    func disconnect() {
        edm.disconnect()
    }
    
    func didUpdateE4Status(status: String) {
        if status == "Connected" {
            self.E4Connected = true
            self.delegate?.updateIcon(connected: true)
        } else if status == "Disconnected" {
            self.E4Connected = false
            self.delegate?.updateIcon(connected: false)
        }
        
        print("E4 status: \(status)")
    }
}

protocol E4ControllerDelegate {
    func updateIcon(connected: Bool)
}

protocol E4ConnectDelegate {
    func authSuccess(authenticated: Bool)
}

