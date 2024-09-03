//
//  ImageDownloader.swift
//  PictureCollection
//
//  Created by Bui Tan Sang on 03/09/2024.
//

import UIKit

final class ImageDownloader: Operation {
    let photoRecord: PhotoRecord
    
    init(_ photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main() {
        if isCancelled {
            return
        }
        
        guard let imageData = try? Data(contentsOf: photoRecord.url) else { return }
        
        if isCancelled {
            return
        }
        
        if !imageData.isEmpty {
            photoRecord.state = .downloaded
            photoRecord.image = UIImage(data: imageData)
        } else {
            photoRecord.state = .failed
            photoRecord.image = UIImage(named: "Fail")
        }
    }
}
