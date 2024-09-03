//
//  PhotoRecord.swift
//  PictureCollection
//
//  Created by Bui Tan Sang on 03/09/2024.
//

import UIKit

enum PhotoRecordState {
    case new, downloaded, failed
}

class PhotoRecord {
    let name: String
    let url: URL
    var state = PhotoRecordState.new
    var image = UIImage(named: "Placeholder")
    
    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}
