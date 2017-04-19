//
//  ImageStore.swift
//  PhotoRama2

//  Created by Alex Louzao on 3/27/17.
//  Copyright © 2017 ALcsc2310. All rights reserved.
//

import UIKit

class ImageStore{
    
    let cache = NSCache<NSString,UIImage>()
    
    func setImage(_ image: UIImage, forKey key: String){
        cache.setObject(image, forKey: key as NSString)
        
        let url = imageURL(forKey: key)
        if let data = UIImagePNGRepresentation(image){
            let _ = try? data.write(to: url, options: [.atomic])
        }
    }
    
    func image(forKey key: String) -> UIImage? {
        //return cache.object(forKey: key as NSString)
        if let existingImage = cache.object(forKey: key as NSString){
            return existingImage
        }
        
        let url = imageURL(forKey: key)
        guard let imageFromDisk = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        
        cache.setObject(imageFromDisk, forKey: key as NSString)
        return imageFromDisk
        
    }
    
    func deleteImage(forKey key: String){
        cache.removeObject(forKey: key as NSString)
        
        let url = imageURL(forKey: key)
        //FileManager.default.removeItem(at: url)
        do {
            try FileManager.default.removeItem(at: url)
        } catch let deleteError{
            print("ERROR removing image from disk: \(deleteError)")
        }
    }
    
    func imageURL(forKey key: String) -> URL{
        let documentsDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        
        return documentDirectory.appendingPathComponent(key)
    }
    
}
