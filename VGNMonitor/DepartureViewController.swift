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
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        
        let spinningButton = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
        self.navigationItem.rightBarButtonItem = spinningButton
        
    }
    
    override func viewWillAppear(animated: Bool) {
        getDepartures(currentStop.id)
        
        
        if let searchController = self.presentedViewController as? UISearchController {
            searchController.active = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return departures.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("departure", forIndexPath: indexPath) as UITableViewCell?

            let departure = departures[indexPath.row]
        
            cell!.textLabel?.text = "\(departure.line) \(departure.direction)"
            cell!.detailTextLabel?.text = departure.time
        
            return cell!

    }
    
    
    func getDepartures(id : String){
        
        Alamofire.request(.GET, "http://www.vgn.de/echtzeit-abfahrten/?type_dm=any&nameInfo_dm=\(id)").validate().responseString { response in
            switch response.result {
            case .Success:
                if let html = response.result.value {
                    
                    if let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                        
                        //doc.xpath("//tr[class='Liste']")
                        
                        for departure in doc.css("tr[class='Liste' or class='Liste alt']") {
                            
                            let tds = departure.css("td")
                            
                            
                            //tds.forEach({ (t) in
                            //    print(t.text)
                            //})
                            //print("\n ---------")
     
                        
                            let time = tds[0].text!
                            let line = tds[2].text!.stringByReplacingOccurrencesOfString("\n", withString: "").stringByReplacingOccurrencesOfString(" ", withString:"")
                            let direction = tds[3].text!
                            
                            let dep = Departure(time: time, direction: direction, line: line)
                            
                            self.departures.append(dep)
                            
                            let reloadButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "update:")
                            self.navigationItem.rightBarButtonItem = reloadButton
                        }
                    }
                    
                    
                    self.tableView.reloadData()
                    self.navigationItem.rightBarButtonItem?.title = "Update"

                }
            case .Failure(let error):
                print("error \(error)")
            }
        }
        
    }
    
    
    func update(sender: UIBarButtonItem){
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        
        let spinningButton = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
        
        self.navigationItem.rightBarButtonItem = spinningButton
        
        departures.removeAll()
        
        self.tableView.reloadData()
        
        getDepartures(currentStop.id)
    }

    
}

