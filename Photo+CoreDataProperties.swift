//
//  Photo+CoreDataProperties.swift
//  Photorama
//
//  Created by Alex Louzao on 4/21/17.
//  Copyright © 2017 ALcsc2310. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var dateTaken: NSDate?
    @NSManaged public var photoID: String?
    @NSManaged public var remoteURL: NSObject?
    @NSManaged public var title: String?

}
