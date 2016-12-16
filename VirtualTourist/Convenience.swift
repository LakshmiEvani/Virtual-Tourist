//
//  Convenience.swift
//  VirtualTourist
//
//  Created by Souji on 12/13/16.
//  Copyright © 2016 Souji. All rights reserved.
//

import Foundation
import CoreData

extension Client {
    
    
    // MARK: Flickr API
    
    func getPhotosFromLocation(pin: Pin, completionHandler: @escaping (  _ photos: [[String: AnyObject]], _ errorString: String?) -> Void){
        
        var randomPageNumber: Int = 1
        
        if let numberPages = pin.pageNumber?.intValue {
            if numberPages > 0 {
                let pageLimit = min(numberPages, 20)
                randomPageNumber = Int(arc4random_uniform(UInt32(pageLimit))) + 1 }
        }
        
        // Specific Parameters for photos request       l
        
        let parameters : [String:AnyObject] = [

            FlickrParameterKeys.Method : Methods.PhotosSearch as AnyObject,
            FlickrParameterKeys.APIKey : FlickrParameterValues.APIKey as AnyObject,
            FlickrParameterKeys.Extras : FlickrParameterValues.Extras as AnyObject,
            FlickrParameterKeys.Format : FlickrParameterValues.ResponseFormat as AnyObject,
            FlickrParameterKeys.NoJSONCallback : FlickrParameterValues.DisableJSONCallback as AnyObject,
            FlickrParameterKeys.Page : randomPageNumber as AnyObject,
            FlickrParameterKeys.GalleryID : FlickrParameterValues.GalleryID as AnyObject,
            FlickrParameterKeys.Latitude: pin.latitude as AnyObject,
            FlickrParameterKeys.Longitude: pin.longitude as AnyObject,
            FlickrParameterKeys.PerPage : 15 as AnyObject
            ]
        
        
        taskForGetMethodWithParameters(methodParameters: parameters, completionHandler: {
            results, error in
            
            if let error = error {
                completionHandler([], "Could not get results. in result")
            
            } else {
                
                // Response dictionary
                if let photosDictionary = results?.value(forKey: FlickrResponseKeys.Photos) as? [String: AnyObject],
                    let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String : AnyObject]],
                    let numberOfPhotoPages = photosDictionary[FlickrResponseKeys.Pages] as? Int {
                    
                    pin.pageNumber = numberOfPhotoPages as NSNumber?
                    
                    
                    // Dictionary with photos
                    for photoDictionary in photosArray {
                        
                        
                        // Create the Photos model
                        let newPhoto = Photos(dictionary: photoDictionary, pins: pin, context: self.sharedContext)
                        
        
                    }
                    
                    completionHandler(photosArray, nil)

                } else {
                    
                    completionHandler([], "Could not get results. in result")
                }
            }
        })

    }
    
    // Download save image
    func downloadPhotoImage(_ photo: Photos, completionHandler: @escaping (_ imageData:Data?, _ error:NSError?) -> Void) {
        
        let imageURLString = photo.url
        
        // Make GET request for download photo by url
        
        taskForGETMethod(imageURLString!, completionHandler: { (result, error) in
        
                // check for failure
                guard error == nil else {
                    completionHandler(nil, error)
                    return
                }
                
                completionHandler(result, nil)
        })
    }
    
    
    
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackController.sharedInstance().managedObjectContext
    }
    
}
