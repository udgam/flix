//
//  MoviesViewController.swift
//  MovieViewer
//
//  Created by Udgam Goyal on 6/15/16.
//  Copyright © 2016 Udgam Goyal. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchingBar: UISearchBar!
    var endpoint: String!
    
    var titles: [String]! = []
    var movies: [NSDictionary]?
    var refreshControl = UIRefreshControl()
    var filteredData: [NSDictionary]!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        searchingBar.delegate = self
        refreshControl.addTarget(self, action: #selector(loadData(_:)), forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
        filteredData = movies
        self.loadData(true)
        
       
        print("Filtered Data: \(filteredData)")
        
    }
    
    func loadData(initial: Bool) {
    
        let apiKey = "3f22d00550b9a16769272eac90ec8bb0"
        let url = NSURL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(
            URL: url!,
            cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
            timeoutInterval: 10)
        
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: nil,
            delegateQueue: NSOperationQueue.mainQueue()
        )
        
        if (initial) {
            MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        }
        
        let task: NSURLSessionDataTask = session.dataTaskWithRequest(request,completionHandler: { (dataOrNil, response, error) in
            
            if let data = dataOrNil {
                if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                    data, options:[]) as? NSDictionary {
                    //print("response: \(responseDictionary)")
                    
                    self.movies = responseDictionary["results"] as? [NSDictionary]
                    for m in self.movies!{
                        let t = m["title"]! as! String
                        self.titles!.append(t)
                    }
                    
                    //print("Test 1: \()")
                    print("Titles: \(self.titles)")
                    self.filteredData = self.movies
                    self.tableView.reloadData()
                    if (initial) {
                        MBProgressHUD.hideHUDForView(self.view, animated: true)
                    } else {
                        self.refreshControl.endRefreshing()
                    }
                    
                }
                
            }
        })
        task.resume()
        
        
        
        
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        
        if let movies = movies{
            return filteredData.count
        }else{
            return 0
        }
        
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        //let row = indexPath.row
        //let name = names[row]
        
        let movie = filteredData![indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        
        let baseURL = "http://image.tmdb.org/t/p/w500"
        let posterPath = movie["poster_path"] as? String
        let imageURL = NSURL(string: baseURL + posterPath!)
        let imageRequest = NSURLRequest(URL: imageURL!)
        
        cell.posterView.setImageWithURLRequest(
            imageRequest,
            placeholderImage: nil,
            success: { (imageRequest, imageResponse, image) -> Void in
                
                // imageResponse will be nil if the image is cached
                if imageResponse != nil {
                    print("Image was NOT cached, fade in image")
                    cell.posterView.alpha = 0.0
                    cell.posterView.image = image
                    UIView.animateWithDuration(0.3, animations: { () -> Void in
                        cell.posterView.alpha = 1.0
                    })
                } else {
                    print("Image was cached so just update the image")
                    cell.posterView.image = image
                }
            },
            failure: { (imageRequest, imageResponse, error) -> Void in
                // do something for the failure condition
        })
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        //cell.posterView.setImageWithURL(imageURL!)
        
        print("row\(indexPath.row)")
        
        let section = indexPath.section
        print ("Section:\(section)")
        
        cell.selectionStyle = .Blue
        
        return cell
        
    }
    
    /*func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
            filteredData = searchText.isEmpty ? movies : movies?.filter({(dataString: NSDictionary) -> Bool in
                let s = dataString["title"] as? NSString
            return s?.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
        })
        
    }*/
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        // When there is no text, filteredData is the same as the original data
        if searchText.isEmpty {
            filteredData = movies
        } else {
            // The user has entered text into the search box
            // Use the filter method to iterate over all items in the data array
            // For each item, return true if the item should be included and false if the
            // item should NOT be included
            filteredData = (movies?.filter({(dataItem: NSDictionary) -> Bool in
                // If dataItem matches the searchText, return true to include it
                let s2 = dataItem["title"] as? String
                if s2?.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil {
                    return true
                } else {
                    return false
                }
            }))!
        }
        tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.searchingBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    
    
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cell)
        let movie = movies![indexPath!.row]
        
        let detailViewController = segue.destinationViewController as! DetailViewController
        detailViewController.movie = movie
        
        
        
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
    
    
}
