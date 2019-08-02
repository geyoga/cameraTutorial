//
//  ViewController.swift
//  cameraTutorial
//
//  Created by Georgius Yoga Dewantama on 01/08/19.
//  Copyright © 2019 Georgius Yoga Dewantama. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var labelAccuracy: UILabel!
    @IBOutlet weak var labelName: UILabel!
    var state : Bool = false
    var name : String = ""
    var accur : String = ""
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // activate camera
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input =  try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        captureSession.addOutput(dataOutput)
        
        
        
    }
    @IBAction func captureAction(_ sender: UIButton) {
        
        doHaptic()
        state = true
        labelName.text     = "Object   : \(name)"
        labelAccuracy.text = "Accuracy : \(accur)"
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer : CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, error) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            
            guard let firstObservation = results.first else { return }
            
            print(firstObservation.identifier, firstObservation.confidence)
            
            self.settingUpVoice(voice: firstObservation.identifier)
            
            self.name = firstObservation.identifier
            self.accur = String (firstObservation.confidence * 100)
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
    }
    
    func settingUpVoice(voice : String) {
        
        if state == true {
            
            let speechSynthesizer = AVSpeechSynthesizer()
            let speechUtterance : AVSpeechUtterance = AVSpeechUtterance(string: voice)
            speechUtterance.rate = AVSpeechUtteranceMaximumSpeechRate / 2.0
            speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            speechSynthesizer.speak(speechUtterance)
            state = false
            
        }
        
    }
    

}

extension UIViewController {
    
    func doHaptic () {
        
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        
        feedback.impactOccurred()
    }
}

