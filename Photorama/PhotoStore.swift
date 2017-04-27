//
//  PhotoStore.swift
//  Photorama
//
//  Created by Alex Louzao on 4/18/17.
//  Copyright © 2017 ALcsc2310. All rights reserved.
//

import UIKit
import CoreData

enum ImageResult {
    case success(UIImage)
    case failure(Error)
}

enum PhotoError: Error{
    case imageCreationError
}

enum PhotosResult{
    case success([Photo])
    case failure(Error)
}

enum TagsResult{
    case success([Tag])
    case failure(Error)
}

class PhotoStore{
    
    let imageStore = ImageStore()
    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Photorama")
        container.loadPersistentStores { (description, error) in
            if let error = error {
                print("ERROR setting up Core Data (\(error))")
            }
        }
        return container
    }()
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    func fetchInterestingPhotos(completion: @escaping (PhotosResult) -> Void){
        // Silver pg 275
        let url = FlickrAPI.interestingPhotosURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request){
            (data, response, error) -> Void in
            
            // Bronze pg 375
            // Prints out the information of each image as the interesting images are loading
            if let status = response as? HTTPURLResponse {
                print("Fetch Interesting Photos")
                print("statusCode is \(status.statusCode)")
                print("Header fields are \(status.allHeaderFields)")
                
            }
            
            self.processPhotosRequest(data: data, error: error) {
                (result) in
                OperationQueue.main.addOperation {
                    completion(result)
                }
            }
        }
        task.resume()
    }
    func fetchRecentPics(completion: @escaping (PhotosResult) -> Void){
        // Silver pg 275
        let url = FlickrAPI.recentPhotosURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request){
            (data, response, error) -> Void in
            
            // Bronze pg 375
            // Prints out the information of each image as the recent images are loading
            if let status = response as? HTTPURLResponse {
                print("Fetch Recent Photos")
                print("statusCode is \(status.statusCode)")
                print("Header fields are \(status.allHeaderFields)")
                
            }
            
            self.processPhotosRequest(data: data, error: error) {
                (result) in
                OperationQueue.main.addOperation {
                    completion(result)
                }
            }
        }
        task.resume()
    }
    
    private func processPhotosRequest(data: Data?, error: Error?, completion: @escaping (PhotosResult) -> Void){
        guard let jsonData = data else{
            completion(.failure(error!))
            return
        }
        persistentContainer.performBackgroundTask {
            (context) in
            let result = FlickrAPI.photos(fromJSON: jsonData, into: context)
            
            do {
                try context.save()
            } catch {
                print("ERROR saving core data : \(error)")
                completion(.failure(error))
                return
            }
            
            switch result {
            case let .success(photos):
                let photoIDs = photos.map { return $0.objectID }
                let viewContext = self.persistentContainer.viewContext
                let viewContextPhotos = photoIDs.map { return viewContext.object(with: $0) } as! [Photo]
                completion(.success(viewContextPhotos))
            case .failure:
                completion(result)
            }
        }
    }
    
    func fetchImage(for photo: Photo, completion: @escaping (ImageResult)->Void){
        
        guard let photoKey = photo.photoID else {
            preconditionFailure("Photo expected to have a photoID.")
        }
        if let image = imageStore.image(forKey: photoKey){
            OperationQueue.main.addOperation {
                completion(.success(image))
            }
            return
        }
        
        guard let photoURL = photo.remoteURL else {
            preconditionFailure("Photo expected to have a remote URL")
        }
        let request = URLRequest(url: photoURL as! URL)
        
        let task = session.dataTask(with: request){
            (data, response, error) -> Void in
            
            /* Bronze pg 375
            // Prints out the information of each image
            if let status = response as? HTTPURLResponse {
                print("Fetching Image")
                print("statusCode is \(status.statusCode)")
                print("Header fields are \(status.allHeaderFields)")
                print("")
            }*/
            
            let result = self.processImageRequest(data: data, error: error)
            if case let .success(image) = result{
                self.imageStore.setImage(image, forKey: photoKey)
            }
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }
    
    private func processImageRequest(data: Data?, error: Error?) -> ImageResult{
        guard
            let imageData = data,
            let image = UIImage(data: imageData)
            else {
                if data == nil{
                    return .failure(error!)
                } else {
                    return .failure(PhotoError.imageCreationError)
                }
        }
        return .success(image)
    }
    
    func fetchAllPhotos(completion: @escaping (PhotosResult) -> Void) {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortByDateTaken = NSSortDescriptor(key: #keyPath(Photo.dateTaken), ascending: true)
        fetchRequest.sortDescriptors = [sortByDateTaken]
        
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do{
                let allPhotos = try viewContext.fetch(fetchRequest)
                completion(.success(allPhotos))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func fetchAllTags(completion: @escaping (TagsResult) -> Void) {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        let sortByName = NSSortDescriptor(key: #keyPath(Tag.name), ascending: true)
        fetchRequest.sortDescriptors = [sortByName]
        
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do {
                let allTags = try fetchRequest.execute()
                completion(.success(allTags))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // Bronze pg 416
    // This function will save the contents for the view count and the favorite information
    // Pre - As the information for the favorite and view count fields have been updated they
    // need to be stored so that the core data can track their values for a particular image 
    // through out the execution of the app and while it is closed
    // Post - Stores the values for the view count and favorites boolean to keep track 
    // about the image during execution and while the app is closed.
    func saveContextIfNeeded() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            print("Save context")
            try? context.save()
        }
    }
    
}
