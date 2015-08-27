//
//  CameraViewController.swift
//  photojojo
//
//  Created by Ryan Pliske on 1/23/15.
//  Copyright (c) 2015 Ochre. All rights reserved.
//

import UIKit
import AudioToolbox
import Crashlytics

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  // An image picker ctlr. manages user interactions and delivers the results to a delegate. In this case the delegate is also this class.
  let imagePicker = UIImagePickerController()
  // Camera Overlay : View with our custom buttons
  @IBOutlet var cameraOverlay : UIView!
  // Instantiate Models
  var cameraData = CameraModel(apiHandler: ApiHandlerModel(baseUrl: ApiConfig.baseUrl, user: ApiConfig.user, password: ApiConfig.password))
  let amazonModel = AmazonHandlerModel()
  let jojoAPIHandler: ApiHandlerModel = ApiHandlerModel(baseUrl: ApiConfig.baseUrl, user: ApiConfig.user, password: ApiConfig.password)
  // When the camera is dismissed, we return to this ViewController and thus need to prepare to leave.
  var prepareToLeaveCameraViewController = false
  var cameraIsNowEmpty = false
  var timerOptionsOpen = false
  var timerOptionChoice : Int?
  var originalTimerPosition : CGPoint!
  var originalCameraImagePosition : CGPoint!
  var secondsLeft = 99
  var timer : NSTimer!
  var airplaneMode_aka_NoUserNameMode = false
  var failedtoUpdateCompletedRoll = false
  // get path to Documents folder
  let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
  // User Interface Objects
  
  var currentlyUploading = false
  var arrayOfPhotoParamsThatFailedToUpload : [NSDictionary]?
  
  @IBOutlet weak var numOfRemainingPhotosLabel: UILabel!
  @IBOutlet weak var takePhotoButton: UIButton!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var menuButton: UIButton!
  @IBOutlet weak var flashButton: SpringButton!
  @IBOutlet weak var timerButton: SpringButton!
  @IBOutlet weak var flipCameraButton: SpringButton!
  @IBOutlet weak var noneOptionForTimer: SpringButton!
  @IBOutlet weak var threeSecOptionForTimer: SpringButton!
  @IBOutlet weak var tenSecOptionForTimer: SpringButton!

  // Make the App Delegate methods available to this view controller
  let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
  var userDatabaseData : UserModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBarHidden = true
    // Begin Detecting Rotation
    UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationChanged:", name: UIDeviceOrientationDidChangeNotification, object: UIDevice.currentDevice())
    // Grab current User info passed from the BuyNewRollController. (user_id in particular)
    self.userDatabaseData = appDelegate.getUserInfo()
    self.userDatabaseData.getUsername()
    self.userDatabaseData.getUserId()
    self.cameraData = appDelegate.getCameraInfo()
  }
  
  override func viewDidAppear(animated: Bool) {
    // When CameraViewController appears to the user, check to see if user wishes to leave
    if self.prepareToLeaveCameraViewController {
      if self.cameraIsNowEmpty {
        // If Shipping Info saved, check if all photos uploaded
        if let addressSavedOnPhone = NSUserDefaults.standardUserDefaults().objectForKey("shippingAddressData") as? NSData {
          // Go to Uploading View Controller
          self.performSegueWithIdentifier("showUploadFromCamera", sender: self)
        }
        else {
          // If no Shipping Info stored on phone, go to shipping form
          self.performSegueWithIdentifier("showShippingFormFromCamera", sender: self)
        }
      } else {
        // Else we are leaving because the Menu Button was pressed and user still has photos remaining to use.
        self.segueToMenu()
      }
      return
    }
    // Attempt to Open the Camera (Camera could be in use, or device may not have one)
    println("Attempting to open device's camera.")
    if !self.accessCamera() {
      // Device doesn't have a camera, so exit.
      return
    }

    // Check for camera/photo info saved on the device.
    self.dealWithDatabaseDataStoredOnDevice()
    
  }

  
  /* Detect when phone is rotated */
  /* ------------------------------------------------------------------------------------------- */
  func orientationChanged(notification : NSNotification) {
    var device : UIDevice = notification.object as! UIDevice
    
    switch device.orientation {
    case UIDeviceOrientation.Portrait:
      if self.numOfRemainingPhotosLabel != nil {
        self.numOfRemainingPhotosLabel.transform = CGAffineTransformMakeRotation(CGFloat(0))
        self.menuButton.transform = CGAffineTransformMakeRotation(CGFloat(0))
      }
      break
    
    case UIDeviceOrientation.PortraitUpsideDown:
      if self.numOfRemainingPhotosLabel != nil {
        self.numOfRemainingPhotosLabel.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        self.menuButton.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
      }
      break
      
    case UIDeviceOrientation.LandscapeLeft:
      if self.numOfRemainingPhotosLabel != nil {
        self.numOfRemainingPhotosLabel.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        self.menuButton.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
      }
      break
    
    case UIDeviceOrientation.LandscapeRight:
      if self.numOfRemainingPhotosLabel != nil {
        self.numOfRemainingPhotosLabel.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2 + M_PI_2 + M_PI_2))
        self.menuButton.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2 + M_PI_2 + M_PI_2))
      }
      break
      
    default:
      break
    }
  }
  
  /* Check for stored camera and photo data stored on the device: If camera, use data, else create new camera data and save it to the phone. */
  /* ------------------------------------------------------------------------------------------- */
  func dealWithDatabaseDataStoredOnDevice() {
    // If Existing 'camera_id' saved on device, then use it.
    // NOTE: creating new camera is done before coming to CameraViewController
    if let cameraNSData = NSUserDefaults.standardUserDefaults().objectForKey("camera_id") as? NSData {
      self.cameraData.cameraID = NSKeyedUnarchiver.unarchiveObjectWithData(cameraNSData) as! Int!
      println("User has existing PhotoJoJo camera on phone. Camera ID is: \(self.cameraData.cameraID)")
      // Get the number of photos already taken. If there are any. (For when the user comes back to the app after having closed it.)
      if let photoNSData = NSUserDefaults.standardUserDefaults().objectForKey("numOfPhotosUsed") as? NSData {
        self.cameraData.numberOfPhotosUsed = NSKeyedUnarchiver.unarchiveObjectWithData(photoNSData) as! Int!
      } else {
        self.cameraData.numberOfPhotosUsed = 0
      }
      // Get the number of photos purchased.
      if let photoNSData = NSUserDefaults.standardUserDefaults().objectForKey("numOfPhotosPurchased") as? NSData {
        self.cameraData.numberOfPhotosPurchased = NSKeyedUnarchiver.unarchiveObjectWithData(photoNSData) as! Int!
      }
    }
    else {
      self.cameraData.deleteCameraFromUsersDevice()
    }
    // Initially Set the remaining number of Photos Label
    self.numOfRemainingPhotosLabel.text = "\(self.cameraData.numberOfPhotosPurchased!-self.cameraData.numberOfPhotosUsed)"
    // If user has a username
    if let username = self.userDatabaseData.username {
      CLSLogv("from CameraViewController; User Name: %@, User Id: %d", getVaList([username, self.userDatabaseData.user_id!]))
    }
    else { // get Username
      self.userDatabaseData.getUsername()
    }
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
  }
  
  /* Function to pull up the Camera View */
  /* ------------------------------------------------------------------------------------------- */
  func accessCamera() -> Bool {
    // Only works if device has a camera and if it's available
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
      self.imagePicker.delegate = self
      self.imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
      self.imagePicker.showsCameraControls = false
      // Disallow Editing after photo is taken
      self.imagePicker.allowsEditing = false
      // Set Flash Mode
      self.imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashMode.Off
      // Grab the Overlay View from Views/CameraOverlay.xib file
      NSBundle.mainBundle().loadNibNamed("CameraOverlay", owner: self, options: nil)
      // Set the overlay to the Camera view Controller
      self.imagePicker.cameraOverlayView = cameraOverlay
      // Make imagePicker transform to Full Screen
      // Device's screen size (ignoring rotation intentionally)
      var screenSize : CGSize = UIScreen.mainScreen().bounds.size
      // calculate a size which constrains the 4:3 aspect ratio to the screen size.
      var cameraAspectRatio : Float = 4.0 / 3.0
      var imageWidth : Float = floorf(Float(screenSize.width) * cameraAspectRatio)
      var scale : Float = ceilf((Float(screenSize.height-30)/imageWidth) * 10.0) / 10.0
      imagePicker.cameraViewTransform = CGAffineTransformMakeScale(CGFloat(scale), CGFloat(scale))
      // Set the OverlayView  frame (Frame initially has zero width/height etc.
      cameraOverlay.frame = self.imagePicker.view.frame
      cameraOverlay = nil
      
      self.presentViewController(self.imagePicker, animated: true, completion: nil)
      return true
    } else {
      var alert = UIAlertController(title: "Camera Needed", message: "This app requires your device to have a camera.", preferredStyle: UIAlertControllerStyle.Alert)
      alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil)
      
      return false
    }
  }
  
  /* Delegate Function to handle when a picture is taken via self.imagePicker.takePicture() */
  // Overall Objective: To Save Photo to phone, then attempt to upload the saved image to Amazon
  /* ------------------------------------------------------------------------------------------- */
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
    println("Picture Taken")
    // Name the image
    let currentDate = NSDate()
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy_MM_dd_:HH:mm:ss:a"
    let dateString = dateFormatter.stringFromDate(currentDate)
    let image_FileName = dateString + ".jpg"
    var pathToImage : NSString = self.documentsPath.stringByAppendingPathComponent(image_FileName)
    // Push to Background Thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
    {
      // Pull out JPEG information
      if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
        println("Extracting Image Data...")
        // write image to file
        UIImageJPEGRepresentation(image, 1.0).writeToFile(pathToImage as String, atomically : true)
        println("Picture written to \(pathToImage)")
        // save photoPath to phone
        self.savePhotoNametoFailedUploads(dateString, pathToImage: pathToImage)
      }
    }
  }
  
  func windTheCamera() {
    // Reset the "remaining number of Photos" Label
    self.cameraData.numberOfPhotosUsed++

    // Reset the photo's left label
    self.numOfRemainingPhotosLabel.text = "\(self.cameraData.numberOfPhotosPurchased!-self.cameraData.numberOfPhotosUsed)"
    // Stop Activity Indicator
    self.activityIndicator.stopAnimating()

    // If that was the last photo, then dismiss the camera
    if self.cameraData.numberOfPhotosPurchased <= self.cameraData.numberOfPhotosUsed {
      // Prepare to Leave the Camera
      self.prepareToLeaveCameraViewController = true
      self.cameraIsNowEmpty = true
      // Leave the Camera
      self.imagePicker.dismissViewControllerAnimated(true, completion: nil)
    } else {
      // Prepare for another photo to be taken
      // Re-Enable the take photo button
      self.takePhotoButton.userInteractionEnabled = true
      // Re-Enable Menu Button
      self.menuButton.userInteractionEnabled = true
    }
  }
  
  
  /* Button Action to take the photo */
  /* ------------------------------------------------------------------------------------------- */
  @IBAction func takePhoto(sender: AnyObject) {
    // Disable the menu button
    self.menuButton.userInteractionEnabled = false
    self.takePhotoButton.userInteractionEnabled = false
    // If timer options are showing, then hide the timer Options
    if self.timerOptionsOpen {
      self.hideTimerOptionsWithAnimations()
    }
    // Check if User selected a timer option (If they did start that specific timer)
    if self.timerOptionChoice != nil {
      // First disable the timer button so they can't mess up the "Timer" Displaying 10...9...etc.
      self.timerButton.userInteractionEnabled = false
      // Start the selected Timer
      self.secondsLeft = self.timerOptionChoice!
      var now = NSDate()
      let aSelector:Selector = "updateTimerEachSecond"
      self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: aSelector, userInfo: nil, repeats: true)
      return
    }

    self.imagePicker.takePicture()
    self.activityIndicator.startAnimating()
  }
  
  func updateTimerEachSecond(){
    self.secondsLeft--
    switch(secondsLeft){
    case 0 :
      self.imagePicker.takePicture()
      self.timerButton.userInteractionEnabled = true
      self.activityIndicator.startAnimating()
      self.timer.invalidate()
      if self.timerOptionChoice == 3 {
        var image :UIImage = UIImage(named: "timer-on-3")!
        self.timerButton.setImage(image, forState: .Normal)
      }
      else {
        var image :UIImage = UIImage(named: "timer-on-10")!
        self.timerButton.setImage(image, forState: .Normal)
      }
      return
    case 1 :
      var image :UIImage = UIImage(named: "timer-on-1")!
      self.timerButton.setImage(image, forState: .Normal)
      return
    case 2 :
      var image :UIImage = UIImage(named: "timer-on-2")!
      self.timerButton.setImage(image, forState: .Normal)
      return
    case 3 :
      var image :UIImage = UIImage(named: "timer-on-3")!
      self.timerButton.setImage(image, forState: .Normal)
      return
    case 4 :
      var image :UIImage = UIImage(named: "timer-on-4")!
      self.timerButton.setImage(image, forState: .Normal)
      return
    case 5 :
      var image :UIImage = UIImage(named: "timer-on-5")!
      self.timerButton.setImage(image, forState: .Normal)
      return
    case 6 :
      var image :UIImage = UIImage(named: "timer-on-6")!
      self.timerButton.setImage(image, forState: .Normal)
      return
    case 7 :
      var image :UIImage = UIImage(named: "timer-on-7")!
      self.timerButton.setImage(image, forState: .Normal)
      return
    case 8 :
      var image :UIImage = UIImage(named: "timer-on-8")!
      self.timerButton.setImage(image, forState: .Normal)
      return
    case 9 :
      var image :UIImage = UIImage(named: "timer-on-9")!
      self.timerButton.setImage(image, forState: .Normal)
      return
    default:
      return
    }
  }
  
  /* IBAction connected to the CameraOverlay.xib file (Menu Button) */
  /* ------------------------------------------------------------------------------------------- */
  @IBAction func goToMenu(sender: AnyObject) {
    self.prepareToLeaveCameraViewController = true
    self.imagePicker.dismissViewControllerAnimated(true, completion: nil)
  }
  
  func segueToMenu(){
    var menuExists = false
    for viewController in self.navigationController!.viewControllers! {
      if viewController.isKindOfClass(MenuViewController)
      {
        menuExists = true
      }
    }
    if menuExists {
      self.performSegueWithIdentifier("unwindToMenuFromCam", sender: self)
    }
    else {
      var mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
      let menuVC = mainStoryBoard.instantiateViewControllerWithIdentifier("MenuViewController") as! MenuViewController
      // Sets the array of viewcontrollers to only the menu.
      self.navigationController?.setViewControllers([menuVC], animated: true)
    }
    
  }
  
  /* Function to add photo Path to an array (new or existing) and then save to the phone */
  /* ------------------------------------------------------------------------------------------- */
  func savePhotoNametoFailedUploads(fileNameWithoutFileExtension : NSString, pathToImage : NSString){

    // If we find some, then add the photo to the array
    if self.cameraData.arrayOfFailedUploadingPhotos != nil
    {
      self.cameraData.arrayOfFailedUploadingPhotos!.append(fileNameWithoutFileExtension)
    }
    else // Create a new array
    {
      self.cameraData.arrayOfFailedUploadingPhotos = [fileNameWithoutFileExtension]
    }

    // Now that the photo is saved to the phone, reenable the take photo button
    dispatch_async(dispatch_get_main_queue())
    {
      self.windTheCamera()
    }
  }
  
  
  /* Function to prepare the cameraViewController with # of photos purchased by User */
  /* ------------------------------------------------------------------------------------------- */
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
    if segue.identifier == "showShippingFormFromCamera" {
      var shippingFormViewController = segue.destinationViewController as! ShippingFormViewController
      shippingFormViewController.shippingHeader = true
      shippingFormViewController.cameFromCamera = true
      if self.failedtoUpdateCompletedRoll {
        shippingFormViewController.failedtoUpdateCompletedRoll = true
      }
    }
    if segue.identifier == "showUploadFromCamera" {
      var uploadingViewController = segue.destinationViewController as! UploadingViewController
      uploadingViewController.cameFromCamera = true
    }
  }
  
  @IBAction func flashButtonPressed(sender: AnyObject) {
      if self.imagePicker.cameraFlashMode == .Off {
        var image :UIImage = UIImage(named: "flash-on")!
        flashButton.setImage(image, forState: .Normal)
        self.imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashMode.On
      }
      else
      {
        var image :UIImage = UIImage(named: "flash-off")!
        self.flashButton.setImage(image, forState: .Normal)
        self.imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashMode.Off
      }
  }
  
  @IBAction func flipCameraButtonPressed(sender: AnyObject) {
    UIView.transitionWithView(self.imagePicker.view, duration: 1.0, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: {
        if self.imagePicker.cameraDevice == UIImagePickerControllerCameraDevice.Rear {
          self.imagePicker.cameraDevice = UIImagePickerControllerCameraDevice.Front
          self.flashButton.hidden = true
        }
        else
        {
          self.imagePicker.cameraDevice = UIImagePickerControllerCameraDevice.Rear
          self.flashButton.hidden = false
        }
      }, completion: nil)
  }
  
  @IBAction func timerButtonPressed(sender: AnyObject) {
    if self.timerOptionsOpen{
      return
    }
    
    self.displayTimerOptionsWithAnimations()
  }
  
  func displayTimerOptionsWithAnimations(){
    self.timerOptionsOpen = true
    // Hide Camera Option
    self.showCameraOptions(false)
    // Move timer to left corner
    var leftCorner : CGPoint = CGPointMake(-29, self.timerButton.center.y)
    self.originalTimerPosition = CGPointMake(self.timerButton.center.x, self.timerButton.center.y)
    UIView.beginAnimations(nil, context: nil)
    UIView.setAnimationDuration(0.2)
    self.timerButton.center = leftCorner
    UIView.commitAnimations()
    // Show Timer Buttons
    self.timerButton.duration = 0.5
    self.timerButton.animateToNext({ () -> () in
      self.showTimerOptions(true)
    })
  }
  
  func hideTimerOptionsWithAnimations(){
    self.timerOptionsOpen = false
    // Hide Timer Options
    self.showTimerOptions(false)
    // Move timer back to original position
    UIView.beginAnimations(nil, context: nil)
    UIView.setAnimationDuration(0.3)
    self.timerButton.center = self.originalTimerPosition
    UIView.commitAnimations()
    // Show Camera Buttons
    self.timerButton.duration = 0.3
    self.timerButton.animateToNext({ () -> () in
      self.showCameraOptions(true)
    })
  }
  
  func showCameraOptions(show : Bool){
    if show {
      // Unhide flash and front/rear buttons
      self.flipCameraButton.hidden = false
      self.flashButton.hidden = false
      // Bounce buttons
      self.flashButton.animation = "zoomIn"
      self.flipCameraButton.animation = "zoomIn"
      self.flipCameraButton.animate()
      self.flashButton.animate()
      // Enable flash and flip
      self.flipCameraButton.userInteractionEnabled = true
      self.flashButton.userInteractionEnabled = true
      return
    }
    else {
      // Hide flash and front/rear buttons
      self.flipCameraButton.hidden = true
      self.flashButton.hidden = true
      // Disable flash and front/rear buttons
      self.flipCameraButton.userInteractionEnabled = false
      self.flashButton.userInteractionEnabled = false
    }
  }
  
  func showTimerOptions(show : Bool) {
    if show {
      // Unhide timer Options
      self.noneOptionForTimer.hidden = false
      self.threeSecOptionForTimer.hidden = false
      self.tenSecOptionForTimer.hidden = false
      // Bounce Buttons
      self.noneOptionForTimer.animation = "pop"
      self.threeSecOptionForTimer.animation = "pop"
      self.tenSecOptionForTimer.animation = "pop"
      self.noneOptionForTimer.animate()
      self.threeSecOptionForTimer.animate()
      self.tenSecOptionForTimer.animate()
      // Enable timer Options
      self.noneOptionForTimer.userInteractionEnabled = true
      self.threeSecOptionForTimer.userInteractionEnabled = true
      self.tenSecOptionForTimer.userInteractionEnabled = true
      return
    }
    else {
      // Hide timer Options
      self.noneOptionForTimer.hidden = true
      self.threeSecOptionForTimer.hidden = true
      self.tenSecOptionForTimer.hidden = true
      // Disable timer Options
      self.noneOptionForTimer.userInteractionEnabled = false
      self.threeSecOptionForTimer.userInteractionEnabled = false
      self.tenSecOptionForTimer.userInteractionEnabled = false
    }
  }
  
  @IBAction func noneButtonPressed(sender: AnyObject) {
    // Hide timer options
    self.hideTimerOptionsWithAnimations()
    // Display chosen item
    self.assignTimerValue("none")
  }
  
  @IBAction func threeSecButtonPressed(sender: AnyObject) {
    // Hide timer options
    self.hideTimerOptionsWithAnimations()
    // Display chosen item
    self.assignTimerValue("three")
  }
  
  @IBAction func tenSecOptionPressed(sender: AnyObject) {
    // Hide timer options
    self.hideTimerOptionsWithAnimations()
    // Display chosen item
    self.assignTimerValue("ten")
  }
  
  func assignTimerValue(choice : String){
    
    switch (choice) {
        case "none" :
          var image :UIImage = UIImage(named: "timer-off")!
          self.timerButton.setImage(image, forState: .Normal)
          self.timerOptionsOpen = false
          self.timerOptionChoice = nil
          // change none-off to none-on
          image = UIImage(named: "none-sec-on")!
          self.noneOptionForTimer.setImage(image, forState: .Normal)
          // change 3-on to 3-off
          image = UIImage(named: "3-sec-off")!
          self.threeSecOptionForTimer.setImage(image, forState: .Normal)
          // change 10-on to 10-off
          image = UIImage(named: "10-sec-off")!
          self.tenSecOptionForTimer.setImage(image, forState: .Normal)
          return
        case "three" :
          var image :UIImage = UIImage(named: "timer-on-3")!
          self.timerButton.setImage(image, forState: .Normal)
          self.timerOptionChoice = 3
          // change none-on to none-off
          image = UIImage(named: "none-sec-off")!
          self.noneOptionForTimer.setImage(image, forState: .Normal)
          // change 3-off to 3-on
          image = UIImage(named: "3-sec-on")!
          self.threeSecOptionForTimer.setImage(image, forState: .Normal)
          // change 10-on to 10-off
          image = UIImage(named: "10-sec-off")!
          self.tenSecOptionForTimer.setImage(image, forState: .Normal)
          return
        case "ten" :
          var image :UIImage = UIImage(named: "timer-on-10")!
          self.timerButton.setImage(image, forState: .Normal)
          self.timerOptionChoice = 10
          // change none-on to none-off
          image = UIImage(named: "none-sec-off")!
          self.noneOptionForTimer.setImage(image, forState: .Normal)
          // change 10-off to 10-on
          image = UIImage(named: "10-sec-on")!
          self.tenSecOptionForTimer.setImage(image, forState: .Normal)
          // change 3-on to 3-off
          image = UIImage(named: "3-sec-off")!
          self.threeSecOptionForTimer.setImage(image, forState: .Normal)
          return
        default :
          break
    }
  }
  
    
}
