//
//  RecordFileManager.swift
//  RiverRecording
//
//  Created by Marquez on 12/10/2017.
//  Copyright © 2017 Marquez Kim. All rights reserved.
//

import Foundation
import AVFoundation
import Photos

protocol RecordFileManagerDelegate {
    func record()
}
final class RecordFileManager {
    
    private init () {
        
        
    }
    
    static let shared = RecordFileManager()
    
    func makeRiver(_ url: URL, _ startDate: Date, _ endDate: Date, completion: @escaping (String) -> ()) {

        accessToPhotoLibrary()
        
        // Test code for HUD
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion("Finished")
        }
    }
    
    func accessToPhotoLibrary() {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                print("GTG")
                let fetchOptions = PHFetchOptions()
                let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                print("Found \(allPhotos.count) images")
            case .denied, .restricted:
                print("Not allowed")
            case .notDetermined:
                print("Not determined yet")
                
            }
        }
    }
    
    
} 
