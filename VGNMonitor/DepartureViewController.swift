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
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let stopViewController = self.navigationController?.viewControllers[0] as! StopViewController
        
        self.currentStop = stopViewController.selectedStop
        
        self.navigationItem.title = currentStop.name
        
        let refreshControl = self.refreshControl
        refreshControl!.addTarget(self, action: #selector(DepartureViewController.getDepartures), forControlEvents: UIControlEvents.ValueChanged)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        getDepartures()
        
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
        
        if(departures.count == 0){
            self.tableView.backgroundView = activityIndicator
            self.tableView.separatorStyle = .None
        }else{
            self.tableView.separatorStyle = .SingleLine
        }
        
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
    
    func getDepartures(){
        
        Alamofire.request(.GET, "http://www.vgn.de/echtzeit-abfahrten/?type_dm=any&nameInfo_dm=\(self.currentStop.id)").validate().responseString { response in
            switch response.result {
            case .Success:
                if let html = response.result.value {
                    
                    if let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                        
                        self.departures.removeAll()
                        self.activityIndicator.stopAnimating()

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
                        }
                    }
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
            case .Failure(let error):
                print("error \(error)")
                self.refreshControl?.endRefreshing()
                
                let alertCoontroller = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
                alertCoontroller.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: {(alert: UIAlertAction!) in
                    if(self.departures.isEmpty){
                        self.getDepartures()
                    }
                }))

                switch error.code{
                case -1009:
                    alertCoontroller.title = "Keine Internetverbindung"
                    alertCoontroller.message = "Bitte stelle eine Verbindung zum Internet her."
                default:
                    alertCoontroller.title = "Unbekannter Fehler"
                    alertCoontroller.message = "Irgendetwas lief furchtbar schief..."
                }
                
                self.presentViewController(alertCoontroller, animated: true, completion: nil)
                self.activityIndicator.stopAnimating()
                
            }
        
        }
        
    }
    

    
}

