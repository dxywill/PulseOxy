//
//  ConnectivityManager.swift
//  Cardiac
//
//  Created by Eileen Guo on 4/18/17.
//  Copyright © 2017 Eileen Guo. All rights reserved.
//


import Foundation
import MultipeerConnectivity

class ConnectivityManager : NSObject {
    static let sharedInstance = ConnectivityManager()
    
    var delegate:ConnectivityManagerDelegate?
    let directoryModel = DirectoryModel.sharedInstance
    
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    private var advertiser:MCNearbyServiceAdvertiser
    
    private var browser:MCNearbyServiceBrowser
    lazy var session:MCSession = {
        let session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .optional)
        session.delegate = self as! MCSessionDelegate
        return session
    }()
    
    override init() {
        self.browser = MCNearbyServiceBrowser.init(peer: self.myPeerID, serviceType: directoryModel.SERVICE_TYPE)
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: directoryModel.SERVICE_TYPE)
        
        super.init()
        
        self.advertiser.delegate = self
        self.advertiser.startAdvertisingPeer()
        
        self.browser.delegate = self;
        self.browser.startBrowsingForPeers()
    }

    
    deinit {
        self.advertiser.stopAdvertisingPeer()
        self.browser.stopBrowsingForPeers()
    }
    
    func send(message: [String:Any]) {
        if session.connectedPeers.count > 0 {
            NSLog("sending message")
            print(message)
            let data = NSKeyedArchiver.archivedData(withRootObject: message)
            do {
                try self.session.send(data, toPeers: session.connectedPeers, with: .reliable)
            } catch {
                NSLog("Error sending message in connectivity manager")
            }
        }
    }
}

protocol ConnectivityManagerDelegate {
    func didReceive(message:[String:Any])
    func connectedDevicesChanged(manager : ConnectivityManager, connectedDevices: [String])
}


// Advertiser delegate functions
extension ConnectivityManager : MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
}

// Browser delegate functions
extension ConnectivityManager : MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
//
//        if (info!["phoneMode"] != directoryModel.phoneMode && info!["subjectID"] == directoryModel.subjectData["subjectID"] as? String) {
//            print("inviting peer")
//            browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
//        } else {
//            print("peer not matching")
//        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
}

// Helper to get the MCSessionState string
extension MCSessionState {
    func stringValue() -> String {
        switch(self) {
        case .notConnected: return "notConnected"
        case .connecting: return "connecting"
        case .connected: return "connected"
        }
    }
}

// Session delegate functions

extension ConnectivityManager : MCSessionDelegate {

//    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
//
//    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state)")

        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        if let msg = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String:Any] {
            self.delegate?.didReceive(message:msg)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        NSLog("%@", "Did receive certificate")
        certificateHandler(true)
    }
}

