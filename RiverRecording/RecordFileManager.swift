//
//  RecordFileManager.swift
//  RiverRecording
//
//  Created by Marquez on 12/10/2017.
//  Copyright © 2017 Marquez Kim. All rights reserved.
//

import Foundation
import AVFoundation

protocol RecordFileManagerDelegate {
    func record()
}
final class RecordFileManager {
    
    private init () {
        
        
    }
    
    static let shared = RecordFileManager()
    
    func makeRiver(_ url: URL, _ time: TimeInterval, completion: @escaping (String) -> ()) {
        completion("Finished")
    }
    
    
} 