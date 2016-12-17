//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Souji on 11/9/16.
//  Copyright © 2016 Souji. All rights reserved.
//

import Foundation
import CoreData
import MapKit

public class Pin: NSManagedObject {
    
    public var coordinate: CLLocationCoordinate2D {
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    convenience init(annotationLatitude: Double, annotationLongitude: Double, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context)!
        
        self.init(entity: entity, insertInto: context)
        
        latitude = annotationLatitude
        longitude = annotationLongitude
        self.pageNumber = 0
    }
}

extension Pin {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin");
    }
    
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var photos: Photos?
    @NSManaged public var title: String?
    @NSManaged var pageNumber: NSNumber?
    
   
}

// MARK: Generated accessors for photos
extension Pin {
    
    @objc(addPhotosObject:)
    @NSManaged public func addToPhotos(_ value: Photos)
    
    @objc(removePhotosObject:)
    @NSManaged public func removeFromPhotos(_ value: Photos)
    
    @objc(addPhotos:)
    @NSManaged public func addToPhotos(_ values: NSSet)
    
    @objc(removePhotos:)
    @NSManaged public func removeFromPhotos(_ values: NSSet)
    
}

