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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

