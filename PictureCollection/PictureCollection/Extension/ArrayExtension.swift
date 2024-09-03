//
//  ArrayExtension.swift
//  PictureCollection
//
//  Created by Bui Tan Sang on 30/08/2024.
//

import Foundation

extension Array where Element: Comparable {
    var indexOfMin: Int? {
        guard let min = self.min() else { return nil }
        return self.firstIndex(of: min)
    }
    
    var indexOfMax: Int? {
        guard let max = self.max() else { return nil }
        return self.firstIndex(of: max)
    }
}
