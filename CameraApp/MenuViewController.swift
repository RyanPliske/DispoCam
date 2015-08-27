//
//  MenuViewController.swift
//  photojojo
//
//  Created by Ryan Pliske on 2/18/15.
//  Copyright (c) 2015 Ochre. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
  
  var urlString : String!
  var alertBanner : SpringImageView = SpringImageView(image: UIImage(named: "no-shipping-info-alert")!)

  @IBOutlet weak var shippingButton: MenuButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewWillAppear(animated: Bool) {
    self.navigationController?.navigationBarHidden = true
    
    // If Shipping Info saved, don't do anything
    if let addressSavedOnPhone = NSUserDefaults.standardUserDefaults().objectForKey("shippingAddressData") as? NSData {
      self.shippingButton.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
      // display normal Shipping Info Button
      if self.alertBanner.isDescendantOfView(self.shippingButton) // If Banner, then remove it
      {
        self.alertBanner.delay = 1.5
        self.alertBanner.duration = 3.5
        self.alertBanner.animation = "fall"
        self.alertBanner.animateToNext({ () -> () in
          self.alertBanner.removeFromSuperview()
        })
      }
    }
    else {
      // move "Shipping Info" upwards
      self.shippingButton.contentVerticalAlignment = UIControlContentVerticalAlignment.Top
      // display pink add Shipping Info Button
      alertBanner.frame = CGRectMake(self.shippingButton.frame.minX, self.shippingButton.frame.minY, (self.shippingButton.frame.width - self.shippingButton.frame.width * 0.10), (self.shippingButton.frame.height * 0.15) )
      alertBanner.contentMode = UIViewContentMode.ScaleAspectFill
      self.shippingButton.addSubview(alertBanner)
      alertBanner.setTranslatesAutoresizingMaskIntoConstraints(false)
      // center the alert Banner
      self.shippingButton.addConstraint(NSLayoutConstraint(item: alertBanner, attribute: NSLayoutAttribute.CenterX, relatedBy: .Equal, toItem: self.shippingButton, attribute: .CenterX, multiplier: 1.0, constant: 0.0))
      // Add Y-axis constraint
      self.shippingButton.addConstraint(NSLayoutConstraint(item: alertBanner, attribute: .CenterY, relatedBy: .Equal, toItem: self.shippingButton, attribute: .CenterY, multiplier: 1.0, constant: 13.0))
      
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  @IBAction func openJoJoStore(sender: AnyObject) {
    self.urlString = "http://photojojo.com/store/"
    performSegueWithIdentifier("showWebViewController", sender: self)
  }

  @IBAction func openJoJoHelp(sender: AnyObject) {
    self.urlString = "http://photojojo.com/disposablecamera/help/"
    performSegueWithIdentifier("showWebViewController", sender: self)
  }
  
  @IBAction func openJoJoPrivacyPolicy(sender: AnyObject) {
    self.urlString = "https://photojojo.com/store/dca/privacy_policy"
    performSegueWithIdentifier("showWebViewController", sender: self)
  }

  @IBAction func CameraButtonClicked(sender: AnyObject) {
    // Check for camera_id on phone, if found, present user with camera.
    if let cameraNSData = NSUserDefaults.standardUserDefaults().objectForKey("camera_id") as? NSData {
      // If camera already exists, go back to it, else instantiate a new one (and exit this function)
      for viewController in self.navigationController!.viewControllers! {
        if viewController.isKindOfClass(CameraViewController)
        {
          // Just making sure that the camera doesn't already exist.
          println("Attempting to deallocate previous camera.")
        }
      }
      self.performSegueWithIdentifier("segueToCamFromMenu", sender: self)
      return
    }
    // If BuyNewRollViewController exists on the stack of ViewControllers, go back to it. Else instantiate a new one.
    for viewController in self.navigationController!.viewControllers! {
      if viewController.isKindOfClass(BuyNewRollViewController)
      {
        self.performSegueWithIdentifier("unwindtoBuyNewFromMenu", sender: self)
        return
      }
    }
    self.performSegueWithIdentifier("showBuyNewRollFromMenu", sender: self)
  }
  

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showWebViewController" {
      var webVC : WebViewController = segue.destinationViewController as! WebViewController
      webVC.urlString = self.urlString
      return
    }
    if segue.identifier == "unwindToCameraFromMenu" {
      var camVC : CameraViewController = segue.destinationViewController as! CameraViewController
      camVC.prepareToLeaveCameraViewController = false
      return
    }
    if segue.identifier == "segueToShippingFromMenu" {
      var viewController = segue.destinationViewController as! ShippingFormViewController
      viewController.shippingHeader = true
      viewController.cameFromMenu = true
    }
    if segue.identifier == "segueToTutorialFromMenu" {
      var viewController = segue.destinationViewController as! TutorialViewController
      viewController.onboarding = false
    }
  }

  @IBAction func unwindToMenu(segue: UIStoryboardSegue) {}
  
  override func shouldAutorotate() -> Bool {
    return false
  }
}
