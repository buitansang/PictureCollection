//
//  AdvanceGridLayout.swift
//  PictureCollection
//
//  Created by Bui Tan Sang on 30/08/2024.
//

import UIKit

protocol AdvanceGridLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, layout: AdvanceGridLayout, heightForItemAtIndexPath indexPath: IndexPath) -> CGFloat
}

final class AdvanceGridLayout: UICollectionViewLayout {
    
    typealias AttributeCache = [UICollectionViewLayoutAttributes]
    
    weak var delegate: AdvanceGridLayoutDelegate?
    
    private var itemCache = AttributeCache()
    private var supplementaryCache: [String: AttributeCache] = [:]
    
    func initializeContentBounds() {
        guard let collectionView = collectionView else { return }
        
        var width = collectionView.bounds.size.width
        let height = collectionView.bounds.size.height
        
        if let fixedWidth = collectionViewWidthFixed {
            width = fixedWidth
        }
        
        let size = CGSize(width: width * CGFloat(numberOfPage), height: height)
        contentBounds = CGRect(origin: .zero, size: size)
    }
    
    private var contentBounds: CGRect = .zero
    var collectionViewWidthFixed: CGFloat?
    
    var cellPadding: CGFloat = 2 {
        didSet {
            guard oldValue != cellPadding else { return }
            invalidateLayout()
        }
    }
    
    var numberOfColumnsInPage = 7 {
        didSet {
            guard oldValue != numberOfColumnsInPage else { return }
            invalidateLayout()
        }
    }
    
    var maximumRowInPage = 10 {
        didSet {
            guard oldValue != maximumRowInPage else { return }
            invalidateLayout()
        }
    }
    
    var numberOfPage: Int {
        guard let collectionView = collectionView else { return 0 }
        let count = collectionView.numberOfItems(inSection: 0)
        return Int(ceil(Double(count) / Double(numberOfItemsInPage)))
    }
    
    var numberOfItemsInPage: Int {
        return numberOfColumnsInPage * maximumRowInPage
    }
    
    var minimumLineSpacing: CGFloat = 0
    var minimumInteritemSpacing: CGFloat = 0
    
    var cellWidth: CGFloat {
        let spacing = CGFloat(numberOfColumnsInPage * numberOfPage - 1) * minimumInteritemSpacing
        return (contentBounds.width - spacing) / CGFloat(numberOfColumnsInPage * numberOfPage)
    }
    
    override func prepare() {
        guard let collectionView = collectionView else { return }
        
        itemCache.removeAll()
        supplementaryCache.removeAll()
        initializeContentBounds()
        
        let count = collectionView.numberOfItems(inSection: 0)
        
        if count <= 0 { return }
        
        var xOffsets: [CGFloat] = .init(repeating: 0, count: numberOfPage * numberOfColumnsInPage)
        xOffsets = xOffsets.indices.map { CGFloat($0) * contentBounds.width / (CGFloat(numberOfColumnsInPage) * CGFloat(numberOfPage)) }
        var heightItemInRow: [CGFloat] = .init(repeating: 0, count: numberOfPage * numberOfColumnsInPage)
        var yOffsets: [CGFloat] = .init(repeating: 0, count: numberOfPage * numberOfColumnsInPage)
        
        for page in (0...numberOfPage - 1) {
            let start = page * numberOfColumnsInPage
            let end = start + numberOfColumnsInPage - 1
            
            for index in (start...end) {
                yOffsets[index] = 0
            }
            
            var column = page * numberOfColumnsInPage
            var realItemsInCurrentPage = numberOfItemsInPage
            var itemIndex = page * numberOfItemsInPage
            
            if page == numberOfPage - 1 {
                realItemsInCurrentPage = count - page * numberOfItemsInPage
            }
            
            while itemIndex < realItemsInCurrentPage + page * numberOfItemsInPage {
                let indexPath = IndexPath(item: itemIndex, section: 0)
                let itemHeight = delegate?.collectionView(collectionView, layout: self, heightForItemAtIndexPath: indexPath) ?? 0
                
                let height = itemHeight + minimumLineSpacing
                heightItemInRow[column] = height
                
                let width = cellWidth
                let frame = CGRect(x: xOffsets[column], y: yOffsets[column], width: width, height: height)
                
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = frame
                itemCache.append(attributes)
                contentBounds = contentBounds.union(frame)
                
                if contentBounds.size.height != frame.maxY {
                    contentBounds.size.height =  yOffsets[column] + heightItemInRow.getMax()
                }
                
                yOffsets[column] = frame.maxY
                
                itemIndex += 1
                
                let yOffsetsInCurrentPage = Array(yOffsets[start...end])
                if itemIndex.isMultiple(of: numberOfColumnsInPage) {
                    let yOffsetsMax = yOffsetsInCurrentPage.getMax()
                    for index in (start...end) {
                        yOffsets[index] = yOffsetsMax
                    }
                }
                column = (yOffsetsInCurrentPage.indexOfMin ?? 0) + (page * numberOfColumnsInPage)
                
                if count <= 0 {
                    contentBounds.size.height = 0
                }
            }
        }
    }
    
    override var collectionViewContentSize: CGSize {
        return contentBounds.size
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        return !newBounds.size.equalTo(collectionView.bounds.size)
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return itemCache[indexPath.item]
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return supplementaryCache[elementKind]?[indexPath.item]
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var result = [UICollectionViewLayoutAttributes]()
        
        let attributes = binSearchAttributes(in: itemCache, intersecting: rect)
        result.append(contentsOf: attributes)
        
        supplementaryCache.keys.forEach { key in
            if let cache = supplementaryCache[key] {
                let attributes = binSearchAttributes(in: cache, intersecting: rect)
                result.append(contentsOf: attributes)
            }
        }

        return result
    }
    
    // MARK: - Helpers
    func binSearchAttributes(in cache: AttributeCache, intersecting rect: CGRect) -> AttributeCache {
        var result = [UICollectionViewLayoutAttributes]()
        
        let start = cache.startIndex
        guard let end = cache.indices.last else { return result }
        
        guard let firstMatchIndex = findPivot(in: cache, for: rect, start: start, end: end) else {
            return result
        }
        
        for attributes in cache[..<firstMatchIndex].reversed() {
            guard attributes.frame.maxY >= rect.minY else { break }
            result.append(attributes)
        }
        
        for attributes in cache[firstMatchIndex...] {
            guard attributes.frame.minY <= rect.maxY else { break }
            result.append(attributes)
        }
        
        return result
    }
    
    func findPivot(in cache: AttributeCache, for rect: CGRect, start: Int, end: Int) -> Int? {
        if end < start { return nil }
        
        let mid = (start + end) / 2
        let attr = cache[mid]
        
        if attr.frame.intersects(rect) {
            return mid
        } else {
            if attr.frame.maxX < rect.minX {
                return findPivot(in: cache, for: rect, start: (mid + 1), end: end)
            } else {
                return findPivot(in: cache, for: rect, start: start, end: (mid - 1))
            }
        }
    }
}

extension Array where Element == CGFloat {
    func getMax() -> CGFloat {
        return self.max() ?? 0.0
    }
}
