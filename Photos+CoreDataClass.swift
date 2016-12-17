//
//  Photos+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Souji on 11/9/16.
//  Copyright © 2016 Souji. All rights reserved.
//

import Foundation
import CoreData
import UIKit

public class Photos: NSManagedObject {
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    var getImage:  UIImage?{
        get { return Client.Caches.imageCache.imageWithIdentifier(id) }
        set { Client.Caches.imageCache.storeImage(newValue, withIdentifier: id!)}
    }
    
    //Make photo object from flickr search results
    convenience init(dictionary: [String:AnyObject], pins: Pin, context: NSManagedObjectContext) {
        
        print("Count in dictionary in Photos",dictionary.count)
        let entity = NSEntityDescription.entity(forEntityName: "Photos", in: context)
        self.init(entity: entity!, insertInto: context)
        
        title = dictionary["title"] as? String
        id = dictionary["id"] as? String
        url = dictionary["url_m"] as? String
        self.pin = pins
       try! context.save()
        
    }
    
     
    //Delete the associated image file when the Photo managed object is deleted.
    
    override public func prepareForDeletion() {
        Client.Caches.imageCache.deleteImages(id!)
    }
    
   
}
extension Photos {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photos> {
        return NSFetchRequest<Photos>(entityName: "Photos");
    }
    
    @NSManaged public var images: NSData?
    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var pin: Pin?
    @NSManaged public var id: String?
}
