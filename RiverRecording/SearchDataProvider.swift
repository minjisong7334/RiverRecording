//
//  SearchingDataProvider.swift
//  RiverRecording
//
//  Created by Marquez on 15/10/2017.
//  Copyright © 2017 Marquez Kim. All rights reserved.
//

import Foundation

class SearchDataProvider {
    
    var count: Int?
    var contents: [String]? = []
    
    init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            try contents = FileManager.default.contentsOfDirectory(atPath: documentsDirectory.path)
        } catch {
            contents = ["No file exists.."]
        }
        
        defer {
            count = contents?.count
        }
    }
}
