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
import Kanna

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
    
    func getDepartures(id : String){
        
        Alamofire.request(.GET, "http://www.vgn.de/echtzeit-abfahrten/?type_dm=any&nameInfo_dm=\(id)").validate().responseString { response in
            switch response.result {
            case .Success:
                if let value = response.result.value {

                    
                    
                    self.tableView.reloadData()
                    
                }
            case .Failure(let error):
                print("error \(error)")
            }
        }
        
    }
    

    
}

