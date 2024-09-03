//
//  ViewController.swift
//  PictureCollection
//
//  Created by Bui Tan Sang on 29/08/2024.
//

import UIKit

class PictureCollectionViewController: UIViewController {
    
    private lazy var topBarStackView: UIStackView = {
        let v = UIStackView()
        v.backgroundColor = .white
        v.axis = .horizontal
        v.spacing = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var plusButton: UIButton = {
        let bt = UIButton()
        bt.setImage(UIImage(systemName: "plus"), for: .normal)
        bt.addTarget(self, action: #selector(plusButtonAction), for: .touchUpInside)
        return bt
    }()
    
    private lazy var reloadButton: UIButton = {
        let bt = UIButton()
        bt.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        bt.addTarget(self, action: #selector(reloadButtonAction), for: .touchUpInside)
        return bt
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewLayout()
        let clv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        clv.backgroundColor = .white
        clv.bounces = false
        clv.isPagingEnabled = true
        clv.translatesAutoresizingMaskIntoConstraints = false
        return clv
    }()
    
    typealias Record = PhotoRecord
    private let urlString = "https://loremflickr.com/200/200"
    private var imageList = [Record]()
    private let pendingOperations = PendingOperations()

    private let numberOfItemsInRow = 7
    private let minimumInteritemSpacing: CGFloat = 2
    private let collectionViewWidthFixed = UIScreen.main.bounds.size.width - 2*2
    private var currentIndex = 0
    private var currentPage: Int = 1 {
        didSet {
           // guard oldValue != currentPage else { return }
            let targetOffsetX = CGFloat(currentPage - 1) * collectionViewWidthFixed
            let targetOffset = CGPoint(x: targetOffsetX, y: 0)
            collectionView.setContentOffset(targetOffset, animated: true)
        }
    }
    private var numberOfColumnsInPage = 7
    private var maximumRowInPage = 10
    private var numberOfItemsInPage: Int {
        return numberOfColumnsInPage * maximumRowInPage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(topBarStackView)
        view.addSubview(collectionView)
        setupColectionView()
        
        let spacer = UIView()
        spacer.isUserInteractionEnabled = false
        spacer.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        
        topBarStackView.addArrangedSubview(plusButton)
        topBarStackView.addArrangedSubview(reloadButton)
        topBarStackView.addArrangedSubview(spacer)
        
        NSLayoutConstraint.activate([
            topBarStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 36),
            topBarStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            topBarStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBarStackView.heightAnchor.constraint(equalToConstant: 36),
            
            plusButton.widthAnchor.constraint(equalToConstant: 36),
            reloadButton.widthAnchor.constraint(equalToConstant: 36),
            
            collectionView.topAnchor.constraint(equalTo: topBarStackView.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 2),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
}

private extension PictureCollectionViewController {
    func createLayout() -> AdvanceGridLayout {
        let layout = AdvanceGridLayout()
        layout.delegate = self
        layout.numberOfColumnsInPage = numberOfItemsInRow
        layout.minimumLineSpacing = 2.0
        layout.minimumInteritemSpacing = minimumInteritemSpacing
        layout.collectionViewWidthFixed = collectionViewWidthFixed
        layout.numberOfColumnsInPage = 7
        layout.maximumRowInPage = 10
        return layout
    }
    
    func widthItem() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.size.width
        let totalSpacingInRow = CGFloat(numberOfItemsInRow - 1) * minimumInteritemSpacing
        return (screenWidth - 2*2 - totalSpacingInRow) / CGFloat(numberOfItemsInRow)
    }
    
    func setupColectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PictureCell.self, forCellWithReuseIdentifier: PictureCell.reuseIdentifier)
        collectionView.collectionViewLayout = createLayout()
    }
    
//    func initializeImageList() {
//        imageList = (1...280).map {
//            (UIImage(named: "EMYEUU")!.resizeImage(targetSize: CGSize(width: 200, height: 200)), $0)
//        }
//    }
}

extension PictureCollectionViewController: AdvanceGridLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, layout: AdvanceGridLayout, heightForItemAtIndexPath indexPath: IndexPath) -> CGFloat {
        return widthItem()
    }
}

extension PictureCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PictureCell.reuseIdentifier, for: indexPath) as? PictureCell else { return UICollectionViewCell() }
        let record = imageList[indexPath.row]
        
        cell.bind(record)
        switch record.state {
        case .new, .downloaded:
            if !collectionView.isDragging && !collectionView.isDecelerating {
                startOperations(for: record, at: indexPath)
            }
        default: break
        }
        return cell
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        suspendAllOperations()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            loadImagesForOnscreenCells()
            resumeAllOperations()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        loadImagesForOnscreenCells()
        resumeAllOperations()
    }
}

private extension PictureCollectionViewController {
    func startOperations(for photoRecord: PhotoRecord, at indexPath: IndexPath) {
        switch (photoRecord.state) {
        case .new:
            startDownload(for: photoRecord, at: indexPath)
        default:
            print("idle state")
        }
    }
    
    func startDownload(for photoRecord: PhotoRecord, at indexPath: IndexPath) {
        
        guard pendingOperations.downloadsInProgress[indexPath] == nil else {
            return
        }
        
        let downloader = ImageDownloader(photoRecord)
        downloader.completionBlock = {
            if downloader.isCancelled {
                return
            }
            
            DispatchQueue.main.async {
                self.pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
        pendingOperations.downloadsInProgress[indexPath] = downloader
        pendingOperations.downloadQueue.addOperation(downloader)
    }
    
    // MARK: - Operation management
    
    func suspendAllOperations() {
        pendingOperations.downloadQueue.isSuspended = true
    }
    
    func resumeAllOperations() {
        pendingOperations.downloadQueue.isSuspended = false
    }
    
    func loadImagesForOnscreenCells() {
        let pathsArray = collectionView.indexPathsForVisibleItems
        
        let allPendingOperations = Set(pendingOperations.downloadsInProgress.keys)
        
        var toBeCancelled = allPendingOperations
        let visiblePaths = Set(pathsArray)
        toBeCancelled.subtract(visiblePaths)
        
        var toBeStarted = visiblePaths
        toBeStarted.subtract(allPendingOperations)
        
        for indexPath in toBeCancelled {
            if let pendingDownload = pendingOperations.downloadsInProgress[indexPath] {
                pendingDownload.cancel()
            }
            
            pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
        }
        
        for indexPath in toBeStarted {
            let recordToProcess = imageList[indexPath.row]
            startOperations(for: recordToProcess, at: indexPath)
        }
    }
}

private extension PictureCollectionViewController {
    @objc func plusButtonAction() {
        currentIndex += 1
        
        let url = URL(string: urlString)
        if let url = url {
            let record = PhotoRecord(name: "\(currentIndex)", url: url)
            imageList.append(record)
            
            currentPage = updateCurrentPage(for: imageList.count, itemsPerPage: numberOfItemsInPage)
            collectionView.reloadData()
        }
    }
    
    @objc func reloadButtonAction() {
        currentIndex = 0
        imageList.removeAll()
        collectionView.reloadData()
        
        let url = URL(string: urlString)
        if let url = url {
            for _ in (1...700) {
                currentIndex += 1
                let record = PhotoRecord(name: "\(currentIndex)", url: url)
                imageList.append(record)
                currentPage = updateCurrentPage(for: imageList.count, itemsPerPage: numberOfItemsInPage)
            }
            collectionView.reloadData()
        }
    }
    
    func updateCurrentPage(for count: Int, itemsPerPage: Int) -> Int {
        return (count - 1) / itemsPerPage + 1
    }
}
