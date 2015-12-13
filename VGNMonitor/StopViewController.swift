//
//  FirstViewController.swift
//  VGNMonitor
//
//  Created by Torsten Wauer on 13/12/15.
//  Copyright © 2015 twdorado. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class StopViewController: UITableViewController, UISearchResultsUpdating {

    var filteredStops = [Stop]()
    var resultSearchController = UISearchController()

    
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
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        self.resultSearchController.active = false
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if (self.resultSearchController.active)
        {
            return self.filteredStops.count
        }
        else
        {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("stop", forIndexPath: indexPath) as UITableViewCell?
        
        if (self.resultSearchController.active)
        {
            cell!.textLabel?.text = self.filteredStops[indexPath.row].name
            
            return cell!
        }
        else
        {
            return cell!
        }
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController)
    {
        self.filteredStops.removeAll(keepCapacity: false)
        
        let query = searchController.searchBar.text!
        
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
    

}

