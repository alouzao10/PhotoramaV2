//
//  PhotosViewController.swift
//  Photorama
//
//  Created by Alex Louzao on 4/18/17
//  Copyright © 2017 ALcsc2310. All rights reserved.
//

import UIKit

class PhotosViewController: UIViewController, UICollectionViewDelegate{
    
    // Set up buttons to get the interesting images or recent images
    @IBOutlet var recentPics: UIBarButtonItem!
    @IBOutlet var interestingPics: UIBarButtonItem!
    
    // Attempted to display the favorited image like the interesting and recent
    // Accessing the pictures and display those with the true favorite tag
    // @IBOutlet var showFavorite: UIBarButtonItem!

    //@IBOutlet var imageView: UIImageView!
    @IBOutlet var collectionView: UICollectionView!
    var store = PhotoStore()
    let photoDataSource = PhotoDataSource()
    
    // Once the view loads it sets up the information for the photo source
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = photoDataSource
        collectionView.delegate = self
        
        updateDataSource()
    }
    
    // Silver pg 375
    // If the button for intersting pictures has been pressed then it will
    // call a function to send the request to retrieve the interesting pictures
    @IBAction func getIntersting(_ sender: UIButton){
        viewDidLoad()
        store.fetchInterestingPhotos {
            (photosResult) -> Void in
            self.updateDataSource()
        }
        print("GETTING INTERESTING")
        
        
    }
    // Silver pg 375
    // If the button for recent pictures has been pressed then it will
    // call a function to send the request to retrieve the recent pictures
    @IBAction func getRecent(_ sender: UIButton){
        viewDidLoad()
        store.fetchRecentPics {
            (photosResult) -> Void in
            self.updateDataSource()
        }
        print("GETTING RECENT")
        
    }
    
    // Silver pg 436
    // Attempted to load the Pictures that were set to favorite just like
    // how the recent and interesting pictures were loaded into view
    /*var photo = Photo()
    @IBAction func getFavorites(_ sender: UIButton){
        viewDidLoad()
        store.fetchFavorites(for: photo) {
            (photosResult) -> Void in
            self.updateDataSource()
        }
        print("GETTING Favorites")
        
    }*/
    

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath){
        let photo = photoDataSource.photos[indexPath.row]
        store.fetchImage(for: photo) { (result) -> Void in
            guard let photoIndex = self.photoDataSource.photos.index(of: photo),
                case let .success(image) = result else {
                    return
            }
            let photoIndexPath = IndexPath(item: photoIndex, section: 0)
            
            if let cell = self.collectionView.cellForItem(at: photoIndexPath) as? PhotoCollectionViewCell{
                cell.update(with: image)
            }
        }
    }
    
    // makes the transition to view the image by itself where the user can 
    // set the favorite tag, see the view coung, and set tags for the image
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        switch segue.identifier{
        case "showPhoto"?:
            if let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first{
                let photo = photoDataSource.photos[selectedIndexPath.row]
                let destinationVC = segue.destination as! PhotoInfoViewController
                destinationVC.photo = photo
                destinationVC.store = store
            }
        default:
            preconditionFailure("Unexpected segue indentifier")
        }
    }
    
    // updates the data source of the image once the image is loaded
    private func updateDataSource(){
        store.fetchAllPhotos { (photosResult) in
            switch photosResult {
            case let .success(photos):
                self.photoDataSource.photos = photos
            case .failure:
                self.photoDataSource.photos.removeAll()
            }
            self.collectionView.reloadSections(IndexSet(integer: 0))
        }
    }
}

// Silver pg 401
// Adds new functionality to the class to alter the initial layout of images
// It will update the current layout of the images to only show 4 images
// per row and resize the images to always fit within the layout row.
    extension PhotosViewController: UICollectionViewDelegateFlowLayout {
        
        // Sets the new collection view and resizes the images to fit 4 per row
        func collectionView(_ collectionView: UICollectionView,
                            layout collectionLayout: UICollectionViewLayout,
                            sizeForItemAt indexPath: IndexPath) -> CGSize {
            
            let viewWidth = collectionView.bounds.size.width
            let numImgRow: CGFloat = 4
            let imgW = viewWidth / numImgRow
            return CGSize(width: imgW, height: imgW)
        }

        // Once the new layout is set, it will reload the data of the collection view
        // to display the new layout with 4 images per row and sesized images displayed
        override func viewWillTransition(to size: CGSize,
                                         with coordinator: UIViewControllerTransitionCoordinator){
            collectionView.reloadData()
        }
    }






