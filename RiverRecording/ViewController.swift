//
//  ViewController.swift
//  RiverRecording
//
//  Created by Marquez Kim on 2016. 7. 26..
//  Copyright © 2016년 Marquez Kim. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // UI part
    @IBOutlet var recBtn: UIButton!
    @IBOutlet var photoBtn: UIButton!
    
    @IBOutlet var photoImg: UIImageView!
    
    @IBOutlet var statusLabel: UILabel!
    
    // AV part
    var recorder:AVAudioRecorder!
    var player:AVAudioPlayer!
    var captureSession:AVCaptureSession!
    var captureDevice:AVCaptureDevice!
    var previewLayer:AVCaptureVideoPreviewLayer!
    
    var imagePicker:UIImagePickerController!
    
    var meterTimer:Timer!
    
    var soundFileURL:URL!
    
    var isRecording:Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // UI Image Set up
        
        // Boolean set up
        isRecording = false
        
        // UI change
        initRecBtnImage()
        
        // AV init
        setSessionPlayback()
        askForNotifications()
        checkHeadphones()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        recorder = nil
        player = nil
    }
    
    func initRecBtnImage() {
        recBtn.imageView!.layer.cornerRadius = recBtn.imageView!.frame.height/2
        recBtn.setImage(recBtn.imageView!.image, for:UIControlState())
    }
    
    func changeRecBtnImage() {
        if (isRecording == true) {
            recBtn.imageView!.layer.cornerRadius = 0
            recBtn.setImage(recBtn.imageView!.image, for:UIControlState())
        } else {
            recBtn.imageView!.layer.cornerRadius = recBtn.imageView!.frame.height/2
            recBtn.setImage(recBtn.imageView!.image, for:UIControlState())
        }
        
    }
    
// MARK: Record
    
    @IBAction func pressRecButton(_ sender: UIButton) {
        NSLog("rec btn pressed")
        // UI change
        isRecording = !isRecording
        changeRecBtnImage()
        
        if isRecording == true { // Recording Stop
            record()
        } else {
            stop()
        }
    }
    
    func record() {
        // AV
        // check player
        if player != nil && player.isPlaying {
            player.stop()
        } else {
            // do nothing
        }
        
        // Recorder
        if recorder == nil {
            NSLog("recording, recorder nil")
            recordWithPermission(true)
            return
        } else {
            if recorder.isRecording {
                NSLog("pausing")
                recorder.pause()
            } else {
                NSLog("recording")
                recordWithPermission(false)
            }
        }
    }
    
    func recordWithPermission(_ setup:Bool) {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        // ios 8 and later
        if (session.responds(to: #selector(AVAudioSession.requestRecordPermission(_:)))) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("Permission to record granted")
                    self.setSessionPlayAndRecord()
                    if setup {
                        self.setupRecorder()
                    }
                    self.recorder.record()
                    self.meterTimer = Timer.scheduledTimer(timeInterval: 0.1,
                        target:self,
                        selector:#selector(ViewController.updateAudioMeter(_:)),
                        userInfo:nil,
                        repeats:true)
                } else {
                    print("Permission to record not granted")
                }
            })
        } else {
            print("requestRecordPermission unrecognized")
        }
    }
    
    func setupRecorder() {
        let format = DateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        let currentFileName = "recording-\(format.string(from: Date())).m4a"
        print(currentFileName)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.soundFileURL = documentsDirectory.appendingPathComponent(currentFileName)
        
        if FileManager.default.fileExists(atPath: soundFileURL.absoluteString) {
            // probably won't happen. want to do something about it?
            print("soundfile \(soundFileURL.absoluteString) exists")
        }
        
        let recordSettings:[String : AnyObject] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless as UInt32),
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue as AnyObject,
            AVEncoderBitRateKey : 320000 as AnyObject,
            AVNumberOfChannelsKey: 2 as AnyObject,
            AVSampleRateKey : 44100.0 as AnyObject
        ]
        
        do {
            recorder = try AVAudioRecorder(url: soundFileURL, settings: recordSettings)
            recorder.delegate = self
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
        } catch let error as NSError {
            recorder = nil
            print(error.localizedDescription)
        }
        
    }
    
    func setSessionPlayAndRecord() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            print("could not set session category")
            print(error.localizedDescription)
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("could not make session active")
            print(error.localizedDescription)
        }
    }
    
    
    func stop() {
        print("stop")
        
        recorder?.stop()
        player?.stop()
        
        //meterTimer.invalidate()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false)
        } catch let error as NSError {
            print("could not make session inactive")
            print(error.localizedDescription)
        }
        
        //recorder = nil
    }
    
    func setSessionPlayback() {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
        } catch let error as NSError {
            NSLog("Fail: set session category")
            NSLog(error.localizedDescription)
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("Fail: make session active")
            NSLog(error.localizedDescription)
        }
    }

    func askForNotifications() {
        
        NotificationCenter.default.addObserver(self,
                                                         selector:#selector(ViewController.background(_:)),
                                                         name:NSNotification.Name.UIApplicationWillResignActive,
                                                         object:nil)
        
        NotificationCenter.default.addObserver(self,
                                                         selector:#selector(ViewController.foreground(_:)),
                                                         name:NSNotification.Name.UIApplicationWillEnterForeground,
                                                         object:nil)
        
        NotificationCenter.default.addObserver(self,
                                                         selector:#selector(ViewController.routeChange(_:)),
                                                         name:NSNotification.Name.AVAudioSessionRouteChange,
                                                         object:nil)
    }
    
    func background(_ notification:Notification) {
        print("background")
    }
    
    func foreground(_ notification:Notification) {
        print("foreground")
    }
    
    
    func routeChange(_ notification:Notification) {
        print("routeChange \((notification as NSNotification).userInfo)")
        
        if let userInfo = (notification as NSNotification).userInfo {
            //print("userInfo \(userInfo)")
            if let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt {
                //print("reason \(reason)")
                switch AVAudioSessionRouteChangeReason(rawValue: reason)! {
                case AVAudioSessionRouteChangeReason.newDeviceAvailable:
                    print("NewDeviceAvailable")
                    print("did you plug in headphones?")
                    checkHeadphones()
                case AVAudioSessionRouteChangeReason.oldDeviceUnavailable:
                    print("OldDeviceUnavailable")
                    print("did you unplug headphones?")
                    checkHeadphones()
                case AVAudioSessionRouteChangeReason.categoryChange:
                    print("CategoryChange")
                case AVAudioSessionRouteChangeReason.override:
                    print("Override")
                case AVAudioSessionRouteChangeReason.wakeFromSleep:
                    print("WakeFromSleep")
                case AVAudioSessionRouteChangeReason.unknown:
                    print("Unknown")
                case AVAudioSessionRouteChangeReason.noSuitableRouteForCategory:
                    print("NoSuitableRouteForCategory")
                case AVAudioSessionRouteChangeReason.routeConfigurationChange:
                    print("RouteConfigurationChange")
                    
                }
            }
        }

    }
    
    func checkHeadphones() {
        // check NewDeviceAvailable and OldDeviceUnavailable for them being plugged in/unplugged
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        if currentRoute.outputs.count > 0 {
            for description in currentRoute.outputs {
                if description.portType == AVAudioSessionPortHeadphones {
                    NSLog("headphones are plugged in")
                    break
                } else {
                    NSLog("headphones are unplugged")
                }
            }
        } else {
            NSLog("checking headphones requires a connection to a device")
        }
    }
    
// MARK: Photo
    
    @IBAction func pressPhotoButton(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        let tempImage:UIImage = image
        photoImg.image  = tempImage
        
        dismiss(animated: true, completion: nil)
    }
    
// MARK: AudioMeter
    
    func updateAudioMeter(_ timer:Timer) {
        
        if recorder.isRecording {
            let min = Int(recorder.currentTime / 60)
            let sec = Int(recorder.currentTime.truncatingRemainder(dividingBy: 60))
            
            let s = String(format: "%02d:%02d", min, sec)

            recorder.updateMeters()
            // if you want to draw some graphics...
            let apc0 = recorder.averagePower(forChannel: 0)
            let peak0 = recorder.peakPower(forChannel: 0)
            
            statusLabel.text = apc0.description + " " + peak0.description + " " + s
        }
    }
}


// MARK: AVAudioRecorderDelegate
extension ViewController : AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                         successfully flag: Bool) {
        print("finished recording \(flag)")
        
        // iOS8 and later
        let alert = UIAlertController(title: "Recorder",
                                      message: "Finished Recording",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Keep", style: .default, handler: {action in
            print("keep was tapped")
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: {action in
            print("delete was tapped")
            self.recorder.deleteRecording()
        }))
        self.present(alert, animated:true, completion:nil)
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder,
                                          error: Error?) {
        
        if let e = error {
            print("\(e.localizedDescription)")
        }
    }
    
}

// MARK: AVAudioPlayerDelegate
extension ViewController : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("finished playing \(flag)")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let e = error {
            print("\(e.localizedDescription)")
        }
        
    }
}
