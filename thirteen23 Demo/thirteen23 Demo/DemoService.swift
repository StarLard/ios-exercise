//
//  DemoService.swift
//  thirteen23 Demo
//
//  Created by Caleb Friden on 8/26/17.
//  Copyright © 2017 Caleb Friden. All rights reserved.
//

import CoreData
import CoreDataService
import Foundation
import UIKit

class DemoService {
    
    // MARK: Service
    
    func imagesAreLoaded() -> Bool {
        
        let context = CoreDataService.sharedCoreDataService.mainQueueContext
        
        do {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Image.fetchRequest()
            let count  = try context.count(for: fetchRequest)
            return count == 0 ? false : true
        } catch {
            return true
        }
        
    }
    
    func getImages() -> [Image] {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Image.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
        
        let context = CoreDataService.sharedCoreDataService.mainQueueContext
        do {
            let fetchedImages = try context.fetch(fetchRequest) as! [Image]
            return fetchedImages
        } catch {
            fatalError("Failed to fetch images: \(error)")
        }
    }
    
    func addNewImage(image: UIImage, position: Int16 = -1) {
        let context = CoreDataService.sharedCoreDataService.mainQueueContext
        
        if let imageData = UIImagePNGRepresentation(image) {
            let imageEntity = NSEntityDescription.insertNewObject(forEntityName: "Image", into: context) as! Image
            imageEntity.data = imageData as NSData
            imageEntity.position = position
        }
        do {
            try context.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
        CoreDataService.sharedCoreDataService.saveRootContext {
            print("New image item saved")
        }
    }
    
    func setImagePosition(image: Image, position: Int16) {
        let context = CoreDataService.sharedCoreDataService.mainQueueContext
        
        image.position = position
        
        do {
            try context.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
        CoreDataService.sharedCoreDataService.saveRootContext {
            print("Image position changes saved")
        }
    }
    
    // MARK: Initialization
    fileprivate init() {
        
        let context = CoreDataService.sharedCoreDataService.mainQueueContext
        context.performAndWait {}
    }
    
    // MARK: Properties (Static)
    static let sharedDemoService = DemoService()
}
