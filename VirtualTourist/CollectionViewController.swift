//
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Souji on 11/1/16.
//  Copyright © 2016 Souji. All rights reserved.
//


import Foundation
import CoreData
import UIKit
import MapKit

class  CollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    
    // Outlet
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var imageInfoLabel: UILabel!
    @IBOutlet weak var newCollectionButton: UIButton!
    // Images array
    var imagePin : Pin!
    
    var imagePhotos = [Photos]()
    
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    var selectedIndex = [IndexPath]()
    
    // Properties
    var client = Client.sharedInstance()
    var appDelegate: AppDelegate!
    var annotation: MKAnnotation!
    
    
    // Core Data Convenience. Useful for fetching, adding and saving objects
    var sharedContext: NSManagedObjectContext = CoreDataStackController.sharedInstance().managedObjectContext
    var fetchedResultsController: NSFetchedResultsController<Photos>!
    
    // Life Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        initMap()
        //TODO: Implement flowLayout here.
        flowLayOut(size: self.view.frame.size)
        
        
        let nib = UINib(nibName: "CollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "CollectionViewCell")
        
        
        let fetchRequest: NSFetchRequest<Photos> =  Photos.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "pin", ascending: true)]
        
        // limit the fetch to photos associated with the pin
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.imagePin);
        
        // Create the Fetched Results Controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
            
            print("fetchedResultsController after perform fetch",fetchedResultsController.fetchedObjects?.count)
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
        fetchedResultsController.delegate = self
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if imagePin != nil && imagePin.photos == nil {
            
            let noOfPhotos = Client.sharedInstance().numberOfPhotosDownloaded
            if noOfPhotos == 0 {
                
                newCollectionButton.isEnabled = false
            }
        }
        
        collectionView.reloadData()
    }
    
    
    //initializing map
    func initMap(){
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: self.imagePin.latitude, longitude: self.imagePin.longitude)
        annotation.title = self.imagePin.title
        DispatchQueue.main.async {
            self.mapView.centerCoordinate = annotation.coordinate
            self.mapView.addAnnotation(annotation)
        }
    }
    
    
    func flowLayOut(size:CGSize){
        
        let space: CGFloat = 3.0
        let dimension1 = (view.frame.size.height - (2 * space))/3.0
        
        flowLayout?.minimumInteritemSpacing = space
        flowLayout?.minimumLineSpacing = space
        flowLayout?.itemSize = CGSize(width: dimension1, height: dimension1)
    }
    
    
    // Collection View DataSource
    
    func configureCell(cell: CollectionViewCell, atIndexPath indexPath:IndexPath){
        
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        let photoObject = (fetchedResultsController?.object(at: indexPath))! as Photos
        
        
        if  photoObject.images != nil {
            print("The photos in photoobject are: ",photoObject)
            
            let imageURL = URL(string: (photoObject.description))
            let imageData = try? Data(contentsOf: imageURL!)
            photoImageView = UIImageView(image: UIImage(data: imageData!)!)
            cell.imageView.image = photoImageView.image
            cell.imageView.isHidden = false
            cell.activityIndicator.isHidden = true
            cell.activityIndicator.stopAnimating()
        } else {
            cell.imageView.image = UIImage(named: "placeholder")
            client.getPhotosFromLocation(pin: imagePin, completionHandler: { (photos, error) in
                if photos != nil {
                    
                    for photo in photos {
                    DispatchQueue.main.async(execute: { () -> Void in
                        let photodesc = URL(string: (photo.description))
                        let imageData = try? Data(contentsOf: photodesc!)
                        self.photoImageView = UIImageView(image: UIImage(data: imageData!)!)
                        cell.imageView.image = self.photoImageView.image
                        cell.activityIndicator.isHidden = true
                        cell.activityIndicator.stopAnimating()
                        cell.imageView.isHidden = false
                    })
                }
                } else {
                    
                    print(error)
                }
            })
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return fetchedResultsController?.fetchedObjects?.count ?? 0
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Get reference to PhotoCell object at cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        
        
        //Cleaning the cell
        // self.collectionView.deleteItems(at: [indexPath])
        configureCell(cell: cell, atIndexPath: indexPath)
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
        
        let photo = fetchedResultsController.object(at: indexPath as IndexPath)
        self.sharedContext.delete(photo)
        CoreDataStackController.sharedInstance().saveContext()
        
    }
    
    
    // methods for retaining new set of images
    func deletePhotos() {
        
        for photo in fetchedResultsController.fetchedObjects! {
            sharedContext.delete(photo)
            CoreDataStackController.sharedInstance().saveContext()
        }
    }
    func reFetchPin() {
        
        
        let managedContext = CoreDataStackController().managedObjectContext
        
        let photoFetch:NSFetchRequest<Photos> = Photos.fetchRequest()
        do {
            _ = try managedContext.fetch(photoFetch as! NSFetchRequest<NSFetchRequestResult>) as! [Photos]
            
        } catch {
            fatalError("Failed to fetch photo: \(error)")
        }
        
    }
    
    @IBAction func newCollectionButtonAction(_ sender: AnyObject) {
        
        let pics = fetchedResultsController?.fetchedObjects
        
        for pic in pics! {
            
            if pic.pin != nil {
                
                deletePhotos()
                
                print("Photos deleted")
                // Empty the array after deletion
                CoreDataStackController.sharedInstance().saveContext()
            }
            self.collectionView?.reloadData()
        }
        
        
        reFetchPin()
        client.getPhotosFromLocation(pin: imagePin) {(result, error) in
            
            if error == nil {
                print(error)
                return
            } else {
                
                DispatchQueue.main.async(execute: {
                    
                    CoreDataStackController.sharedInstance().saveContext()
                    
                })
                if self.imagePin.photos == nil {
                    
                    self.newCollectionButton.isEnabled = false
                    self.imageInfoLabel.isHidden = false
                    self.imageInfoLabel.text = "No Images Found"
                }    else {
                    
                    // Changing different page number
                    
                    var setPage = self.imagePin.pageNumber
                    var int : Int = Int(setPage!)
                    int += 1
                    setPage = NSNumber(value: int)
                    self.imagePin.pageNumber = setPage
                    
                    DispatchQueue.main.async (execute: {
                        if self.imagePhotos.count == 0 {
                            self.imageInfoLabel.text = "No Images Found"
                            self.imageInfoLabel.isHidden = false
                        } else {
                            self.imageInfoLabel.isHidden = true
                        }
                        self.collectionView.reloadData()
                        self.newCollectionButton.isEnabled = true
                    })
                }
            }
            
        }
    }
    
    
    
    ///fetchedResultsController = nil
    
    /*client.getPhotosFromLocation(pin: imagePin) {(result, error) in
     
     if self.imagePin.photos == nil {
     
     self.newCollectionButton.isEnabled = false
     self.imageInfoLabel.isHidden = false
     self.imageInfoLabel.text = "No Images Found"
     }    else {
     
     self.newCollectionButton.isEnabled = true
     self.imageInfoLabel.isHidden = true
     /* var setPage = self.imagePin.pageNumber
     var int : Int = Int(setPage!)
     int += 1
     setPage = NSNumber(value: int)*/
     var randomPageNumber: Int = 1
     
     if let numberPages = self.imagePin.pageNumber?.intValue {
     if numberPages > 0 {
     let pageLimit = min(numberPages, 20)
     randomPageNumber = Int(arc4random_uniform(UInt32(pageLimit))) + 1 }
     }
     
     print("The photos count in get images", result?.count)
     
     // self.imagePin.pageNumber = setPage
     
     DispatchQueue.main.async {
     self.collectionView?.reloadData()
     CoreDataStackController.sharedInstance().saveContext()
     }
     }*/
    
    
    
    /*  let pics = fetchedResultsController?.fetchedObjects
     
     for pic in pics! {
     
     if pic.pin != nil {
     
     deletePhotos()
     
     print("Photos deleted")
     // Empty the array after deletion
     CoreDataStackController.sharedInstance().saveContext()
     }
     self.collectionView?.reloadData()
     }
     
     reFetchPin()*/
    
    /* client.getPhotosFromLocation(pin: imagePin) {(result, error) in
     
     
     var randomPageNumber: Int = 1
     
     if let numberPages = self.imagePin.pageNumber?.intValue {
     if numberPages > 0 {
     let pageLimit = min(numberPages, 20)
     randomPageNumber = Int(arc4random_uniform(UInt32(pageLimit))) + 1 }
     }
     
     /*   self.numberOfPhotoDownloaded = (result?.count)!
     print("The photos count in get images", result?.count)
     
     var setPage = self.imagePin.pageNumber
     var int : Int = Int(setPage!)
     int += 1
     setPage = NSNumber(value: int)
     self.imagePin.pageNumber = setPage
     */
     
     }*/
    
    
    
    func setMapViewAnnotation(_ annotation: MKAnnotation) {
        self.annotation = annotation;
    }
    
    //Communicating data changes to the collection view
    
    private func controllerWillChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    private func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            collectionView.insertSections(NSIndexSet(index: sectionIndex) as IndexSet)
        case .delete:
            collectionView.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet)
        case .move:
            break
        case .update:
            break
        }
    }
    
    private func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeObject anObject: AnyObject, atIndexPath indexPath: IndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            insertedIndexPaths.append(newIndexPath! as IndexPath)
            break
        case .delete:
            deletedIndexPaths.append(indexPath! as IndexPath)
            break
        case .update:
            updatedIndexPaths.append(indexPath! as IndexPath)
            break
        case .move:
            print("Move an item. We don't expect to see this in this app.")
            break
        }
    }
    
    private func controllerDidChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
            }, completion: nil)
        
    }
    
    
    // Error help function
    func showAlert(_ alertTitle: String, alertMessage: String, actionTitle: String){
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
}
