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

class DepartureViewController: UITableViewController {
    
    var currentStop = Stop(name: "", id: "")
    var departures = [Departure]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let stopViewController = self.navigationController?.viewControllers[0] as! StopViewController
        
        self.currentStop = stopViewController.selectedStop
        
        self.navigationItem.title = currentStop.name
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("departure", forIndexPath: indexPath) as UITableViewCell?

            cell!.textLabel?.text = self.currentStop.name
            
            return cell!

    }
    

    
}

