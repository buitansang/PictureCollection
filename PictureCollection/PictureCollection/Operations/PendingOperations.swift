//
//  PendingOperations.swift
//  PictureCollection
//
//  Created by Bui Tan Sang on 03/09/2024.
//

import Foundation

class PendingOperations {
    lazy var downloadsInProgress: [IndexPath: Operation] = [:]
    lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download queue"
        //  queue.maxConcurrentOperationCount = 1
        return queue
    }()
}
