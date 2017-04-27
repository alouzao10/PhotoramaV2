//
//  PhotoInfoViewController.swift
//  Photorama
//
//  Created by Alex Louzao on 4/18/17.
//  Copyright © 2017 ALcsc2310. All rights reserved.
//

import UIKit

class PhotoInfoViewController: UIViewController{
    
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var setFavorite: UIToolbar!
    @IBOutlet var fave: UILabel!
    
    var photo: Photo!{
        didSet{
            navigationItem.title = photo.title
        }
    }
    var store: PhotoStore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        store.fetchImage(for: photo){ (result) -> Void in
            switch result{
            case let .success(image):
                self.imageView.image = image
            case let .failure(error):
                print("Error fetching image for photo: \(error)")
            }
        }
        
        // Silver pg 436
        // when you go back in the view it will set the tag if its been faved...
        if photo.favoritePic == true {
            fave.text = "Favorite"
            //setFavorite.tag = 1
        }
        if photo.favoritePic == false{
            fave.text = ""
            //setFavorite.tag = 0
        }
        
        
        // Bronze pg 416
        photo.viewCount += 1

        store.saveContextIfNeeded()
        
        let label = UILabel()
        label.text = "\(photo.viewCount) views"
        label.backgroundColor = UIColor.clear
        label.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(label)
        
        label.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: -8).isActive = true
        
    }
    
    // Silver pg 436
    @IBAction func setFavorite(_ sender: UIButton){
        // set the Core Data tag and the tag of button to detect a favorite image
        if sender.tag == 0 && photo.favoritePic == false{
            sender.tag = 1
            photo.favoritePic = true
            fave.text = "Favorite"
            store.saveContextIfNeeded()
        } else {
            sender.tag = 0
            photo.favoritePic = false
            fave.text = ""
            store.saveContextIfNeeded()
        }
        
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showTags"?:
            let navController = segue.destination as! UINavigationController
            let tagController = navController.topViewController as! TagsViewController
            
            tagController.store = store
            tagController.photo = photo
        default:
            preconditionFailure("Unexpected segue identifier")
        }
    }
    
}
