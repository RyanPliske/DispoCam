//
//  AppDelegate.swift
//  App Delegate's function is to respond to changes in app state
//
//  Created by Ryan Pliske on 1/21/15.
//  Copyright (c) 2015 Ochre. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  //Manages and Coordinates the Views of the app
  var window: UIWindow?
  // Instantiate a User Object to be used across all View Controllers
  var user = UserModel(apiHandler: ApiHandlerModel(baseUrl: ApiConfig.baseUrl, user: ApiConfig.user, password: ApiConfig.password))
  // Instantiate a Camera Object to be used across all View Controllers
  var camera = CameraModel(apiHandler: ApiHandlerModel(baseUrl: ApiConfig.baseUrl, user: ApiConfig.user, password: ApiConfig.password))
  // Dictionary which is given key-value pairs of query params from coupon URL
  var dictionary : NSMutableDictionary?
  
  func getCouponQueryParams() -> NSDictionary? {
    return self.dictionary
  }
  
  // Function to allow ViewControllers to grab the instantiated API Object
  func getUserInfo() -> UserModel {
      return self.user
  }
  
  // Function to allow ViewControllers to grab camera info
  func getCameraInfo() -> CameraModel {
      return self.camera
  }
  
  // Did Finish Launching
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    Fabric.with([Crashlytics()])
    
    // Installation for Heap Analytics
    Heap.setAppId("2771673445")
    #if DEBUG
      // Heap.enableVisualizer()
    #endif
    // Initial Setup for Stripe SDK
    Stripe.setDefaultPublishableKey(StripeConfig.publishableKey)
        
    // Initial Setup for AWS SDK
    // http://docs.aws.amazon.com/mobile/sdkforios/developerguide/setup.html (scroll about 1/3 down)
    
    let credentialsProvider = AWSCognitoCredentialsProvider(
      regionType: .USEast1,
      identityPoolId: AwsConfig.poolId
    )
    
    let defaultServiceConfiguration = AWSServiceConfiguration(
      region: AWSRegionType.USEast1,
      credentialsProvider: credentialsProvider
    )
    AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = defaultServiceConfiguration
    // AWSLogger.defaultLogger().logLevel = .Verbose

    
    // Create a Navigation Controller which will act as our root View Controller in the VC Hierarchy
    var navigationController = UINavigationController(rootViewController : self.window!.rootViewController!)
    self.window?.rootViewController = navigationController
    var mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
    
    // If user already has a current camera
    // --------------------------------------------------------------------------------------------------
    if let cameraNSData = NSUserDefaults.standardUserDefaults().objectForKey("camera_id") as? NSData {
      // Grab User ID
      if let userDataOnDevice = NSUserDefaults.standardUserDefaults().objectForKey("user_id") as? NSData {
        // Asign user id to userModel object
        self.user.user_id = NSKeyedUnarchiver.unarchiveObjectWithData(userDataOnDevice) as! Int!
        println("Found USER ID in UserDefaults: {\(self.user.user_id!)}")
        CLSLogv("Found USER ID in UserDefaults: %d", getVaList([self.user.user_id!]))
        // Check if user exists in NSUserDefaults
        if let username = NSUserDefaults.standardUserDefaults().objectForKey("username") as? NSData {
          self.user.username = NSKeyedUnarchiver.unarchiveObjectWithData(username) as! String!
          println("Found username in UserDefaults: {\(self.user.username!)}")
          CLSLogv("Found username in UserDefaults: %@", getVaList([self.user.username!]))
        }
      }
      
      // First check if camera is empty (If empty go to upload Failure VC)
      if let photos1 = NSUserDefaults.standardUserDefaults().objectForKey("numOfPhotosUsed") as? NSData {
        var photosUsed = NSKeyedUnarchiver.unarchiveObjectWithData(photos1) as! Int!
        if let photos2 = NSUserDefaults.standardUserDefaults().objectForKey("numOfPhotosPurchased") as? NSData {
          var photosPurchased = NSKeyedUnarchiver.unarchiveObjectWithData(photos2) as! Int!
          if photosPurchased <= photosUsed {
            // Check if user has saved their shipping info (If they haven't present shipping view controller
            if let addressSavedOnPhone = NSUserDefaults.standardUserDefaults().objectForKey("shippingAddressData") as? NSData {
              // Present User with Upload Failure
              let failureVC = mainStoryBoard.instantiateViewControllerWithIdentifier("UploadingViewController") as! UploadingViewController
              navigationController.pushViewController(failureVC, animated: false)
              return true
            }
            // Present user with Shipping Info
            let shippingVC = mainStoryBoard.instantiateViewControllerWithIdentifier("ShippingFormViewController") as! ShippingFormViewController
            shippingVC.shippingHeader = true
            shippingVC.cameFromCamera = true
            navigationController.pushViewController(shippingVC, animated: false)
            return true
          }
        }
      }
      // Present User's camera.
      let cameraVC = mainStoryBoard.instantiateViewControllerWithIdentifier("CameraViewController") as! CameraViewController
      navigationController.pushViewController(cameraVC, animated: false)
      return true
    }

    // If user_id exists in NSUserDefaults, display Buy New ViewController
    // --------------------------------------------------------------------------------------------------
    if let userDataOnDevice = NSUserDefaults.standardUserDefaults().objectForKey("user_id") as? NSData {
      // Asign user id to userModel object
      self.user.user_id = NSKeyedUnarchiver.unarchiveObjectWithData(userDataOnDevice) as! Int!
      println("Found USER ID in UserDefaults: {\(self.user.user_id!)}")
      CLSLogv("Found USER ID in UserDefaults: %d", getVaList([self.user.user_id!]))
      // Check if username exists in NSUserDefaults
      if let username = NSUserDefaults.standardUserDefaults().objectForKey("username") as? NSData {
        self.user.username = NSKeyedUnarchiver.unarchiveObjectWithData(username) as! String!
        println("Found username in UserDefaults: {\(self.user.username!)}")
        CLSLogv("Found username in UserDefaults: %@", getVaList([self.user.username!]))
      }
      
      // Display Buy New
      let buyNewVC = mainStoryBoard.instantiateViewControllerWithIdentifier("BuyNewRollViewController") as! BuyNewRollViewController
      navigationController.pushViewController(buyNewVC, animated: false)
      return true
    }
    
    // Check if user exists in keychain
    // --------------------------------------------------------------------------------------------------
    let (dictionary, error) = Locksmith.loadDataForUserAccount("photojojoUserAccount2")
    if error == nil {
      
      // Grab user ID from keychain
      if let userIDString = dictionary!.valueForKey("userID") as? NSString{
        self.user.user_id = userIDString.integerValue
        println("Found USER ID in KeyChain: {\(self.user.user_id!)}")
        CLSLogv("Found USER ID in KeyChain: %d", getVaList([self.user.user_id!]))
      }

      // save username to device
      if let userNameString = dictionary!.valueForKey("username") as? String {
        self.user.username = userNameString
        println("Found username in KeyChain: {\(self.user.username!)}")
        CLSLogv("Found username in Keychain: %@", getVaList([self.user.username!]))
      }
    }
    
    // Display Tutorial
    let tutorialVC = mainStoryBoard.instantiateViewControllerWithIdentifier("TutorialViewController") as! TutorialViewController
    navigationController.pushViewController(tutorialVC, animated: false)
    return true
  }
    
    func applicationDidBecomeActive(application: UIApplication) {
        NSNotificationCenter.defaultCenter().postNotificationName("returnedWhileUploading", object: nil)
    }
    
    
  /*
  // Function to open Application from a coupon and parse the query parameters
  func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
    // parse the url
    var query = url.query
    // var urlString : NSString = url.absoluteString!
    self.dictionary = NSMutableDictionary(capacity: 3)
    // we may want the token and the user_id to be part of the url sent in the email for validation purposes.
    // we could validate in app (if user's id == user_id from url)
    if query != nil {
      var keyPairs : NSArray = query!.componentsSeparatedByString("&")
      for pair in keyPairs {
        var elements : NSArray = pair.componentsSeparatedByString("=")
        var key = elements.objectAtIndex(0).stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        var value = elements.objectAtIndex(1).stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        self.dictionary!.setObject(value!, forKey: key!)
      }
      NSNotificationCenter.defaultCenter().postNotificationName("returnToAppWithCouponToken", object: nil, userInfo:self.dictionary! as [NSObject : AnyObject])
      var mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
      let buyNewRoll_vc = mainStoryBoard.instantiateViewControllerWithIdentifier("BuyNewRollViewController") as! BuyNewRollViewController
      self.window?.rootViewController = buyNewRoll_vc
    }
    
    return true
  }
  */
}
