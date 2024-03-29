//
//  FlickrAPI.swift
//  Photorama
//
//  Created by Alex Louzao on 4/18/17.
//  Copyright © 2017 ALcsc2310. All rights reserved.
//

import Foundation
import CoreData

enum FlickrError: Error{
    case invalidJSONData
}

enum Method: String {
    // Silver pg 375
    // Setting the cases to either retrieve the interesting photos or
    // recent photos that have been determined by the button press
    case interestingPhotos = "flickr.interestingness.getList"
    case recentPhotos = "flickr.photos.getRecent"
}

struct FlickrAPI{

    private static let baseUrlString = "https://api.flickr.com/services/rest"
    private static let apikey = "a6d819499131071f158fd740860a5a88"
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    private static func photo(fromJSON json: [String: Any], into context: NSManagedObjectContext) -> Photo? {
        guard
            let photoID = json["id"] as? String,
            let title = json["title"] as? String,
            let dateString = json["datetaken"] as? String,
            let photoURLString = json["url_h"] as? String,
            let url = URL(string: photoURLString),
            let dateTaken = dateFormatter.date(from: dateString) else {
                return nil
        }
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "\(#keyPath(Photo.photoID)) == \(photoID)")
        fetchRequest.predicate = predicate
        
        var fetchedPhotos: [Photo]?
        context.performAndWait {
            fetchedPhotos = try? fetchRequest.execute()
        }
        if let existingPhoto = fetchedPhotos?.first {
            return existingPhoto
        }
        
        var photo: Photo!
        context.performAndWait{
            photo = Photo(context: context)
            photo.title = title
            photo.photoID = photoID
            photo.remoteURL = url as NSURL
            photo.dateTaken = dateTaken as NSDate
            // Bronze pg 416
            // Sets the viewCount value which was added as an attribute in the core data
            photo.viewCount = 0
            // Silver pg 436
            // Sets the favoritePic bool which was added as an attribute in the core data
            photo.favoritePic = false
        }
        return photo
    }
    
    private static func flickrURL(method: Method, parameters: [String:String]?) -> URL{
        
        var components = URLComponents(string: baseUrlString)!
        var queryItems = [URLQueryItem]()
        let baseParams = ["method": method.rawValue, "format": "json", "nojsoncallback": "1", "api_key": apikey]
        for (key, value) in baseParams {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        if let additionalParams = parameters{
            for (key, value) in additionalParams{
                let item = URLQueryItem(name: key, value: value)
                queryItems.append(item)
            }
        }
        components.queryItems = queryItems
        return components.url!
        
    }
    
    static var interestingPhotosURL: URL {
        return flickrURL(method: .interestingPhotos, parameters: ["extras": "url_h, date_taken"])
    }
    static var recentPhotosURL: URL {
        return flickrURL(method: .recentPhotos, parameters: ["extras": "url_h, date_taken"])
    }
    
    static func photos(fromJSON data: Data, into context: NSManagedObjectContext) -> PhotosResult{
        do{
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard
                let jsonDictionary = jsonObject as? [AnyHashable:Any],
                let photos = jsonDictionary["photos"] as? [String:Any],
                let photosArray = photos["photo"] as? [[String:Any]] else{
                    return .failure(FlickrError.invalidJSONData)
            }
            var finalPhotos = [Photo]()
            for photoJSON in photosArray{
                if let photo = photo(fromJSON: photoJSON, into: context){
                    finalPhotos.append(photo)
                }
            }
            if finalPhotos.isEmpty && !photosArray.isEmpty{
                return .failure(FlickrError.invalidJSONData)
            }
            return .success(finalPhotos)
        } catch let error{
            return .failure(error)
        }
    }

}
