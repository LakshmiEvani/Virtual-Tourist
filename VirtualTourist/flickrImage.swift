//
//  FlickrImage.swift
//  VirtualTourist
//
//  Created by Souji on 11/12/16.
//  Copyright © 2016 Souji. All rights reserved.
//

import Foundation
import UIKit
import MapKit

struct  FlickrImage {
    
    var url : String?
    let id: String?
    let title: String?
   
    init(photos : [String:AnyObject]) {
        
        id = photos[Client.FlickrResponseKeys.ID] as? String
        title = photos[Client.FlickrResponseKeys.Title] as? String
        url = photos[Client.FlickrResponseKeys.MediumURL] as? String
       
}
    
    static func photosFromResults(results: [[String:AnyObject]]) -> [FlickrImage] {
        
        var FlickrPhotos = [FlickrImage]()
        
        // iterate through array of dictionaries, each Student is a dictionary
        for result in results {
            FlickrPhotos.append(FlickrImage(photos: result))
        }
        return FlickrPhotos
    }
    
}
