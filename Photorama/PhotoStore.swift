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
        
        let url = FlickrAPI.interestingPhotosURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request){
            (data, response, error) -> Void in
            let result = self.processPhotosRequest(data: data, error: error)
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }
    
    private func processPhotosRequest(data: Data?, error: Error?) -> PhotosResult{
        guard let jsonData = data else{
            return .failure(error!)
        }
        return FlickrAPI.photos(fromJSON: jsonData, into: persistentContainer.viewContext)
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
        let request = URLRequest(url: photoURL as URL)
        
        let task = session.dataTask(with: request){
            (data, response, error) -> Void in
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
    
}