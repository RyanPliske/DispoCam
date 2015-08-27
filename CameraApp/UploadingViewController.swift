//
//  UploadingViewController.swift
//  photojojo
//
//  Created by Ryan Pliske on 3/11/15.
//  Copyright (c) 2015 Ochre. All rights reserved.
//

import UIKit
import Crashlytics
import QuartzCore

class UploadingViewController: UIViewController {

    @IBOutlet weak var tryAgainButton: Button!
    @IBOutlet weak var circularArrowImage: UIImageView!
    @IBOutlet weak var uploadCountLabel: SpringLabel!
    @IBOutlet var uploadingView: UIView!
    @IBOutlet var uploadingSuccessView: UIView!
    @IBOutlet weak var uploadingCameraImage: UIImageView!
    // Instantiate Models
    var cameraData : CameraModel!
    var userData : UserModel!
    let jojoAPIHandler: ApiHandlerModel = ApiHandlerModel(baseUrl: ApiConfig.baseUrl, user: ApiConfig.user, password: ApiConfig.password)
    var finalUploadFailedAttempts = 0
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    // get path to Documents folder
    let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
    var rotation = CABasicAnimation(keyPath: "transform.rotation")
    var reach : Reachability?
    var internetIsReachable = false
    var cameFromCamera = false
    var finishUploadAttempts = 0
    let path = UIBezierPath()
    let animation = CAKeyframeAnimation(keyPath: "position")
  
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
        self.cameraData = appDelegate.getCameraInfo()
        self.userData = appDelegate.getUserInfo()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "animateUploadingCameraImage", name: "returnedWhileUploading", object: nil)
        // If Existing 'camera_id' saved on device, then use it.
        if let cameraNSData = NSUserDefaults.standardUserDefaults().objectForKey("camera_id") as? NSData {
          self.cameraData.cameraID = NSKeyedUnarchiver.unarchiveObjectWithData(cameraNSData) as! Int!
          println("Entered Uploading Failure VC : Camera ID is: \(self.cameraData.cameraID)")
        }
        self.userData.getUsername()
        self.userData.getUserId()

        // Rotation initial setup
        rotation.fromValue = NSNumber(float: 0)
        rotation.toValue = NSNumber(double: (2 * M_PI))
        rotation.duration = 2.0 // Speed
        rotation.repeatCount = 1000000 // Repeat For a Long Time (or until I turn it off)
        // Camera Animating upwards thingy initial setup
        path.moveToPoint( CGPoint(x: self.view.center.x - 35, y: self.view.frame.maxY + 60) )
        path.addCurveToPoint(
            // Last Point to move to (aka defined end Point)
            CGPoint(x: self.view.center.x - 15, y: -50),
            // First Point to move to
            controlPoint1: CGPoint(x: self.view.center.x - 55, y: self.view.frame.maxY  - 200),
            // Second Point to move to
            controlPoint2: CGPoint(x: self.view.center.x + 70 , y: 150)
        )
        animation.path = path.CGPath
        animation.repeatCount = Float.infinity
        animation.duration = 2.5
        // If User came here from camera, automatically try again, else wait for user to click the button
        if cameFromCamera {
          NSBundle.mainBundle().loadNibNamed("Uploading", owner: self, options: nil)
          if let aUploadingView = uploadingView{
            self.view.addSubview(aUploadingView)
          }
          uploadingView.frame = self.view.frame
          self.animateUploadingCameraImage()
          NSTimer.scheduledTimerWithTimeInterval(6.0, target: self, selector: "tryAgain", userInfo: nil, repeats: false)
          self.uploadCountLabel.superview?.bringSubviewToFront(uploadCountLabel)
        }
    }
  
    /* Once Okay Fantastic Button is pressed, either unwind to Buy New VC or push a new one. */
    /* ------------------------------------------------------------------------------------------- */
    @IBAction func okayFantasticButtonPressed(sender: AnyObject) {
      for viewController in self.navigationController!.viewControllers! {
        if viewController.isKindOfClass(BuyNewRollViewController)
        {
          self.performSegueWithIdentifier("unwindToBuyNewFromUploadSuccess", sender: self)
          println("going back to Buy New")
          return
        }
      }
      println("showing new Buy New")
      self.performSegueWithIdentifier("showBuyNewFromUpload", sender: self)
      return
    }
  
    /* Spin the arrow */
    /* ------------------------------------------------------------------------------------------- */
    func animateUploadingCameraImage()
    {
        if uploadingCameraImage != nil{
          self.uploadingCameraImage.layer.addAnimation(animation, forKey: "animateGoodJobCamImage")
        }
    }
  
    func displayFailure(){
      self.finishUploadAttempts = 0
      self.uploadCountLabel.hidden = true
      UIApplication.sharedApplication().networkActivityIndicatorVisible = false
      UIView.transitionWithView(self.view, duration: 3.0, options: UIViewAnimationOptions.TransitionCurlUp , animations: {self.uploadingView.removeFromSuperview()}, completion: nil)
    }
  
    func displaySuccess(){
      println("Finished with the Upload Checking. Now Going to Success Screen.")
      // Clear out the photo data from the device
      self.cameraData.deleteCameraFromUsersDevice()
      UIApplication.sharedApplication().networkActivityIndicatorVisible = false
      NSBundle.mainBundle().loadNibNamed("UploadingSuccess", owner: self, options: nil)
      if uploadingView != nil {
        self.uploadingView.removeFromSuperview()
      }
      if let aUploadingView = uploadingSuccessView{
        UIView.transitionWithView(self.view, duration: 3.0, options: UIViewAnimationOptions.TransitionCurlUp , animations: {self.view.addSubview(aUploadingView)}, completion: nil)
      }
      uploadingSuccessView.frame = self.view.frame
      uploadingSuccessView = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func tryAgainButtonPressed(sender: AnyObject) {
      reach = Reachability.reachabilityForInternetConnection()
      if reach != nil {
        var networkStatus = reach!.currentReachabilityStatus()
        if networkStatus != NetworkStatus.NotReachable {
          self.internetIsReachable = true
        }
      }
      if !internetIsReachable {
        Alert(title: "Network Error", message: "To perform this action you need an internet connection.\nPlease try back in a bit!").show()
      }
      else {
        self.tryAgainButton.userInteractionEnabled = false
        self.circularArrowImage.layer.addAnimation(rotation, forKey: "Spin")
        NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: "tryAgain", userInfo: nil, repeats: false)
      }
    }
  
    func tryAgain(){
      UIApplication.sharedApplication().networkActivityIndicatorVisible = true
      self.uploadCountLabel.hidden = false
      // 1. Look for any photos in the failed-to-upload-photos array, If there are any, then attempt to send those to S3 Bucket
      if self.cameraData.arrayOfFailedUploadingPhotos != nil {
        if self.cameraData.arrayOfFailedUploadingPhotos.count > 0 {
          self.updateCountLabel()
          self.sendFailedPhotosToAmazon()
          return
        }
      }
      
      if self.cameraData.arrayOfFailedUploadingPhotoParameters != nil {
        if self.cameraData.arrayOfFailedUploadingPhotoParameters.count > 0 {
          self.updateCountLabel()
          self.sendFailedParamsToJoJoDb()
          return
        }
      }
      println("Didn't Find any failed photos or photo data. Attempting to Update_Complete_Roll in JoJo DB.")
      // update `roll_completed_at` field in the cameras table with today's date
      self.updateCompletedRoll()
    }
  
  func updateCountLabel(){
    
    if let archivedPhotoCount = NSUserDefaults.standardUserDefaults().objectForKey("numOfPhotosPurchased") as? NSData {
      if let photoCount = NSKeyedUnarchiver.unarchiveObjectWithData(archivedPhotoCount) as? Int {
        if let jojosFailed = self.cameraData.arrayOfFailedUploadingPhotos {
          self.uploadCountLabel.text = "\(photoCount - jojosFailed.count)/\(photoCount)"
        }
        else {
          finishUploadAttempts++
          if finishUploadAttempts == 1 {
            self.uploadCountLabel.text = "Finishing..."
            self.uploadCountLabel.animation = "flash"
            self.uploadCountLabel.animate()
          }
        }
      }
    }
  }
  
  func updateCompletedRoll(){
    // Send PUT request to cameras/id
    let currentDate = NSDate()
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateString = dateFormatter.stringFromDate(currentDate)
    let params = ["shots_used" : "\(self.cameraData.numberOfPhotosUsed)", "roll_completed_at" : dateString]
    
    jojoAPIHandler.PUT("cameras/\(cameraData.cameraID)", parameters: params) { jsonResponse in
      if jsonResponse == nil {
        self.notifyUserOfUploadFailure()
      }
      else {
        // Show Camera Upload Success or Error
        self.displaySuccess()
      }
    }
  }
  
  func sendFailedPhotosToAmazon(){
    println("There are \(self.cameraData.arrayOfFailedUploadingPhotos.count) in the AWS S3 Failed Array.")
    println("")
    let photo = self.cameraData.arrayOfFailedUploadingPhotos[0]
    let photoName = (photo as String) + ".jpg"
    var pathToImage : NSString = self.documentsPath.stringByAppendingPathComponent(photoName)
    self.finalAttemptToUploadPhotoToS3(pathToImage, dateString: photo as String) {
      () in
        self.sendFailedPhotosToAmazon()
    }
  }
  
  func sendFailedParamsToJoJoDb(){
    println("There are \(self.cameraData.arrayOfFailedUploadingPhotoParameters.count) in JoJo Failed Array.")
    println("")
    let photoParams = self.cameraData.arrayOfFailedUploadingPhotoParameters[0]
    self.createNewPhotoInDatabase(photoParams){
      () in
      self.sendFailedParamsToJoJoDb()
    }
  }
  
  /* Final upload to Amazon's S3 cluster  Upon Success, params get added to end of Params Array */
  /* ------------------------------------------------------------------------------------------- */
  func finalAttemptToUploadPhotoToS3(pathToImage: NSString, dateString: String, completion : ()-> () ) {
    println("Attempting to Upload to S3...")
    // Create AWS transfer Manager
    let transferManager = AWSS3TransferManager.defaultS3TransferManager()
    let uploadRequest : AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
    // Get ready for AWS Upload
    let ourDataFileURL = NSURL(fileURLWithPath: pathToImage as String)
    // Grab image from filepath
    if !NSFileManager.defaultManager().fileExistsAtPath(pathToImage as String){
      println("IMAGE DOES NOT EXIST IN DOCUMENTS FOLDER")
      return
    }
    println("IMAGE EXISTS IN DOCUMENTS FOLDER")
    
    // Set folder path in which to save the photo to Amazon S3
    // Theoretically, these return statements should be skipped.
    if let unique_phone_id = self.userData.username {
    } else { return }
    if let camera_id = self.cameraData.cameraID {
    } else { return }
    
    // Set upload request parameters
    uploadRequest.bucket = "photojojo-dca"
    uploadRequest.key =  "uploads/\(self.userData.username!)/\(self.cameraData.cameraID!)/\(dateString).jpg"
    uploadRequest.body = ourDataFileURL
    
    
    // BFTask Documentation : http://docs.aws.amazon.com/mobile/sdkforios/developerguide/bftask.html
    let task = transferManager.upload(uploadRequest)
    dispatch_async(dispatch_get_main_queue())
    {
      task.continueWithBlock { (task) -> AnyObject! in
        // If Error in upload
        if task.error != nil
        {
          dispatch_async(dispatch_get_main_queue())
          {
            self.finalUploadFailedAttempts++
            if self.finalUploadFailedAttempts == 1 {
              self.displayFailure()
            }
            else {
              self.notifyUserOfUploadFailure()
            }
          }
        }
        else
        {
          dispatch_async(dispatch_get_main_queue())
          {
            // Successful Upload
            println("Upload to S3 successful.")
            // Remove from failed Photos Array
            self.removePhotoFromFailedUploads(dateString)
              { () in
              // then append the params to Failed-To-upload-to-JoJo-Queue
              var paramsToAdd : NSDictionary = [
                "camera_id" : "\(self.cameraData.cameraID!)",
                "bucket" : uploadRequest.bucket,
                "file_name" : uploadRequest.key,
                "sort_id" : ""
              ]
              self.savePhotoMetaDataToPhotoParamsArray(paramsToAdd){
                () in
                completion()
              }
            }
          }
        }
        return nil
      } // End task to Amazon
    }
  }
  
  /* Function to add photo Path to an array (new or existing) and then save to the phone */
  /* ------------------------------------------------------------------------------------------- */
  func savePhotoMetaDataToPhotoParamsArray(paramsToAdd : NSDictionary, completion : ()->()){
    
    if self.cameraData.arrayOfFailedUploadingPhotoParameters != nil
    {
      self.cameraData.arrayOfFailedUploadingPhotoParameters!.append(paramsToAdd)
    }
    else // Create a new array
    {
      self.cameraData.arrayOfFailedUploadingPhotoParameters = [paramsToAdd]
    }
    // Check if S3 Array is out
    // If we're finally out of photos then delete array from camera Model and from Device
    if self.cameraData.arrayOfFailedUploadingPhotos.count == 0 {
      self.failedS3PhotosFinishedUploading()
    }
    else{
      completion()
    }
  }
  
  func notifyUserOfUploadFailure(){
    self.finishUploadAttempts = 0
    self.uploadCountLabel.hidden = true
    // Stop Spinning Wheel and Enable Button to be Repressed
    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    self.tryAgainButton.userInteractionEnabled = true
    self.circularArrowImage.layer.removeAnimationForKey("Spin")
    Alert(title: "Network Error", message: "We're sorry. We are having difficulties processing your order. Please try again in a bit!").show()
  }
  
  /* Function to send photo information to the Photo JoJo Database from the PhotoParams Array */
  /* ------------------------------------------------------------------------------------------- */
  func createNewPhotoInDatabase(photoParams : NSDictionary, completion : ()->()) {
    println("Attempting to send photo details to PhotoJoJo Database For the Last Time...")
    jojoAPIHandler.POST("photos", parameters: photoParams as? [String : AnyObject]) { jsonResponse in
      if jsonResponse == nil{
        self.finalUploadFailedAttempts++
        if self.cameFromCamera && self.finalUploadFailedAttempts == 1{
          self.displayFailure()
        }
        else {
          self.notifyUserOfUploadFailure()
        }
      }
      else {
        // If success, remove from array
        self.removePhotoParamsFromFailedUploads(photoParams) {
          () in
          completion()
        }
      }
    }
  }
  
  /* Function to remove photo params from failed Uploads */
  /* ------------------------------------------------------------------------------------------- */
  func removePhotoParamsFromFailedUploads(paramsToRemove : NSDictionary, completion : ()->()){
    
    // Find Index of the photo Path
    if let unwrappedArrayOfFailedUploadingPhotoParameters = self.cameraData.arrayOfFailedUploadingPhotoParameters {
      if let index = find(unwrappedArrayOfFailedUploadingPhotoParameters, paramsToRemove) {
        // Remove that index from the Array
        CLSLogv("from UploadingViewController ~line 326; Removing index %d from failedToUploadParams-to-JoJo Array who's count = %d", getVaList([index, self.cameraData.arrayOfFailedUploadingPhotoParameters.count]))
        println("Removing index \(index) from failedToUploadParams-to-JoJo Array who's count = \(self.cameraData.arrayOfFailedUploadingPhotoParameters.count)")
        self.cameraData.arrayOfFailedUploadingPhotoParameters.removeAtIndex(index)
      
        // Record how many photos we have left
        println("Photos left in failedToUploadTo JoJo Array: \(self.cameraData.arrayOfFailedUploadingPhotoParameters.count)")
        CLSLogv("Photos left in failedToUploadTo JoJo Array: %d", getVaList([index, self.cameraData.arrayOfFailedUploadingPhotoParameters.count]))
      }
      self.updateCountLabel()
      // If we're finally out of photos then go to Success screen.
      if self.cameraData.arrayOfFailedUploadingPhotoParameters.count == 0 {
        self.failedJoJoDataFinishedUploading()
      }
      else {
        completion()
      }
      
    }
  }
  
  /* Function to remove photo Path from failed Uploads */
  /* ------------------------------------------------------------------------------------------- */
  func removePhotoFromFailedUploads(photoToRemove : NSString, completion : ()->()){
    // Find Index of the photo Path
    var index : Int = 0
    for photo in self.cameraData.arrayOfFailedUploadingPhotos{
      if photo == photoToRemove {
        break
      }
      index++
    }
    // Remove that index from the Array
    CLSLogv("from UploadingViewController ~line 391; Removing index %d from failedToUpload Array who's count = %d", getVaList([index, self.cameraData.arrayOfFailedUploadingPhotos.count]))
    println("Removing index \(index) from failedToUpload Array who's count = \(self.cameraData.arrayOfFailedUploadingPhotos.count)")
    self.cameraData.arrayOfFailedUploadingPhotos.removeAtIndex(index)
    
    println("Photos left: \(self.cameraData.arrayOfFailedUploadingPhotos.count)")
    CLSLogv("Photos left in failedToUploadToS3 Array: %d", getVaList([index, self.cameraData.arrayOfFailedUploadingPhotos.count]))
    self.updateCountLabel()
    completion()
  }
  
  func failedS3PhotosFinishedUploading(){
    println("S3 Photos Depleted.")
    // Delete Array
    self.cameraData.arrayOfFailedUploadingPhotos = nil
    // Set User Defaults array to nil
    NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "photosThatFailedToUpload")
    // Start sending the params to JoJo
    self.sendFailedParamsToJoJoDb()
  }
  
  func failedJoJoDataFinishedUploading(){
    println("JoJo params depleted.")
    // Delete Array
    self.cameraData.arrayOfFailedUploadingPhotoParameters = nil
    // Set User Defaults array to nil
    NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "photoParamsThatFailedToUpload")
    // Update Roll
    self.updateCompletedRoll()
  }
}
