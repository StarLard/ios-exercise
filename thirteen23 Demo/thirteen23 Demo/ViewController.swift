//
//  ViewController.swift
//  thirteen23 Demo
//
//  Created by Caleb Friden on 8/26/17.
//  Copyright © 2017 Caleb Friden. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: Properties (IBOutlet)
    @IBOutlet weak var imagesCollectionView: ImagesCollectionView!
    @IBOutlet weak var trashCanLidView: UIImageView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var trashView: UIStackView!

    // MARK: Properties (IBAction)
    @IBAction func downloadPressed(_ sender: Any) {
        downloadButton.isEnabled = false
        self.showActivityIndicator()
        self.downloadImages() {
            results, error in
            if let error = error {
                print(error)
                DispatchQueue.main.async {
                    self.presentAlert(title: "Please try again", message: "Error downloading images")
                    self.hideActivityIndicator()
                    self.downloadButton.isEnabled = true
                }
                return
            }
            guard let downloadedImages = results else {
                fatalError("Unable to unwrap downloaded images")
            }
            self.hideActivityIndicator()
            DispatchQueue.main.async {
                for imageTuple in downloadedImages {
                    DemoService.sharedDemoService.addNewImage(image: imageTuple.0, number: imageTuple.1)
                }
                self.downloadButton.isHidden = true
                self.refreshCollectionView()
            }
        }
    }
    
    // MARK: Properties (Private)
    private var images: [Image] = []
    private var selectedCell: ImagesCollectionViewCell? = nil
    private var canIsOpen: Bool = false
    
    private func refreshCollectionView() {
        self.images = DemoService.sharedDemoService.getImages()
        self.images = images.sorted(by: { $0.position < $1.position })
        self.imagesCollectionView.reloadData()
    }
    
    private func openCan() {
        UIView.animate(withDuration:0.25, animations: {
            self.trashCanLidView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/6)
            self.trashCanLidView.center.y -= 15
            self.trashCanLidView.center.x -= 15
        })
        self.canIsOpen = true
    }
    
    private func closeCan() {
        UIView.animate(withDuration:0.25, animations: {
            self.trashCanLidView.transform = CGAffineTransform(rotationAngle: 0)
            self.trashCanLidView.center.y += 15
            self.trashCanLidView.center.x += 15
        })
        self.canIsOpen = false
    }
    
    private func downloadImages(completionHandler: @escaping (_ results: [(UIImage, Int16)]?, _ error: Error?) -> Void) {
        var downloadedImages: [(UIImage, Int16)] = []
        WebService.sharedWebService.getDataFromAPI(jsonKey: "image_ids") { result, error in
            if let error = error {
                completionHandler(nil, error)
                return
            }
            guard let result = result else {
                fatalError("Result from API was nil")
            }
            let downloadGroup = DispatchGroup()
            for id in result {
                downloadGroup.enter()
                WebService.sharedWebService.getDataFromAPI(jsonKey: "url", apppendix: id) { result, apiError in
                    if let apiError = apiError {
                        downloadGroup.leave()
                        completionHandler(nil, apiError)
                        return
                    }
                    guard let result = result else {
                        fatalError("Result from API was nil")
                    }
                    guard let imageURL = URL(string: result[0]) else {
                        fatalError("Unable to generate URL")
                    }
                    WebService.sharedWebService.downloadImageFromUrl(url: imageURL) { image, downloadError in
                        if let downloadError = downloadError {
                            downloadGroup.leave()
                            completionHandler(nil, downloadError)
                        }
                        guard let image = image else {
                            fatalError("Downloaded image was nil")
                        }
                        let filename = imageURL.lastPathComponent
                        guard let number = Int16(NSString(string: filename).deletingPathExtension) else {
                            fatalError("Unable to extract number from URL")
                        }
                        downloadedImages.append((image, number))
                        downloadGroup.leave()
                    }
                }
            }
            downloadGroup.notify(queue: DispatchQueue.main) {
                completionHandler(downloadedImages, nil)
            }
        }
    }
    
    func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        
        switch(gesture.state) {
            
        case UIGestureRecognizerState.began:
            guard let indexPath = self.imagesCollectionView.indexPathForItem(at: gesture.location(in: self.imagesCollectionView)) else {
                break
            }
            let cell = self.imagesCollectionView.cellForItem(at: indexPath) as! ImagesCollectionViewCell
            self.selectedCell = cell
            imagesCollectionView.beginInteractiveMovementForItem(at: indexPath)
        case UIGestureRecognizerState.changed:
            imagesCollectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
            let gestureCurrentPoint = gesture.location(in: self.view)
            if trashView.frame.contains(gestureCurrentPoint) && !canIsOpen {
                self.openCan()
            } else if canIsOpen && !trashView.frame.contains(gestureCurrentPoint) {
                self.closeCan()
            }
        case UIGestureRecognizerState.ended:
            let gestureEndPoint = gesture.location(in: self.view)
            imagesCollectionView.endInteractiveMovement()
            if trashView.frame.contains(gestureEndPoint) {
                guard  let cell = selectedCell, let image = cell.image else {
                    fatalError("Unable to get selected cell/image")
                }
                self.closeCan()
                self.images.remove(at: cell.tag)
                DemoService.sharedDemoService.deleteImage(image: image)
                self.refreshCollectionView()
            }
            selectedCell = nil
        default:
            imagesCollectionView.cancelInteractiveMovement()
        }
    }
    
    // MARK: Collection View Delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: destinationIndexPath) as! ImagesCollectionViewCell
        guard let image = cell.image else {
            fatalError("Image for cell not set")
        }
        self.images.changeElementIndex(from: sourceIndexPath.row, to: destinationIndexPath.row)
        cell.tag = destinationIndexPath.row
        DemoService.sharedDemoService.setImagePosition(image: image, position: Int16(destinationIndexPath.row))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let image = images[indexPath.row]
        if image.position < 0 {
            DemoService.sharedDemoService.setImagePosition(image: image, position: Int16(indexPath.row))
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imagesCollectionViewCell", for: indexPath) as! ImagesCollectionViewCell
        cell.tag = indexPath.row
        cell.imageView.image = UIImage(data: (image.data as Data?)!)
        cell.image = image
        
        return cell
    }

    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if !DemoService.sharedDemoService.imagesAreLoaded() {
            downloadButton.isHidden = false
        } else {
            refreshCollectionView()
        }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture))
        self.imagesCollectionView.addGestureRecognizer(longPressGesture)
        self.imagesCollectionView.clipsToBounds = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
