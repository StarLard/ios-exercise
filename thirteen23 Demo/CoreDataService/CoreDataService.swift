//
//  CoreDataService.swift
//  thirteen23 Demo
//
//  Created by Caleb Friden on 8/26/17.
//  Copyright © 2017 Caleb Friden. All rights reserved.
//

import CoreData
import Foundation


public typealias SaveCompletionHandler = () -> Void


open class CoreDataService {
    open func saveRootContext(_ completionHandler: @escaping SaveCompletionHandler) {
        self.rootContext.perform() {
            do {
                try self.rootContext.save()
                
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHandler()
                })
            }
            catch let error {
                fatalError("Failed to save root context: \(error as NSError)")
            }
        }
    }
    
    // MARK: Initialization
    fileprivate init() {
        let bundle = Bundle.main
        
        guard let modelPath = bundle.url(forResource: CoreDataService.modelName, withExtension: "momd") else {
            fatalError("Could not find model file with name \"\(CoreDataService.modelName)\", please set CoreDataService.modelName to the name of the model file (without the file extension)")
        }
        
        guard let someManagedObjectModel = NSManagedObjectModel(contentsOf: modelPath) else {
            fatalError("Could not load model at URL \(modelPath)")
        }
        
        guard let documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first as NSString? else {
            fatalError("Could not find documents directory")
        }
        
        managedObjectModel = someManagedObjectModel
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        let storeRootPath = documentsDirectoryPath.appendingPathComponent("DataStore") as NSString
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: storeRootPath as String) {
            do {
                try fileManager.createDirectory(atPath: storeRootPath as String, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error {
                fatalError("Error creating data store directory \(error as NSError)")
            }
        }
        
        let persistentStorePath = storeRootPath.appendingPathComponent("\(CoreDataService.storeName).sqlite")
        let persistentStoreOptions = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: URL(fileURLWithPath: persistentStorePath), options: persistentStoreOptions)
        }
        catch let error {
            fatalError("Error creating persistent store \(error as NSError)")
        }
        
        rootContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        rootContext.persistentStoreCoordinator = persistentStoreCoordinator
        rootContext.undoManager = nil
        
        mainQueueContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        mainQueueContext.parent = rootContext
        mainQueueContext.undoManager = nil
    }
    
    // MARK: Properties
    open let mainQueueContext: NSManagedObjectContext
    
    // MARK: Properties (Private)
    fileprivate let managedObjectModel: NSManagedObjectModel
    fileprivate let persistentStoreCoordinator: NSPersistentStoreCoordinator
    fileprivate let rootContext: NSManagedObjectContext
    
    // MARK: Properties (Static)
    open static var modelName = "thirteen23_Demo"
    open static var storeName = "thirteen23_Demo"
    open static let sharedCoreDataService = CoreDataService()
}
