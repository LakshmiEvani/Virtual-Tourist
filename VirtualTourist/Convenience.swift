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
            FlickrParameterKeys.Longitude: pin.longitude as AnyObject
            ]
        
        
        taskForGetMethodWithParameters(methodParameters: parameters, completionHandler: {
            results, error in
            
            if let error = error {
                completionHandler([], "Could not get results. in result")            } else {
                
                // Response dictionary
                if let photosDictionary = results?.value(forKey: FlickrResponseKeys.Photos) as? [String: AnyObject],
                    let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String : AnyObject]],
                    let numberOfPhotoPages = photosDictionary[FlickrResponseKeys.Pages] as? Int {
                    
                    pin.pageNumber = numberOfPhotoPages as NSNumber?
                    
                    
                    // Dictionary with photos
                    for photoDictionary in photosArray {
                        
                        guard let photoURLString = photoDictionary[FlickrResponseKeys.MediumURL] as? String else {
                            print ("error, photoDictionary)"); continue}
                        
                        // Create the Photos model
                        let newPhoto = Photos(dictionary: photoDictionary, pins: pin, context: self.sharedContext)
                        
        
                        // Download photo by url
                        self.downloadPhotoImage(newPhoto, completionHandler: {
                            success, error in
        
                            
                            // Posting NSNotifications
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "downloadPhotoImage.done"), object: nil)
                            
                            // Save the context
                            DispatchQueue.main.async(execute: {
                                CoreDataStackController.sharedInstance().saveContext()
                            })
                        })
                    }
                    
                    completionHandler(photosArray, nil)

                } else {
                    
                    completionHandler([], "Could not get results. in result")
                }
            }
        })

    }
    
    // Download save image and change file path for photo
    func downloadPhotoImage(_ photo: Photos, completionHandler: @escaping (_ imageData:Data?, _ error:NSError?) -> Void) {
        
        let imageURLString = photo.url
        
        // Make GET request for download photo by url
        
        taskForGETMethod(imageURLString!, completionHandler: { (result, error) in
            
            // If there is an error - set file path to error to show blank image
            if let error = error {
                print("Error from downloading images \(error.localizedDescription )")
                completionHandler(nil, error)
                
            } else {
                
                // Get file name and file url
                let fileName = (imageURLString! as NSString).lastPathComponent
                let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let pathArray = [dirPath, fileName]
                let fileURL = NSURL.fileURL(withPathComponents: pathArray)!
                //print(fileURL)
                
                // Save file
                FileManager.default.createFile(atPath: fileURL.path, contents: result, attributes: nil)
                
                // Update the Photos model
                photo.url = fileURL.path
                completionHandler(result, nil)

            }
        })
    }
    
    
    
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackController.sharedInstance().managedObjectContext
    }
    
}