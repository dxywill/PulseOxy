//
//  FaceConnectController.swift
//  Cardiac
//
//  Created by Eileen Guo on 4/18/17.
//  Copyright © 2017 Eileen Guo. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class FaceConnectController : NSObject {
    
    var delegate:FaceControllerDelegate?
    let directoryModel = DirectoryModel.sharedInstance
    
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let advertiser:MCNearbyServiceAdvertiser
    
    override init() {
        
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: directoryModel.SERVICE_TYPE)
        super.init()
        self.advertiser.delegate = self
        self.advertiser.startAdvertisingPeer()
    }
    
//    func startBinding() {
//        self.debugger?.debug(message: "Looking for other devices")
//        self.advertiser.startAdvertisingPeer()
//    }
    
//    func stopBinding() {
//        self.advertiser.stopAdvertisingPeer()
//    }
    
    deinit {
        self.advertiser.stopAdvertisingPeer()
    }
}

protocol FaceControllerDelegate {
    func didReceive(message:[String:Any], fromPeer peerID:MCPeerID)
    func didChange(state:MCSessionState, forPeer peerID:MCPeerID)
}


// Advertiser delegate functions
extension FaceConnectController : MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, nil)
    }
}
