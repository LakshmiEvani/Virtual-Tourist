//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Souji on 11/1/16.
//  Copyright © 2016 Souji. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import Foundation

class MapViewController: UIViewController, MKMapViewDelegate {
    
    //Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    
    // Properties
    var appDelegate: AppDelegate!
    var sharedContext: NSManagedObjectContext = CoreDataStackController.sharedInstance().managedObjectContext
    var pins = [Pin]()
    var photos = [Photos]()
    var client = Client.sharedInstance()
    
    
    //Load Map Region
    var savedRegionLoaded = false
    var editMode = false
    
    
    
    // Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        mapView.delegate = self
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.onLongPressGesture(_:)))
        longPressGesture.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGesture)
        addPinsToMap()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Update MapView
        if !savedRegionLoaded {
            if let savedRegion = UserDefaults.standard.object(forKey: "savedMapRegion") as? [String: Double] {
                
                let center = CLLocationCoordinate2D(latitude: savedRegion["mapRegionCenterLat"]!, longitude: savedRegion["mapRegionCenterLon"]!)
                let span = MKCoordinateSpan(latitudeDelta: savedRegion["mapRegionSpanLat"]!, longitudeDelta: savedRegion["mapRegionSpanLon"]!)
                mapView.region = MKCoordinateRegion(center: center, span: span)
            }
            savedRegionLoaded = true
        }
    }
    
    
    func addPinsToMap() {
        
        pins = getAllPins()
        print("Pin count in core data is \(pins.count)")
        
        for singlePin in pins{
            
            let annotation = MKPointAnnotation()
            let latitude = CLLocationDegrees(singlePin.latitude)
            let longitude = CLLocationDegrees(singlePin.longitude)
            let coordinate = CLLocationCoordinate2DMake(latitude , longitude )
            annotation.coordinate = coordinate
            annotation.title = singlePin.title
            
            DispatchQueue.main.async {
                
                //Adding annotation
                self.mapView.addAnnotation(annotation)
            }
            
        }
        
    }
    
    //getting all pins from coredata
    
    func getAllPins() -> [Pin] {
        
        var result = [Pin]()
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        do {
            result = try self.sharedContext.fetch(fetchRequest)
            
        } catch {
            
            print("Error in fetch results")
            
        }
        
        return result
        
    }
    
    //Region has Changes
    func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = self.mapView.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if (recognizer.state == UIGestureRecognizerState.began || recognizer.state == UIGestureRecognizerState.ended) {
                    return true
                }
            }
        }
        return false
    }
    
    //  Save Map Region
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        if mapViewRegionDidChangeFromUserInteraction() {
            let regionToSave = [
                "mapRegionCenterLat": mapView.region.center.latitude,
                "mapRegionCenterLon": mapView.region.center.longitude,
                "mapRegionSpanLat": mapView.region.span.latitudeDelta,
                "mapRegionSpanLon": mapView.region.span.longitudeDelta
            ]
            
            UserDefaults.standard.set(regionToSave, forKey: "savedMapRegion")
        }
    }
    
    //Adding Gestures
    
    func onLongPressGesture(_ sender: UIGestureRecognizer) {
        
        if Reachability.isConnectedToNetwork() {
            // Add pin only at the gestureRecognizer .Began state. This is to prevent duplicate pins from being added if the user continues to hold press.
            if UIGestureRecognizerState.began == sender.state {
                let touchPoint = sender.location(in: mapView)
                let newCoordinate: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = newCoordinate
                annotation.title = "New Location"
                
                let pin = Pin(annotationLatitude: annotation.coordinate.latitude, annotationLongitude: annotation.coordinate.longitude, context: sharedContext)
                // Adding the newPin to the map
                mapView.addAnnotation(annotation)
                
                CoreDataStackController.sharedInstance().saveContext()
                //Reverse geocoding is the process of turning a location’s coordinates into a human-readable address.
                CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)) {(placemarks, error) in
                    
                    
                    if error != nil  {
                        print("Reverse geocoder failed with error" + error!.localizedDescription)
                        return
                    }
                    self.getPicsForPin(pin)
                    self.pins.append(pin)
                    CoreDataStackController.sharedInstance().saveContext()
                    
                }
                
            }
            
            
        } else {
            
            let alertTitle = "No Internet Connection"
            let alertMessage = "Make sure your device is connected to the internet"
            let actionTitle = "OK"
            showAlert(alertTitle, alertMessage: alertMessage, actionTitle: actionTitle)
            
        }
    }
    
    //Get images for pin
    
    func getPicsForPin(_ pin: Pin) {
        client.getPhotosFromLocation(pin.coordinate) { (photos, errorString) in
            
            print("The photos count in get images", photos.count)
            if let errorString = errorString {
                print(errorString)
            } else {
                for image in photos {
                    print("The image is:", image)
                    let photo = Photos(dictionary: image, pins: pin, context: self.sharedContext)
                    CoreDataStackController.sharedInstance().saveContext()
                }
            }
        }
    }
    
    
    
    // Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier! {
        case "pinGallery":
            print("segue called")
            let dest = segue.destination as! CollectionViewController
            let pin = sender as! Pin
            dest.imagePin = pin
            
        default:
            print("Unknown segue")
        }
        
    }
    
    // MARK: - MKMapViewDelegate
    
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) as UIView
            
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews
    
    /*    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
     
     
     print("calloutAccessoryControlTapped")
     if control == view.rightCalloutAccessoryView {
     // Flickr images on callout
     
     self.performSegue(withIdentifier: "pinGallery", sender: view)
     CoreDataStackController.sharedInstance().saveContext()
     } else {
     let pin = view.annotation as! Pin
     mapView.removeAnnotation(view.annotation!)
     sharedContext.delete(pin)
     print("The Pin is deleted")
     CoreDataStackController.sharedInstance().saveContext()
     
     }
     }*/
    
    // This delegate method is implemented to respond to taps on the pin annotation.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let selectedAnnotation = view.annotation!
        // deselect the pin annotation
        mapView.deselectAnnotation(selectedAnnotation, animated: true)
        
        for pin in self.pins {
            
            if pin.latitude == selectedAnnotation.coordinate.latitude && pin.longitude == selectedAnnotation.coordinate.longitude {
                
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "pinGallery", sender: pin)
                    
                }
                CoreDataStackController.sharedInstance().saveContext()
            }
        }
    }
    
    
    /*   do {
     
     let latitude = view.annotation?.coordinate.latitude
     let longitude = view.annotation?.coordinate.longitude
     
     // Create Fetch Request
     let pinfetchRequest : NSFetchRequest<Pin> = NSFetchRequest(entityName: "Pin")
     pinfetchRequest.sortDescriptors = [NSSortDescriptor(key: "photos", ascending: true)]
     
     let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [latitude, longitude])
     pinfetchRequest.predicate = predicate
     
     
     var pin = try sharedContext.fetch(pinfetchRequest) as? [Pin]
     pins = [pin![0]]
     
     } catch {
     
     print("failed to get pin by object id")
     return
     }
     
     guard !self.isEditing else {
     mapView.removeAnnotation(view.annotation!)
     sharedContext.delete(pin)
     CoreDataStackController.sharedInstance().saveContext()
     return
     }
     
     let controller = storyboard!.instantiateViewController(withIdentifier: "CollectionViewController") as! CollectionViewController
     controller.mapView = mapView
     controller.imagePin = pin
     self.performSegue(withIdentifier: "pinGallery", sender: pin)
     
     
     */
    
    
    
    // Error help function
    func showAlert(_ alertTitle: String, alertMessage: String, actionTitle: String){
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    
}







