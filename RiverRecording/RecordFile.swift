//
//  RecordFile.swift
//  RiverRecording
//
//  Created by Marquez on 12/10/2017.
//  Copyright © 2017 Marquez Kim. All rights reserved.
//

import Foundation

class RecordFile {
    
    var name: String
//    var audio: AudioFile
    var pictures: [(Data, Date)]?
    
    init(_ name: String) {
        self.name = name
    }
    
}
