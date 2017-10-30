//
//  PulseOximeterViewController.swift
//  Cardiac
//
//  Created by Xinyi Ding on 30/10/2017.
//  Copyright © 2017 Eileen Guo. All rights reserved.
//

import UIKit
import AVFoundation

class PulseOximeterViewController: UIViewController {

    //MARK: Class Properties
    var videoManager:VideoAnalgesic! = nil
    //we'll be using the BridgeSub to handle the heart rate stuff (Module B), and this ViewController to handle the face stuff (Module A)
    let bridge = OpenCVBridgeSub()
    
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        
        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
        
    }
    
    //MARK: Process image output
    func processImage(inputImage:CIImage) -> CIImage{
        
        var retImage = inputImage

        // Try to detect heart rate via the finger method
        if (self.videoManager.getCameraPosition()==AVCaptureDevice.Position.back) {
            self.bridge.setTransforms(self.videoManager.transform)
            self.bridge.setImage(retImage,
                                 withBounds: retImage.extent, // the first face bounds
                andContext: self.videoManager.getCIContext())
            self.bridge.processImage()
            retImage = self.bridge.getImageComposite() // get back opencv processed part of the image (overlayed on original)
        }
        return retImage
    }
    
    @IBAction func toggleFlasg(_ sender: UIButton) {
         self.videoManager.toggleFlash()
    }
}
