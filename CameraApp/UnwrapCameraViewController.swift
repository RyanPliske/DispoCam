//
//  UnwrapCameraViewController.swift
//  photojojo
//
//  Created by Ryan Pliske on 3/10/15.
//  Copyright (c) 2015 Ochre. All rights reserved.
//

import UIKit

class UnwrapCameraViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {
      NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: "unwrapCamera", userInfo: nil, repeats: false)
    }

    func unwrapCamera(){
      self.performSegueWithIdentifier("showCameraFromUnwrap", sender: self)
    }

}
