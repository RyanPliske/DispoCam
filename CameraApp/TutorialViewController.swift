//
//  TutorialViewController.swift
//  photojojo
//
//  Created by Ryan Pliske on 2/18/15.
//  Copyright (c) 2015 Ochre. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController {
  var onboarding = true
  var userDatabaseData : UserModel!
  let jojoAPIHandler: ApiHandlerModel = ApiHandlerModel(baseUrl: ApiConfig.baseUrl, user: ApiConfig.user, password: ApiConfig.password)
  // Make the App Delegate methods available to this view controller
  let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
  // Grab device's unique id
  let unique_device_id = UIDevice.currentDevice().identifierForVendor.UUIDString
  
  @IBAction func YAASS(sender: AnyObject) {
    yaaaaaassButton.enabled = false
    if userDatabaseData.user_id == nil || userDatabaseData.username == nil {
      self.userDatabaseData.createNewUser() {
        (networkError) in
        // Let user pass this regardless of Network Error
        self.performSegueWithIdentifier("pushBuyNowViewController", sender: self)
      }
    } else {
      self.performSegueWithIdentifier("pushBuyNowViewController", sender: self)
    }
  }
  
  @IBOutlet weak var yaaaaaassButton: Button!
  
  @IBAction func goBack(sender: AnyObject) {
    self.performSegueWithIdentifier("unwindtoMenuFromTutorial", sender: self)
  }
  
  @IBOutlet weak var goBackButton: UIButton!
  @IBOutlet weak var exposuresAnimation: UIImageView!
  @IBOutlet weak var internetPrinterAnimation: UIImageView!
  @IBOutlet weak var deliveryAnimation: UIImageView!
  @IBOutlet weak var openingAnimation: UIImageView!
  @IBOutlet weak var noSavingAnimation: UIImageView!
  @IBOutlet weak var takePhotosAnimation: UIImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBarHidden = true
    // instantiate UserModel with user_id
    self.userDatabaseData = appDelegate.getUserInfo()
    // Add listeners for failure/success of creating a new user
    
    if onboarding {
      goBackButton.userInteractionEnabled = false
      goBackButton.hidden = true
      yaaaaaassButton.userInteractionEnabled = true
      yaaaaaassButton.hidden = false
    } else {
      goBackButton.userInteractionEnabled = true
      goBackButton.hidden = false
      
      yaaaaaassButton.userInteractionEnabled = false
      yaaaaaassButton.hidden = true
    }
    
    animateImageView(exposuresAnimation,       duration: 4.8)
    animateImageView(internetPrinterAnimation, duration: 1.0)
    animateImageView(deliveryAnimation,        duration: 3.0)
    animateImageView(openingAnimation,         duration: 3.2)
    animateImageView(noSavingAnimation,        duration: 1.5)
    animateImageView(takePhotosAnimation,      duration: 1.6)
  }
  
  override func viewWillDisappear(animated: Bool) {
    exposuresAnimation.stopAnimating()
    internetPrinterAnimation.stopAnimating()
    deliveryAnimation.stopAnimating()
    openingAnimation.stopAnimating()
    noSavingAnimation.stopAnimating()
    takePhotosAnimation.stopAnimating()
  }

  func animateImageView(imageView: UIImageView, duration: NSTimeInterval) {
    if let name = imageView.restorationIdentifier {
      var images: [UIImage] = []
      var i = 0
      // Don't worry, we'll break out of the loop
      // when we can't find the next UIImage
      while true {
        if let image = UIImage(named: NSString(format: "\(name)_%d", i) as String) {
          images.append(image)
          i++
        } else {
          break
        }
      }
      
      imageView.animationImages = images
      imageView.animationRepeatCount = 0
      imageView.animationDuration = duration
      
      imageView.image = images[0]
      imageView.startAnimating()
    }
  }
    
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  override func shouldAutorotate() -> Bool {
    return false
  }
}
