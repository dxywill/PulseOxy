//
//  BodyConnectController.swift
//  Cardiac
//
//  Created by Eileen Guo on 4/18/17.
//  Copyright © 2017 Eileen Guo. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class BodyConnectController : NSObject {
    
    let directoryModel = DirectoryModel.sharedInstance
    
    var delegate:BodyControllerDelegate?
    
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let browser:MCNearbyServiceBrowser
    lazy var session:MCSession = {
        let session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .optional)
        session.delegate = self
        return session
    }()
    
    override init() {
        self.browser = MCNearbyServiceBrowser.init(peer: self.myPeerID, serviceType: directoryModel.SERVICE_TYPE)
        
        super.init()
        
        self.browser.delegate = self;
        self.browser.startBrowsingForPeers()
    }
    
//    func startBinding() {
//        self.debugger?.debug(message: "Looking for other devices")
//        self.browser.startBrowsingForPeers()
//    }
    
//    func stopBinding() {
//        self.browser.stopBrowsingForPeers()
//    }
    
    deinit {
        self.browser.stopBrowsingForPeers()
    }
    
    func send(message: [String:Any]) {
        if session.connectedPeers.count > 0 {
            NSLog("sending message")
            let data = NSKeyedArchiver.archivedData(withRootObject: message)
            do {
                try self.session.send(data, toPeers: session.connectedPeers, with: .reliable)
            } catch {
                NSLog("Error sending message in connectivity manager")
            }
        }
        
        NSLog("No peerIDs to send message to")
    }
    
}

protocol BodyControllerDelegate {
    func didReceive(message:[String:Any], fromPeer peerID:MCPeerID)
    func didChange(state:MCSessionState, forPeer peerID:MCPeerID)
    func connectedDevicesChanged(manager : BodyConnectController, connectedDevices: [String])
}

// Browser delegate functions
extension BodyConnectController : MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
}

//// Helper to get the MCSessionState string
//extension MCSessionState {
//    func stringValue() -> String {
//        switch(self) {
//        case .notConnected: return "notConnected"
//        case .connecting: return "connecting"
//        case .connected: return "connected"
//        }
//    }
//}

// Session delegate functions
extension BodyConnectController : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state)")
        self.delegate?.didChange(state: state, forPeer: peerID)
        
        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        if let msg = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String:Any] {
            self.delegate?.didReceive(message:msg, fromPeer: peerID)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
//    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
//        self.debugger?.debug(message:"Did receive certificate")
//        
//        certificateHandler(true)
//    }
}
