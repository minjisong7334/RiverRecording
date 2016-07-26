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
    
    var meterTimer:NSTimer!
    
    var soundFileURL:NSURL!
    
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
        recBtn.setImage(recBtn.imageView!.image, forState:UIControlState.Normal)
    }
    
    func changeRecBtnImage() {
        if (isRecording == true) {
            recBtn.imageView!.layer.cornerRadius = 0
            recBtn.setImage(recBtn.imageView!.image, forState:UIControlState.Normal)
        } else {
            recBtn.imageView!.layer.cornerRadius = recBtn.imageView!.frame.height/2
            recBtn.setImage(recBtn.imageView!.image, forState:UIControlState.Normal)
        }
        
    }
    
// MARK: Record
    
    @IBAction func pressRecButton(sender: UIButton) {
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
        if player != nil && player.playing {
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
            if recorder.recording {
                NSLog("pausing")
                recorder.pause()
            } else {
                NSLog("recording")
                recordWithPermission(false)
            }
        }
    }
    
    func recordWithPermission(setup:Bool) {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        // ios 8 and later
        if (session.respondsToSelector("requestRecordPermission:")) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("Permission to record granted")
                    self.setSessionPlayAndRecord()
                    if setup {
                        self.setupRecorder()
                    }
                    self.recorder.record()
                    self.meterTimer = NSTimer.scheduledTimerWithTimeInterval(0.1,
                        target:self,
                        selector:"updateAudioMeter:",
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
        let format = NSDateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        let currentFileName = "recording-\(format.stringFromDate(NSDate())).m4a"
        print(currentFileName)
        
        let documentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        self.soundFileURL = documentsDirectory.URLByAppendingPathComponent(currentFileName)
        
        if NSFileManager.defaultManager().fileExistsAtPath(soundFileURL.absoluteString) {
            // probably won't happen. want to do something about it?
            print("soundfile \(soundFileURL.absoluteString) exists")
        }
        
        let recordSettings:[String : AnyObject] = [
            AVFormatIDKey: NSNumber(unsignedInt:kAudioFormatAppleLossless),
            AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey : 44100.0
        ]
        
        do {
            recorder = try AVAudioRecorder(URL: soundFileURL, settings: recordSettings)
            recorder.delegate = self
            recorder.meteringEnabled = true
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
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:"background:",
                                                         name:UIApplicationWillResignActiveNotification,
                                                         object:nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:"foreground:",
                                                         name:UIApplicationWillEnterForegroundNotification,
                                                         object:nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:"routeChange:",
                                                         name:AVAudioSessionRouteChangeNotification,
                                                         object:nil)
    }
    
    func background(notification:NSNotification) {
        print("background")
    }
    
    func foreground(notification:NSNotification) {
        print("foreground")
    }
    
    
    func routeChange(notification:NSNotification) {
        print("routeChange \(notification.userInfo)")
        
        if let userInfo = notification.userInfo {
            //print("userInfo \(userInfo)")
            if let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt {
                //print("reason \(reason)")
                switch AVAudioSessionRouteChangeReason(rawValue: reason)! {
                case AVAudioSessionRouteChangeReason.NewDeviceAvailable:
                    print("NewDeviceAvailable")
                    print("did you plug in headphones?")
                    checkHeadphones()
                case AVAudioSessionRouteChangeReason.OldDeviceUnavailable:
                    print("OldDeviceUnavailable")
                    print("did you unplug headphones?")
                    checkHeadphones()
                case AVAudioSessionRouteChangeReason.CategoryChange:
                    print("CategoryChange")
                case AVAudioSessionRouteChangeReason.Override:
                    print("Override")
                case AVAudioSessionRouteChangeReason.WakeFromSleep:
                    print("WakeFromSleep")
                case AVAudioSessionRouteChangeReason.Unknown:
                    print("Unknown")
                case AVAudioSessionRouteChangeReason.NoSuitableRouteForCategory:
                    print("NoSuitableRouteForCategory")
                case AVAudioSessionRouteChangeReason.RouteConfigurationChange:
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
    
    @IBAction func pressPhotoButton(sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera;
            imagePicker.allowsEditing = false
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        let tempImage:UIImage = image
        photoImg.image  = tempImage
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
// MARK: AudioMeter
    
    func updateAudioMeter(timer:NSTimer) {
        
        if recorder.recording {
            let min = Int(recorder.currentTime / 60)
            let sec = Int(recorder.currentTime % 60)
            
            let s = String(format: "%02d:%02d", min, sec)

            recorder.updateMeters()
            // if you want to draw some graphics...
            var apc0 = recorder.averagePowerForChannel(0)
            var peak0 = recorder.peakPowerForChannel(0)
            
            statusLabel.text = apc0.description + " " + peak0.description + " " + s
        }
    }
}


// MARK: AVAudioRecorderDelegate
extension ViewController : AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder,
                                         successfully flag: Bool) {
        print("finished recording \(flag)")
        
        // iOS8 and later
        let alert = UIAlertController(title: "Recorder",
                                      message: "Finished Recording",
                                      preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Keep", style: .Default, handler: {action in
            print("keep was tapped")
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: {action in
            print("delete was tapped")
            self.recorder.deleteRecording()
        }))
        self.presentViewController(alert, animated:true, completion:nil)
    }
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder,
                                          error: NSError?) {
        
        if let e = error {
            print("\(e.localizedDescription)")
        }
    }
    
}

// MARK: AVAudioPlayerDelegate
extension ViewController : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        print("finished playing \(flag)")
    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        if let e = error {
            print("\(e.localizedDescription)")
        }
        
    }
}