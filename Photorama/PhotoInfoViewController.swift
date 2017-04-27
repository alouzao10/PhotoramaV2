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
    
    // Setting up the view count and favorite labels
    // Also sets up the button to see if the user wants
    // to favorite the picture they are on.
    @IBOutlet var viewCnt: UILabel!
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
        // When you transition into the view, it will set the favorite
        // label based on if the photo has been previously favorited
        if photo.favoritePic == true {
            fave.text = "Favorite"
        }
        if photo.favoritePic == false{
            fave.text = ""
        }
        
        // Bronze pg 416
        // Every time the view is loaded it will increment the view count
        // and display the information to a label on the bottom bar
        photo.viewCount += 1
        viewCnt.text = "Views: \(photo.viewCount)"

        // The contents of the favorite and view count are saved for an image
        store.saveContextIfNeeded()
    }
    
    // Silver pg 436
    // A button fuction that will determine if the user want to favorite an image
    // Pre - The photo is assumed to not be favorited by the user and assign
    // the core data bool to false
    // Post - After the button press it will display that the photo has been 
    // favorited by the user and change the core data value to true which keeps track 
    // that the image has been favorited by the user
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

    // Transition to make the tags for an image and set the tags too
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
