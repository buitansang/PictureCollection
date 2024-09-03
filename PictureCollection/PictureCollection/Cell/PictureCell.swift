//
//  PictureCell.swift
//  PictureCollection
//
//  Created by Bui Tan Sang on 30/08/2024.
//

import UIKit

final class PictureCell: UICollectionViewCell {
    
    static let reuseIdentifier = "PictureCell"
    
    private lazy var imageView: UIImageView = {
        let imv = UIImageView()
        imv.translatesAutoresizingMaskIntoConstraints = false
        return imv
    }()
    
    private lazy var indexLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 24, weight: .bold)
        lb.textColor = .white
        lb.translatesAutoresizingMaskIntoConstraints = false
        return lb
    }()
    
    private lazy var indicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init coder has not been implemented")
    }
    
    private var record: PhotoRecord?
    
    func display(_ image: UIImage, index: Int) {
        imageView.image = image
        indexLabel.text = "\(index)"
    }
    
    func bind(_ record: PhotoRecord) {
        self.record = record
        
        // indexLabel.text = record.name
        imageView.image = record.image
        
        switch (record.state) {
        case .downloaded:
          indicator.stopAnimating()
        case .failed:
          indicator.stopAnimating()
        case .new:
          indicator.startAnimating()
        }
    }
    
    private func setupViews() {
        addSubview(imageView)
        addSubview(indexLabel)
        addSubview(indicator)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            indexLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            indexLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            indicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }
}

extension UIImage {
    func resizeImage(targetSize: CGSize) -> UIImage {
       let size = self.size
       
       let widthRatio  = targetSize.width  / size.width
       let heightRatio = targetSize.height / size.height
       
       var newSize: CGSize
       if(widthRatio > heightRatio) {
           newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
       } else {
           newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
       }
       
       let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
       
       UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
       self.draw(in: rect)
       let newImage = UIGraphicsGetImageFromCurrentImageContext()
       UIGraphicsEndImageContext()
       
       return newImage!
   }
}
