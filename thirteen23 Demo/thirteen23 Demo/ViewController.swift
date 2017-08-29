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
                for (index, imageTuple) in downloadedImages.enumerated() {
                    DemoService.sharedDemoService.addNewImage(image: imageTuple.0,
                                                              number: imageTuple.1,
                                                              position: Int16(index))
                }
                self.downloadButton.isHidden = true
                self.refreshCollectionView()
            }
        }
    }
    
    // MARK: Properties (Private)
    private var imagesBuffer: [Image] = []
    private var selectedCell: ImagesCollectionViewCell? = nil
    private var canIsOpen: Bool = false
    
    private func checkOrder() {
        self.imagesBuffer = DemoService.sharedDemoService.getImages()
        let expected = self.imagesBuffer.sorted(by: { $0.number < $1.number })
        if expected == imagesBuffer {
            self.presentAlert(title: "Congratulations!", message: "All the numbers are in order")
        }
    }
    
    private func refreshCollectionView() {
        self.checkOrder()
        self.imagesCollectionView.reloadData()
    }
    
    private func getImageFromBufferForPosition(position: Int) -> Image?{
        let position16 = Int16(position)
        return self.imagesBuffer.filter({ $0.position == position16 }).first
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
    
    // MARK: Properties (Private)
    func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        
        switch(gesture.state) {
            
        case UIGestureRecognizerState.began:
            guard let indexPath = self.imagesCollectionView.indexPathForItem(at: gesture.location(in: self.imagesCollectionView)) else {
                break
            }
            let cell = self.imagesCollectionView.cellForItem(at: indexPath) as! ImagesCollectionViewCell
            self.selectedCell = cell
            if cell.image != nil {
                _ = imagesCollectionView.beginInteractiveMovementForItem(at: indexPath)
            }
        case UIGestureRecognizerState.changed:
            guard self.selectedCell?.image != nil else {
                break
            }
            imagesCollectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
            let gestureCurrentPoint = gesture.location(in: self.view)
            if trashView.frame.contains(gestureCurrentPoint) && !canIsOpen {
                self.openCan()
            } else if canIsOpen && !trashView.frame.contains(gestureCurrentPoint) {
                self.closeCan()
            }
        case UIGestureRecognizerState.ended:
            guard self.selectedCell?.image != nil else {
                self.selectedCell = nil
                break
            }
            let gestureEndPoint = gesture.location(in: self.view)
            imagesCollectionView.endInteractiveMovement()
            if trashView.frame.contains(gestureEndPoint), let cell = selectedCell, let image = cell.image {
                self.closeCan()
                DemoService.sharedDemoService.deleteImage(image: image)
                self.refreshCollectionView()
            } else {
                self.checkOrder()
            }
            self.selectedCell = nil
        default:
            imagesCollectionView.cancelInteractiveMovement()
        }
    }
    
    // MARK: Collection View Delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let maxInt16 = self.imagesBuffer.map{$0.position}.max()
        if let maxPosition = maxInt16 {
            let max = Int(maxPosition)
            return max + 1
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imagesCollectionViewCell", for: indexPath) as! ImagesCollectionViewCell

        if let image = self.getImageFromBufferForPosition(position: indexPath.row) {
            cell.imageView.image = UIImage(data: (image.data as Data?)!)
            cell.image = image
        } else {
            cell.imageView.image = nil
        }
        
        cell.tag = indexPath.row
        
        return cell
    }

    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if !DemoService.sharedDemoService.imagesAreLoaded() {
            downloadButton.isHidden = false
        } else {
            self.refreshCollectionView()
        }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture))
        longPressGesture.minimumPressDuration  = 0.1
        self.imagesCollectionView.addGestureRecognizer(longPressGesture)
        self.imagesCollectionView.clipsToBounds = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
