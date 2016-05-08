//
//  FirstViewController.swift
//  VGNMonitor
//
//  Created by Torsten Wauer on 13/12/15.
//  Copyright © 2015 twdorado. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import SwiftyJSON

class StopViewController: UITableViewController, UISearchResultsUpdating {
    
    var filteredStops = [Stop]()
    var savedStops = [NSManagedObject]()
    var resultSearchController = UISearchController()
    var selectedStop = Stop(name: "", id: "")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.resultSearchController = UISearchController(searchResultsController: nil)
        self.resultSearchController.searchResultsUpdater = self
        self.resultSearchController.dimsBackgroundDuringPresentation = false
        self.resultSearchController.searchBar.sizeToFit()
        
        self.tableView.tableHeaderView = self.resultSearchController.searchBar
        
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchStops()
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        print("prepare for seque")
        
        if (self.resultSearchController.active){
            self.selectedStop = filteredStops[self.tableView.indexPathForSelectedRow!.row]
        }else{
            let s = savedStops[self.tableView.indexPathForSelectedRow!.row]
            self.selectedStop = Stop(name: s.valueForKey("name") as! String, id: s.valueForKey("id") as! String)
        }
        
        let stored = savedStops.contains({ (stop: NSManagedObject) -> Bool in
            return stop.valueForKey("name") as! String == selectedStop.name
        })
        
        if !stored {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            
            let entity =  NSEntityDescription.entityForName("Stop", inManagedObjectContext:managedContext)
            let stop = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
            
            stop.setValue(selectedStop.name, forKey: "name")
            stop.setValue(selectedStop.id, forKey: "id")
            
            do {
                try managedContext.save()
                savedStops.append(stop)
                
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
        }
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        
        if (self.resultSearchController.active)
        {
            return self.filteredStops.count
        }
        else
        {
            return self.savedStops.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        print("cell for row at index path \(self.resultSearchController.active)")
        
        let cell = tableView.dequeueReusableCellWithIdentifier("stop", forIndexPath: indexPath) as UITableViewCell?
        
        if (self.resultSearchController.active)
        {
            cell!.textLabel?.text = self.filteredStops[indexPath.row].name
            
            return cell!
        }
        else
        {
            cell!.textLabel?.text = self.savedStops[indexPath.row].valueForKey("name") as? String
            return cell!
        }
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController)
    {
        print("update result search controller")
        
        self.filteredStops.removeAll(keepCapacity: false)
        
        let query = searchController.searchBar.text!.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        
        
        Alamofire.request(.GET, "http://www.vgn.de/ib/site/tools/EFA_Suggest_v3.php?query=\(query)").validate().responseJSON { response in
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    let json = JSON(value)
                    
                    let suggestions = json["suggestions"]
                    let ids = json["data"]
                    
                    
                    for (index,suggestion):(String, JSON) in suggestions {
                        
                        let i = Int.init(index)
                        let id = ids[i!]["name"]
                        
                        if(id != nil) {
                            let stop = Stop(name: suggestion.string!, id: id.string!)
                            self.filteredStops.append(stop)
                        }
                    }
                    
                    self.tableView.reloadData()
                    
                }
            case .Failure(let error):
                print("error \(error)")
            }
        }
        
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        print("comitEditingStyle")
        
        if(editingStyle == .Delete){
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            
            managedContext.deleteObject(savedStops[indexPath.row])
            
            do{
                try managedContext.save()

            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
            
            fetchStops()
            self.tableView.reloadData()
            
        }
        
        
    }
    
    func fetchStops (){
        
        print("fetch stops")
        
        savedStops.removeAll()
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: "Stop")
        
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            savedStops = results as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
}



