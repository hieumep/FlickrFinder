//
//  FlickFinderViewController.swift
//  FIickFinder
//
//  Created by Hieu Vo on 1/1/16.
//  Copyright © 2016 Hieu Vo. All rights reserved.
//

import UIKit

class FlickFinderViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var textImageView: UILabel!
    @IBOutlet weak var textSearch: UITextField!
    @IBOutlet weak var latTextSearch: UITextField!
    @IBOutlet weak var LonTextSearch: UITextField!
    @IBOutlet weak var photoImageTitle: UILabel!
    
    var tapRecognizer: UITapGestureRecognizer? = nil
    
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "827341edcfd445f14e9b4c6fb09501c7"
    let EXTRAS = "url_m"
    let SAFE_SEARCH = "1"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    let BOUNDING_BOX_HALF_WIDTH = 1.0
    let BOUNDING_BOX_HALF_HEIGHT = 1.0
    let LAT_MIN = -90.0
    let LAT_MAX = 90.0
    let LON_MIN = -180.0
    let LON_MAX = 180.0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        textSearch.delegate = self
        latTextSearch.delegate = self
        LonTextSearch.delegate = self
        tapRecognizer = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
        tapRecognizer!.numberOfTapsRequired = 1
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        addKeyboardDismissRecognizer()
        subscribeToKeyboardNotifications()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        removeKeyboardDismissRecognizer()
        unsubscribeToKeyboadNotifications()
    }
    
    @IBAction func textSearch(sender: AnyObject) {
        guard textSearch.text == "" else{
            textImageView.text = "Photo is loading..."
            self.textImageView.alpha = 1.0
            self.photoImageView.alpha = 0.3
            let arguments :[String:NSObject] = ["method" : METHOD_NAME, "api_key" : API_KEY, "text" : self.textSearch.text!, "extras" : EXTRAS, "safe_search" : SAFE_SEARCH, "format" : DATA_FORMAT, "nojsoncallback" : NO_JSON_CALLBACK]
            getImageFromFlickrBySearch(arguments)
            return
        }
    }
    
    @IBAction func latLongTitudeSearch(sender: AnyObject) {
        let checkLatitude = checkLatitudeTexField(latTextSearch, min: LAT_MIN, max: LAT_MAX, label: "Latitude")
        let checkLongitude = checkLatitudeTexField(LonTextSearch, min: LON_MIN, max: LON_MAX, label: "Longitude")
        if checkLatitude && checkLongitude {
            let bbox = createBoundingBoxString()
            textImageView.text = "Photo is loading..."
            self.textImageView.alpha = 1.0
            self.photoImageView.alpha = 0.3
            let arguments :[String:NSObject] = ["method" : METHOD_NAME, "api_key" : API_KEY, "bbox" : bbox, "extras" : EXTRAS, "safe_search" : SAFE_SEARCH, "format" : DATA_FORMAT, "nojsoncallback" : NO_JSON_CALLBACK]
            getImageFromFlickrBySearch(arguments)
        }
    }
  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Check Latitude or Longitude is empty or not , and check value in [min, max]
    func checkLatitudeTexField(textField:UITextField, min:Double, max : Double, label : String) -> Bool{
        if (textField.text!.isEmpty) {
            self.photoImageTitle.text = "Latitude or Longitude fields can't be empty!!!"
            return false
        }else
        {
            let value = (textField.text! as NSString).doubleValue
            if (value >= min) && (value <= max){
                return true
            }else{
                self.photoImageTitle.text = "\(label) should be [\(min),\(max)]"
                return false
            }
        }
    }
    
    func createBoundingBoxString() -> String {
        
        let latitude = (self.latTextSearch.text! as NSString).doubleValue
        let longitude = (self.LonTextSearch.text! as NSString).doubleValue
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    func getImageFromFlickrBySearch(arguments : [String:NSObject]){
      //  
    
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(arguments)
        let URL = NSURL(string: urlString)!
        let request = NSURLRequest(URL: URL)
        
        let task = session.dataTaskWithRequest(request){(data, response, error) in
            // check error?
            guard (error == nil) else{
                print("There was error with your request")
                return
            }
            // check statusCode
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else{
                if let response = response as? NSHTTPURLResponse{
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            // Check data return
            guard let data = data else {
                print("No data return")
                return
            }
            
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find keys 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary["pages"] as? Int else {
                print("Cannot find key 'pages' in \(photosDictionary)")
                return
            }
            
            /* Pick a random page! */
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getImageFromFlickrBySearchWithPage(arguments, pageNumber: randomPage)
        }
        task.resume()
    }
    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int) {
        
        /* Add the page to the method's arguments */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find key 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "total" key in photosDictionary? */
            guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                print("Cannot find key 'total' in \(photosDictionary)")
                return
            }
            
            if totalPhotosVal > 0 {
                
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find key 'photo' in \(photosDictionary)")
                    return
                }
                
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                let photoTitle = photoDictionary["title"] as! String
                /* GUARD: Does our photo have a key for 'url_m'? */
                guard let imageUrlString = photoDictionary["url_m"] as? String else {
                    print("Cannot find key 'url_m' in \(photoDictionary)")
                    return
                }
                
                let imageURL = NSURL(string: imageUrlString)
                if let imageData = NSData(contentsOfURL: imageURL!) {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.textImageView.alpha = 0.0
                        self.photoImageView.alpha = 1.0
                        self.photoImageView.image = UIImage(data: imageData)
                        self.photoImageTitle.text = photoTitle
                    })
                } else {
                    print("Image does not exist at \(imageURL)")
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.photoImageTitle.text = "No Photos Found. Search Again."
                    self.textImageView.alpha = 1.0
                    self.photoImageView.image = nil
                })
            }
        }
        
        task.resume()
    }
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
}
extension String {
    func toDouble() -> Double? {
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }

}