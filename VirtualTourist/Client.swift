//
//  Client.swift
//  VirtualTourist
//
//  Created by Souji on 11/10/16.
//  Copyright © 2016 Souji. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class Client: NSObject {
    // MARK: Properties
    
    // Shared session
    var session: URLSession
    
    
    // MARK: Initializers
    
    override init() {
        session = URLSession.shared
        super.init()
    }
    
    // MARK: Flickr API
    
    func getPhotosFromLocation(_ coordinate: CLLocationCoordinate2D, completionHandler: @escaping ( _ photos: [[String: AnyObject]], _ errorString: String?) -> Void) {
        // Specify parameters
        let parameters : [String:AnyObject] = [
            Client.FlickrParameterKeys.Latitude: coordinate.latitude as AnyObject,
            Client.FlickrParameterKeys.Longitude: coordinate.longitude as AnyObject,
            ]
        
        
        // Make the request
        
      taskForGetMethod(methodParameters: parameters) { (result, error) in
        
            print("The result is:", result?.count)
    
        
            if error != nil {
                
                completionHandler([], "could not get results.")
            } else {
                
            // Send the value(s) to the completion handler
                if result != nil {
                    
                    if let dictionary = result?[Client.FlickrResponseKeys.Photos] as? NSDictionary {
                        if let results = dictionary[Client.FlickrResponseKeys.Photo] as? [[String: AnyObject]]{
                            
                            completionHandler(results, nil)
                        } else {
                            print("Could not find \(Client.FlickrResponseKeys.Photo) in \(dictionary)")
                            completionHandler([], "Could not get results in dict.")
                        }

                        } else {
                        print("Could not find \(Client.FlickrResponseKeys.Photos) in \(result)")
                        completionHandler([], "Could not get results. in result")
                    }
                } else {
                    print(error)
                    completionHandler([], "Request Failed.")
                }
            
            }
      
        }
        
    }

    
    //Get Method
    
    func taskForGetMethod(methodParameters: [String:AnyObject], completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        var mutableParameters = methodParameters
        mutableParameters[FlickrParameterKeys.Method] = method as AnyObject
        mutableParameters[FlickrParameterKeys.Method] = FlickrParameterValues.GalleryPhotosMethod as AnyObject?
        mutableParameters[FlickrParameterKeys.APIKey] = FlickrParameterValues.APIKey as AnyObject?
        mutableParameters[FlickrParameterKeys.Extras] = FlickrParameterValues.Extras as AnyObject?
        mutableParameters[FlickrParameterKeys.Format] = FlickrParameterValues.ResponseFormat as AnyObject?
        mutableParameters[FlickrParameterKeys.NoJSONCallback] = FlickrParameterValues.DisableJSONCallback as AnyObject?
        mutableParameters[FlickrParameterKeys.Page] = FlickrParameterValues.Page as AnyObject?
        mutableParameters[FlickrParameterKeys.GalleryID] = FlickrParameterValues.GalleryID as AnyObject?
        
        // Build and configure GET request
        let loginURL = Constants.baseURLSecureString + Client.escapedParameters(mutableParameters)
        let url = URL(string: loginURL)
        let request = URLRequest(url: url!)

        // Make the request
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
            
            // GUARD: Was there an error
            guard error == nil else {
                let userInfo = [NSLocalizedDescriptionKey: "There was an error with your request: \(error)"]
                completionHandler(nil, NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                return
            }
            
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? HTTPURLResponse {
                    let userInfo = [NSLocalizedDescriptionKey: "Your Request returned an invalid respons! Status code: \(response.statusCode)!"]
                    completionHandler(nil, NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                } else if let response = response {
                    let userInfo = [NSLocalizedDescriptionKey: "Your request returned an invalid response! Response: \(response)!"]
                    completionHandler(nil, NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                } else {
                    let userInfo = [NSLocalizedDescriptionKey: "Your request returned an invalid response!"]
                    completionHandler(nil, NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                }
                return
            }
            
            // GUARD: Was there any data returned?
            guard let data = data else {
                let userInfo = [NSLocalizedDescriptionKey: "No data was returned by the request!"]
                completionHandler(nil, NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                return
            }
            
            // Parse and use data
            
            Client.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
        
        })
        
        //start the request
        task.resume()
        return task
        
    }
    
    
    //Download photos
    
    func downloadImages(_ imageLocation: String, completionHandlerForImageJob: @escaping (_ imageFile: Data?, _ error: NSError?) -> ()) -> URLSessionTask {
        
        
        let sessionConfiguration = URLSessionConfiguration.default
        _ = URLSession(configuration: sessionConfiguration)
        let request = NSMutableURLRequest(url: URL(string: imageLocation)!)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
            (resultData, responseString, errorString) in
            
            print("Resultdata from downloads: ",resultData)
            if let error = errorString {
                completionHandlerForImageJob(nil, error as NSError?)
            } else {
                completionHandlerForImageJob(resultData, nil)
            }
        })
        
        task.resume()
        
        return task
    }
    


    /* Helper: Given raw JSON, return a usable Foundation object */
    
    class func parseJSONWithCompletionHandler(_ data: Data, completionHandler: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as AnyObject!
        } catch {
            
            let userInfo = [NSLocalizedDescriptionKey: "Could not parse the data as JSON: '\(data)'"]
            completionHandler(nil, NSError(domain: "parseJSONWithCompletionHandler", code: 1, userInfo: userInfo))

        }
        completionHandler(parsedResult, nil)
    }
    
    // Helper function: Given a dictionary of parameters, convert to a string for a url
    class func escapedParameters(_ parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            //Make sure that it is a string value
            let stringValue = "\(value)"
            
            //Escape it
            let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            
            // Append it
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joined(separator: "&")
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> Client {
        
        struct Singleton {
            static var sharedInstance = Client()
        }
        
        return Singleton.sharedInstance
    }
    
    
 }


