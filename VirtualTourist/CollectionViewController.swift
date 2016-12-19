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
    @IBOutlet weak var collectionFlowLayOut: UICollectionViewFlowLayout!
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
        
        // Implemented flowLayout
        flowLayOut(size: self.view.frame.size)
        
        if imagePin.photos != nil {
            subView()
            imageInfoLabel.isHidden = true
            
        }
        
        let fetchRequest: NSFetchRequest<Photos> =  Photos.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "pin", ascending: true)]
        
        // limit the fetch to photos associated with the pin
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.imagePin);
        // Create the Fetched Results Controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        perFormFetch()
        fetchedResultsController.delegate = self
        
    }
    
    
    
    func subView(){
        
        let nib = UINib(nibName: "CollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "CollectionViewCell")
        
    }
    
    
    //initializing map
    func initMap(){
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: self.imagePin.latitude, longitude: self.imagePin.longitude)
        
        DispatchQueue.main.async {
            annotation.title = self.imagePin.title
            
            self.mapView.centerCoordinate = annotation.coordinate
            self.mapView.addAnnotation(annotation)
            
            // Display title of the annotation
            self.mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    
    func perFormFetch() {
        do {
            try fetchedResultsController.performFetch()
            
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
        
    }
    
    func flowLayOut(size:CGSize){
        
        let sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let space: CGFloat = 3.0
        let dimension1 = (view.frame.size.height - (2 * space))/3.0
        collectionFlowLayOut?.minimumInteritemSpacing = 0
        collectionFlowLayOut?.minimumLineSpacing = 0
        
        collectionFlowLayOut?.itemSize = CGSize(width: dimension1, height: dimension1)
    }
    
    
    // Collection View DataSource
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        imageInfoLabel.isHidden = fetchedResultsController.fetchedObjects?.count != 0
        return fetchedResultsController?.fetchedObjects?.count ?? 0
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Get reference to PhotoCell object at cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        
        if indexPath.row < imagePhotos.count  {
            sharedContext.performAndWait({
                cell.imageView.image = self.imagePhotos[self.imagePhotos.startIndex.advanced(by: indexPath.row)].storeImage()
            })
        }
        let photoObject = (fetchedResultsController?.object(at: indexPath))! as Photos
        print("The photos in photoobject are: ",photoObject)
        
        
        if  photoObject.images != nil {
            
            sharedContext.performAndWait {
                let imageURL = URL(string: (photoObject.url)!)
                let imageData = try? Data(contentsOf: imageURL!)
                cell.imageView.image = UIImage(data: imageData!)
                cell.imageView.isHidden = false
                cell.activityIndicator.isHidden = true
                cell.activityIndicator.stopAnimating()
                
            }
        } else {
            
            sharedContext.performAndWait {
                cell.imageView.image = UIImage(named: "placeholder")
                self.client.downloadPhotoImage((photoObject), completionHandler: { (data, error) in
                    if data != nil {
                        let image = UIImage(data: data!)
                        Client.Caches.imageCache.storeImage(image, withIdentifier: (photoObject.id)!)
                        cell.imageView.image = image
                        cell.activityIndicator.isHidden = true
                        cell.activityIndicator.stopAnimating()
                        cell.imageView.isHidden = false
                       photoObject.images = data! as NSData?
                        CoreDataStackController.sharedInstance().saveContext()
                        
                        
                    } else {
                        
                        print("There is no data",error)
                    }
                    
                })
                
            }
        }
        
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
        
        let photo = fetchedResultsController.object(at: indexPath as IndexPath)
       sharedContext.delete(photo)
        CoreDataStackController.sharedInstance().saveContext()
        perFormFetch()
        collectionView.reloadData()
    
    }
    
    
    // methods for retaining new set of images
    
    func downloadPhotos(){
        client.getPhotosFromLocation(pin: imagePin) { (photos, errorString) in
            if let errorString = errorString {
                print(errorString)
            } else {
                for image in photos {
                    print("The image in New Collection:", image)
                    _ = Photos(dictionary: image, pins: self.imagePin, context: self.sharedContext)
                    CoreDataStackController.sharedInstance().saveContext()
                }
                DispatchQueue.main.async {
                    
                    print("refresh images")
                    self.perFormFetch()
                    self.collectionView.reloadData()
                }
                
            }
            
        }
    }
    
    @IBAction func newCollectionButtonAction(_ sender: AnyObject) {
        
        newCollectionButton.isEnabled = false
        
        let pics = fetchedResultsController?.fetchedObjects
        for pic in pics! {
            
            if pic.pin != nil {
                
                sharedContext.delete(pic)
                Client.Caches.imageCache.deleteImages(pic.id!)
                CoreDataStackController.sharedInstance().saveContext()
                print("Photos deleted")
                
            }
            
        }
        
        self.downloadPhotos()
        
    }
    
    func setMapViewAnnotation(_ annotation: MKAnnotation) {
        self.annotation = annotation;
    }
    
    //Communicating data changes to the collection view
    
    private func controllerWillChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
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

