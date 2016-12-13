//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Souji on 11/20/16.
//  Copyright © 2016 Souji. All rights reserved.
//

import Foundation

import UIKit

class ImageCache {
    
 private var dataCache = NSCache<AnyObject, AnyObject>()
    
    //Retrieving images
    
    func imageWithIdentifier(_ identifier: String?) -> UIImage? {
        
            // If the identifier is nil, or empty, return nil
        
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        
          // First try the memory cache
        if let image = dataCache.object(forKey: path as AnyObject) as? UIImage {
            return image
        }
        
         // Next Try the hard drive
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    // Saving Images
    func storeImage(_ image: UIImage?, withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)
        
        // If the image is nil, remove images from the cache
        if image == nil {
            dataCache.removeObject(forKey: path as AnyObject)
            
            do{
                try FileManager.default.removeItem(atPath: path)
            }catch let error as NSError  {
                print(error)
            }
            
            return
        }
           // Otherwise, keep the image in memory
        dataCache.setObject(image!, forKey: path as AnyObject)
        let data = UIImagePNGRepresentation(image!)
        try? data!.write(to: URL(fileURLWithPath: path), options: [.atomic])
    }
    
    // MARK: deleting images
    func deleteImages(_ identifier: String){
        let path = pathForIdentifier(identifier)
        if FileManager.default.fileExists(atPath: path){
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {}
            print("deleted \(path)")
        }
    }
    
    //Helper Function
    func pathForIdentifier(_ identifier: String) -> String {
        let documentsDirectoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
        let fullURL = documentsDirectoryURL.appendingPathComponent(identifier)
        
        return fullURL.path
    }
}
