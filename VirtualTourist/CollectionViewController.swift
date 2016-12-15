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

    
    //initializing map
    func initMap(){
        
        let annotation = MKPointAnnotation()
        
        
         DispatchQueue.main.async {
            annotation.coordinate = CLLocationCoordinate2D(latitude: self.imagePin.latitude, longitude: self.imagePin.longitude)
            annotation.title = self.imagePin.title
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
    
    func subView(){
        
        
    }
    
    
    // Collection View DataSource
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return fetchedResultsController?.fetchedObjects?.count ?? 0
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Get reference to PhotoCell object at cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        //Cleaning the cell
        //  self.collectionView.deleteItems(at: [indexPath])
        // configureCell(cell: cell, indexPath: indexPath)
        let photoObject = (fetchedResultsController?.object(at: indexPath))! as Photos
        print("The photos in photoobject are: ",photoObject)
        
        if  photoObject.images != nil {
            
            let imageURL = URL(string: (photoObject.url)!)
            let imageData = try? Data(contentsOf: imageURL!)
            photoImageView = UIImageView(image: UIImage(data: imageData!)!)
            cell.imageView.image = photoImageView.image
            cell.imageView.isHidden = false
            cell.activityIndicator.isHidden = true
            cell.activityIndicator.stopAnimating()
        } else {
            cell.imageView.image = UIImage(named: "placeholder")
            client.downloadPhotoImage((photoObject), completionHandler: { (data, error) in
                if data != nil {
                DispatchQueue.main.async(execute: { () -> Void in
                    let image = UIImage(data: data!)
                    cell.imageView.image = image
                    Client.Caches.imageCache.storeImage(image, withIdentifier: (photoObject.id)!)
                    cell.activityIndicator.isHidden = true
                    cell.activityIndicator.stopAnimating()
                    cell.imageView.isHidden = false
                })
                } else {
                    
                    print("There is no data",error)
                }
            })
        }
        
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
            Client.Caches.imageCache.deleteImages(photo.id!)
            CoreDataStackController.sharedInstance().saveContext()
        }
        
        self.collectionView?.reloadData()
    }
    
   
    
    func refreshCollection(){
        
        sharedContext.perform{
            if self.imagePin.photos == nil {
                self.collectionView.alpha = 1.0
                self.imageInfoLabel.text = "No Images Found"
                self.imageInfoLabel.isHidden = false
                
            } else {
                self.collectionView.alpha = 0.0
                self.imageInfoLabel.isHidden = true

            }
        }
    }

    @IBAction func newCollectionButtonAction(_ sender: AnyObject) {
        
        newCollectionButton.isEnabled = false
        
        let pics = fetchedResultsController?.fetchedObjects
        
        for pic in pics! {
            
            if pic.pin != nil {
                
                deletePhotos()
                
                print("Photos deleted")
                // Empty the array after deletion
                CoreDataStackController.sharedInstance().saveContext()
            }
        }

        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
        client.getPhotosFromLocation(pin: imagePin) {(photos, errorString) in
         
            if errorString == nil {
                print(errorString)
                return
            } else {
                
                for photo in photos {
                    
                    DispatchQueue.main.async {
                        
                        Client.Caches.imageCache.imageWithIdentifier(photo.description)
                        CoreDataStackController.sharedInstance().saveContext()
                    }
                    
                    DispatchQueue.main.async (execute: {
                        
                        self.collectionView.reloadData()
                    
                        self.newCollectionButton.isEnabled = true
                    })
                }
            }
            
        }
    }
    func setMapViewAnnotation(_ annotation: MKAnnotation) {
        self.annotation = annotation;
    }
    
    //Communicating data changes to the collection view
    
    func controllerWillChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
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
    
    func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeObject anObject: AnyObject, atIndexPath indexPath: IndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
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
    
    func controllerDidChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
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

