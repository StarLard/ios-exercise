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
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var trashCanLid: UIImageView!
    @IBOutlet weak var downloadButton: UIButton!

    // MARK: Properties (IBAction)
    @IBAction func downloadPressed(_ sender: Any) {
        self.getDataFromAPI(jsonKey: "image_ids") { result, error in
            if let error = error {
                print(error)
                self.presentAlert(title: "Unable to download images", message: "Please try again")
                return
            }
            guard let result = result else {
                fatalError("Result from API was nil")
            }
            for id in result {
                self.getDataFromAPI(jsonKey: "url", apppendix: id) { result, error in
                    if let error = error {
                        print(error)
                        self.presentAlert(title: "Unable to download images", message: "Please try again")
                        return
                    }
                    guard let result = result else {
                        fatalError("Result from API was nil")
                    }
                    guard let imageURL = URL(string: result[0]) else {
                        fatalError("Unable to generate URL")
                    }
                    self.downloadImageFromUrl(url: imageURL, imageID: id) { error in
                        if let error = error {
                            print(error)
                            self.presentAlert(title: "Unable to download images", message: "Please try again")
                            return
                        }
                        self.downloadButton.isHidden = true
                        self.refreshCollectionView()
                    }
                }
            }
        }
    }
    
    // MARK: Properties (Private)
    private var images: [Image] = []
    
    private func refreshCollectionView() {
        self.images = DemoService.sharedDemoService.getImages()
        self.images = images.sorted(by: { $0.position > $1.position })
        self.imagesCollectionView.reloadData()
    }
    
    private enum DemoError: Error {
        case couldNotFetch(reason: String)
        case noResponse(reason: String)
        case conversionFailed(reason: String)
    }
    
    private func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default,handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func getDataFromAPI(jsonKey: String,
                                apppendix: String? = nil,
                                completionHandler: @escaping (_ results: [String]?, _ error: Error?) -> Void) {
        var results: [String] = []
        var apiAddress = "https://t23-pics.herokuapp.com/pics"
        if let apppendix = apppendix {
            apiAddress = apiAddress  + "/\(apppendix)"
        }
        guard let apiURL = URL(string: apiAddress) else {
            fatalError("Unable to generate URL")
        }
        let urlRequest = URLRequest(url: apiURL)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completionHandler(nil, DemoError.couldNotFetch(reason: "Error fetching data: \(error)"))
                return
            }
            guard let responseData = data else {
                completionHandler(nil, DemoError.noResponse(reason: "Did not recieve data from API call"))
                return
            }
            do {
                guard let dataJSON = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: Any] else {
                        completionHandler(nil, DemoError.conversionFailed(reason: "Error trying to convert response data to JSON"))
                        return
                }
                if apppendix == nil {
                    guard let resultData = dataJSON[jsonKey] as? [String] else {
                        completionHandler(nil, DemoError.conversionFailed(reason: "Could not get results from JSON"))
                        return
                    }
                    results = resultData
                }
                else {
                    guard let resultData = dataJSON[jsonKey] as? String else {
                        completionHandler(nil, DemoError.conversionFailed(reason: "Could not get results from JSON"))
                        return
                    }
                    results.append(resultData)
                }
                completionHandler(results, nil)
                return
                
            } catch {
                completionHandler(nil, DemoError.conversionFailed(reason: "Error trying to convert data to JSON"))
                return
            }
        }
        task.resume()
    }
    
    private func downloadImageFromUrl(url: URL,
                         imageID: String,
                         completionHandler: @escaping (_ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                completionHandler(DemoError.couldNotFetch(reason: "Error fetching image data: \(error)"))
                return
            }
            guard let responseData = data else {
                completionHandler(DemoError.noResponse(reason: "Did not recieve image data from server"))
                return
            }
            print("Download for \(response?.suggestedFilename ?? url.lastPathComponent) finished")
            DispatchQueue.main.async() { () -> Void in
                guard let image = UIImage(data: responseData) else {
                    fatalError("Could not convert data to image")
                }
                DemoService.sharedDemoService.addNewImage(image: image,
                                                          imageID: imageID,
                                                          imageName: response?.suggestedFilename ?? url.lastPathComponent)
                completionHandler(nil)
            }
        }.resume()
    }
    
    // MARK: Collection View Delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let image = images[indexPath.row]
        if image.position < 0 {
            DemoService.sharedDemoService.setImagePosition(image: image, position: Int16(indexPath.row))
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imagesCollectionViewCell", for: indexPath) as! ImagesCollectionViewCell
        cell.tag = indexPath.row
        cell.imageView.image = UIImage(data: (image.data as Data?)!)
        
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
