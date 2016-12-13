//
// Constants.swift
//  VirtualTourist
//
//  Created by Souji on 11/1/16.
//  Copyright © 2016 Souji. All rights reserved.
//

import Foundation

extension Client {
    
    // MARK: Flickr
    struct Constants {
        
    //Mark: Flickr baseurl
        static let baseURLSecureString = "https://api.flickr.com/services/rest/"
    
    }
    
    //MARK: -- Methods
    struct Methods{
        static let Session = "session"
        static let PhotosSearch = "flickr.photos.search"
    }
    
    // MARK: Flickr Parameter Keys
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let Page = "page"
        static let Latitude = "lat"
        static let Longitude = "lon"
    }
    
    // MARK: Flickr Parameter Values
    struct FlickrParameterValues {
        static let APIKey = "ae09165503b7de8421dff7d8f6ebe98c"
        static let Secret = "41ce569694470bb6"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
        static let GalleryID = "6065-72157617483228192"
        static let Extras = "url_m"
        static let Page = 20
    }
    
    // MARK: Flickr Response Keys
    struct FlickrResponseKeys {
        static let ID = "id"
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
    }
    
    // MARK: Flickr Response Values
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
    
    struct Caches {
        static let imageCache = ImageCache()
    }

}
