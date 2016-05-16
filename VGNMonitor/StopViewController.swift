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
import Kanna

class StopViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var departureTableView: UITableView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    let refreshControl = UIRefreshControl()
    
    var filteredStops = [Stop]()
    var departures = [Departure]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //delegates
        searchBar.delegate = self
        searchTableView.delegate = self
        departureTableView.delegate = self
        
        //data source
        searchTableView.dataSource = self
        departureTableView.dataSource = self
        
        //visibility
        searchTableView.hidden = true
        activityIndicator.hidden = true
        
        //appearence
        searchBar.tintColor = UIColor.whiteColor()
        
        //refresh controll
        refreshControl.backgroundColor = UIColor.lightGrayColor()
        refreshControl.tintColor = UIColor.whiteColor()
        refreshControl.addTarget(self, action: #selector(self.reloadDepartures), forControlEvents: UIControlEvents.ValueChanged)
        departureTableView.addSubview(refreshControl)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    ///////////////
    // tablew view
    //////////////
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        
        if(tableView == searchTableView){
            print("search table view")
            return self.filteredStops.count
        }else{
            print("dep t v")
            
            if(departures.count == 0){
                departureTableView.backgroundView = activityIndicator
                departureTableView.separatorStyle = .None
            }else{
                departureTableView.separatorStyle = .SingleLine
            }
            return self.departures.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if(tableView == searchTableView){
            let cell = tableView.dequeueReusableCellWithIdentifier("stop", forIndexPath: indexPath) as UITableViewCell?
            cell!.textLabel?.text = self.filteredStops[indexPath.row].name
            return cell!
        } else{
            let cell = tableView.dequeueReusableCellWithIdentifier("departure", forIndexPath: indexPath) as UITableViewCell?
            let departure = departures[indexPath.row]
            cell!.textLabel?.text = "\(departure.line) \(departure.direction)"
            cell!.detailTextLabel?.text = departure.time
            return cell!
        }
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if(tableView == searchTableView){
            
            departures.removeAll(keepCapacity: false)
            
            let filtredStop = filteredStops[indexPath.row]
            
            getDepartures(filtredStop.id)
            
            searchBar.text = filtredStop.name
            searchBar.resignFirstResponder()
            
            searchTableView.hidden = true
        
            activityIndicator.startAnimating()
        }
    }
    
    //////////////
    // search bar
    /////////////
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
    
        print("text did changed")
        
        // empty lists
        if(!refreshControl.refreshing){
            filteredStops.removeAll(keepCapacity: false)
            searchTableView.reloadData()
        }
        
        // build query string
        let query = searchText.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        
        // if empty return
        if(query == ""){
            self.searchTableView.hidden = true
            departures.removeAll(keepCapacity: false)
            departureTableView.reloadData()
            return
        }
        
        // do the query
        Alamofire.request(.GET, "http://www.vgn.de/ib/site/tools/EFA_Suggest_v3.php?query=\(query)").validate().responseJSON { response in

            switch response.result {
            case .Success:
                
                if(self.refreshControl.refreshing){
                    self.filteredStops.removeAll(keepCapacity: false)
                    self.searchTableView.reloadData()
                }
                
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
                    
                    self.searchTableView.reloadData()
                    
                    // if query tooks longer and user deleted search text
                    if(self.searchBar.text == ""){
                        self.searchTableView.hidden = true
                    }else{
                        self.searchTableView.hidden = false
                    }
                    
                }
            case .Failure(let error):
                
                print("error \(error)")
                
                
                let alertCoontroller = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
                alertCoontroller.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                
                switch error.code{
                case -1009:
                    alertCoontroller.title = "Keine Internetverbindung"
                    alertCoontroller.message = "Bitte stelle eine Verbindung zum Internet her."
                default:
                    alertCoontroller.title = "Unbekannter Fehler"
                    alertCoontroller.message = "Irgendetwas lief furchtbar schief..."
                }
                 
            }
        }
        
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchTableView.hidden = false
    }

    
    func getDepartures(id: String){
        
        print("get departueres")
        
        self.departures.removeAll()
        self.departureTableView.reloadData()
        
        Alamofire.request(.GET, "http://www.vgn.de/echtzeit-abfahrten/?type_dm=any&nameInfo_dm=\(id)").validate().responseString { response in
            switch response.result {
            case .Success:
                if let html = response.result.value {
                    
                    if let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
                        
                        self.activityIndicator.stopAnimating()
                        
                        for departure in doc.xpath("//tr[@class='Liste'] | //tr[@class='Liste alt']") {
                            
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
                    self.departureTableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            case .Failure(let error):
                print("error \(error)")
                self.refreshControl.endRefreshing()
                
                let alertCoontroller = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
                alertCoontroller.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: {(alert: UIAlertAction!) in
                    if(self.departures.isEmpty){
                        self.getDepartures(id)
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
    
    func reloadDepartures(){
        getDepartures(filteredStops[(searchTableView.indexPathForSelectedRow?.row)!].id)
    }

    
}



