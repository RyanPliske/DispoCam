//
//  BuyNewRollViewController
//  PaymentPresenter created by jflinter of Stripe-ios.
//
//  Created by Ryan Pliske on 1/21/15.
//  Copyright (c) 2015 Ochre. All rights reserved.
//

import UIKit
import Alamofire
import PassKit
import Crashlytics

class BuyNewRollViewController: UIViewController, UITextFieldDelegate, PKPaymentAuthorizationViewControllerDelegate {

  var cameraPrice : Float = 12.99 // this is in dollars
  // Apple Pay
  let paymentRequest = Stripe.paymentRequestWithMerchantIdentifier(StripeConfig.appleMerchantId)
  // Make the App Delegate methods available to this view controller
  let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
  var userDatabaseData : UserModel!
  var cameraData : CameraModel!
  @IBOutlet weak var camIconImage: SpringImageView!
  @IBOutlet weak var giftCodeButton: SpringButton!
  @IBOutlet weak var giftCodeTextField: UITextField!
  @IBOutlet weak var checkButton: UIButton!
  @IBOutlet weak var giftCodeLabel: UILabel!
  @IBOutlet weak var giftCodeSuccessImage: SpringImageView!
  @IBOutlet weak var applePayButton: UIButton!
  @IBOutlet weak var buyNowButton: UIButton!
  @IBOutlet weak var priceLabel: UIImageView!
  @IBOutlet weak var buyNewRollView: UIView!
  @IBOutlet weak var menuButton: UIButton!
  @IBOutlet weak var giftCodeSuccessLabel: SpringLabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBarHidden = true
    self.giftCodeTextField.delegate = self
    // instantiate UserModel with user_id
    self.cameraData = appDelegate.getCameraInfo()
    self.userDatabaseData = appDelegate.getUserInfo()
    self.userDatabaseData.getUserId()
    self.camIconImage.hidden = true
    
    if !Stripe.canSubmitPaymentRequest(self.paymentRequest) {
      // Hide Apple Pay and Buy New Button
      self.applePayButton.userInteractionEnabled = false
      self.applePayButton.hidden = true
      self.buyNowButton.userInteractionEnabled = false
      self.buyNowButton.hidden = true
      // Add New Buy Now Button
      var image :UIImage = UIImage(named: "camera-inactive-button")!
      var frame = CGRectMake(self.view.center.x, self.view.center.y, self.view.frame.width * 0.8, 50)
      var newBuyNowButton : UIButton = UIButton(frame: frame)
      newBuyNowButton.setImage(image, forState: .Normal)
      newBuyNowButton.addTarget(self, action: "newBuyNowButtonPressed", forControlEvents: UIControlEvents.TouchUpInside)
      newBuyNowButton.center = CGPointMake(self.view.center.x, self.buyNowButton.center.y + 10)
      self.buyNewRollView.addSubview(newBuyNowButton)
      // Add Constraints to new Buy Now Button
      newBuyNowButton.setTranslatesAutoresizingMaskIntoConstraints(false)
      var buyNowButtonsWidth = NSLayoutConstraint(item: newBuyNowButton, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.buyNewRollView, attribute: .Width, multiplier: 0.8, constant: 0)
      var heightBelowPriceLabel = NSLayoutConstraint(item: newBuyNowButton, attribute: NSLayoutAttribute.Top, relatedBy: .Equal, toItem: self.priceLabel, attribute: .Bottom, multiplier: 1.0, constant: 12.0)
      var buyNowButtonCenter = NSLayoutConstraint(item: newBuyNowButton, attribute: .CenterX, relatedBy: .Equal, toItem: self.buyNewRollView, attribute: .CenterX, multiplier: 1.0, constant: 0)
      self.buyNewRollView.addConstraint(buyNowButtonsWidth)
      self.buyNewRollView.addConstraint(heightBelowPriceLabel)
      self.buyNewRollView.addConstraint(buyNowButtonCenter)
      self.menuButton.superview?.bringSubviewToFront(menuButton)
    }
    // This code is implemented so if Photojojo wants to use it to send coupons
    // in an email, the user can simply click the link and it will open the Photojojo app if it's installed on the user's phone.
    // NSNotificationCenter.defaultCenter().addObserver(self, selector: "validateCouponFromURL:", name: "returnToAppWithCouponToken", object:nil)
  }
  
  override func viewWillAppear(animated: Bool) {
    self.giftCodeButton.hidden  = false
    self.giftCodeButton.userInteractionEnabled = true
    self.giftCodeTextField.hidden = true
    self.giftCodeTextField.userInteractionEnabled = false
    self.checkButton.hidden = true
    self.checkButton.userInteractionEnabled = false
    self.giftCodeLabel.hidden = true
    self.giftCodeSuccessImage.hidden = true
    self.giftCodeSuccessLabel.hidden = true
  }
  
  override func viewDidAppear(animated: Bool) {
    self.camIconImage.hidden = false
    self.camIconImage.duration = 0.5
    self.camIconImage.animation = "slideDown"
    self.camIconImage.animate()
  }
  
  override func viewWillDisappear(animated: Bool) {
    self.camIconImage.hidden = true
  }
  
  @IBAction func BuyNowButtonPressed(sender: AnyObject) {
    if userDatabaseData.user_id == nil || userDatabaseData.username == nil {
      self.userDatabaseData.createNewUser {(networkError) in
        if networkError != nil {
          // display network error
          self.displayNetworkError("\(networkError)")
        }
        else {
          self.performSegueWithIdentifier("segueToShippingFormFromBuyNew", sender: nil)
        }
      }
      return
    }
    
    self.performSegueWithIdentifier("segueToShippingFormFromBuyNew", sender: nil)
  }
  
  func newBuyNowButtonPressed(){
    if userDatabaseData.user_id == nil || userDatabaseData.username == nil {
      self.userDatabaseData.createNewUser {(networkError) in
        if networkError != nil {
          // display network error
          self.displayNetworkError("\(networkError)")
        }
        else {
          self.performSegueWithIdentifier("segueToShippingFormFromBuyNew", sender: nil)
        }
      }

      return
    }
    
    self.performSegueWithIdentifier("segueToShippingFormFromBuyNew", sender: nil)
  }
  
  @IBAction func menuButtonPressed(sender: AnyObject) {
    for viewController in self.navigationController!.viewControllers! {
      if viewController.isKindOfClass(MenuViewController)
      {
        self.performSegueWithIdentifier("unwindToMenuFromBuyNew", sender: nil)
        return
      }
    }
      self.performSegueWithIdentifier("showHomeFromBuyNew", sender: nil)
  }
  
  /* Function to go to Unwrap Animation */
  /* ------------------------------------------------------------------------------------------- */
  func goToUnwrapAnimation() {
    // Go to Unwrap Animation
    self.performSegueWithIdentifier("showUnwrapFromBuyNewRoll", sender: self)
  }
  
  @IBAction func giftCodeButtonPressed(sender: AnyObject) {
      self.resetCouponButtonsAndLabels()
      self.giftCodeButton.hidden = true
      self.giftCodeButton.userInteractionEnabled = false
      self.giftCodeTextField.hidden = false
      self.giftCodeTextField.userInteractionEnabled = true
      self.checkButton.hidden = false
      self.checkButton.userInteractionEnabled = true
      self.giftCodeLabel.hidden = false
      self.giftCodeSuccessImage.hidden = false
  }

  
  override func shouldAutorotate() -> Bool {
    return false
  }
  
  @IBAction func unwindToBuyNewRoll(segue: UIStoryboardSegue) {}
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    self.giftCodeTextField.resignFirstResponder()
    // remove white space from user input
    var userInput = self.giftCodeTextField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    userInput = userInput.stringByReplacingOccurrencesOfString(" ", withString: "a", options: nil, range: nil)
    if userDatabaseData.user_id == nil || userDatabaseData.username == nil {
      self.userDatabaseData.createNewUser {(networkError) in
        if networkError != nil {
          // display network error
          self.displayNetworkError("\(networkError)")
        }
        else {
          self.sendCouponToBackendForValidation(userInput)
        }
      }
      return true
    }
    self.sendCouponToBackendForValidation(userInput)
    return true
  }
    
  @IBAction func checkButtonPressed(sender: AnyObject) {
    checkButton.userInteractionEnabled = false
    self.giftCodeTextField.resignFirstResponder()
    var userInput = self.giftCodeTextField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    userInput = userInput.stringByReplacingOccurrencesOfString(" ", withString: "a", options: nil, range: nil)
    if userInput == "" {
        Alert(title: "Wait!", message: "Please Enter a Code First!").show()
        checkButton.userInteractionEnabled = true
        return
    }
    if userDatabaseData.user_id == nil || userDatabaseData.username == nil {
      self.userDatabaseData.createNewUser {(networkError) in
        if networkError != nil {
          // display network error
          self.displayNetworkError("\(networkError)")
        }
        else {
          self.sendCouponToBackendForValidation(userInput)
        }
      }

      return
    }
    self.sendCouponToBackendForValidation(userInput)
  }
  
  func sendCouponToBackendForValidation(couponCode : String){
    self.cameraData.readAPIForCouponExistence(couponCode, completion: { (result) -> () in
        switch result {
        case .Success():
           self.couponGETSuccess()
        case .Failure(let errString):
            self.couponGETFail()
        case .NetworkFailure():
            self.displayNetworkError("No Internet Connection. Please Try Back Later.")
            self.checkButton.userInteractionEnabled = true
        }
    })
  }
  
  func couponGETSuccess(){
    // Format to Currency for Displaying Price
    var formatter = NSNumberFormatter()
    formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
    formatter.locale = NSLocale.currentLocale()
    if let couponDollarAmountString = formatter.stringFromNumber(self.cameraData.couponDollarAmount) {
    
      // Check how many uses the Coupon has left
      if self.cameraData.couponUsesLeft <= 0 {
        var image :UIImage = UIImage(named: "check-pink")!
        self.checkButton.setImage(image, forState: .Normal)
        self.giftCodeSuccessLabel.hidden = true
        image = UIImage(named: "gift-code-error")!
        self.giftCodeSuccessImage.image = image
        self.giftCodeSuccessImage.animation = "flash"
        self.giftCodeSuccessImage.animate()
        return
      }
      // Reset UI Buttons and stuff to show success
      var image :UIImage = UIImage(named: "check-green")!
      self.checkButton.setImage(image, forState: .Normal)
      // Disable sending the GET request again
      self.checkButton.userInteractionEnabled = false
      self.giftCodeTextField.userInteractionEnabled = false
      // Set Animation
      self.giftCodeSuccessLabel.animation = "fadeIn"
      
      // Decrease camera Price by coupon dollar amount
      if let dollAmt = self.cameraData.couponDollarAmount {
          println("This coupon is worth \(dollAmt)")
          self.giftCodeSuccessImage.image = nil
          var newCameraPrice = self.cameraPrice - Float(dollAmt)

          // (If coupon makes camera free, then go to unwrap animation view conroller)
          if newCameraPrice <= 0  {
            println("This camera is FREE for the user!")
            var priceString = "LOOKS GOOD! WE APPLIED YOUR " + couponDollarAmountString + "."
            var priceMutableString = NSMutableAttributedString(string: priceString)
            if let boldFont = UIFont(name: "DIN-Bold", size: 12.0) {
              // Find Price Range
              var range = priceString.rangeOfString(couponDollarAmountString)
              var startPriceRange = distance(priceString.startIndex, range!.startIndex)
              var lengthPriceRange = distance(range!.startIndex, range!.endIndex)
              var nsPriceRange = NSMakeRange(startPriceRange, lengthPriceRange)
              priceMutableString.addAttribute(NSFontAttributeName, value: boldFont, range: nsPriceRange)
              self.giftCodeSuccessLabel.attributedText = priceMutableString
              self.giftCodeSuccessLabel.hidden = false
              self.giftCodeSuccessLabel.animate()
              NSTimer.scheduledTimerWithTimeInterval(2.3, target: self, selector: "cameraIsNowFree", userInfo: nil, repeats: false)
            }
          }
          else {
              if let boldFont = UIFont(name: "DIN-Bold", size: 12.0){
                let textFont = [NSFontAttributeName : boldFont]
                self.giftCodeSuccessImage.image = nil
                var priceMutableString = NSMutableAttributedString(string: "LOOKS GOOD! WE APPLIED YOUR " )
                var couponDollarAmountMutableString = NSAttributedString(string: couponDollarAmountString, attributes: textFont)
                priceMutableString.appendAttributedString(couponDollarAmountMutableString)
                var tap = NSAttributedString(string: ".\nTAP ")
                priceMutableString.appendAttributedString(tap)
                var buyNow = NSAttributedString(string: "BUY NOW", attributes : textFont)
                priceMutableString.appendAttributedString(buyNow)
                if Stripe.canSubmitPaymentRequest(self.paymentRequest) {
                  var ors = NSAttributedString(string: " OR ")
                  priceMutableString.appendAttributedString(ors)
                  var applePayString = NSAttributedString(string: "APPLE PAY", attributes : textFont)
                  priceMutableString.appendAttributedString(applePayString)
                }
                var toContinueString = NSAttributedString(string: " TO CONTINUE.")
                priceMutableString.appendAttributedString(toContinueString)
                self.giftCodeSuccessLabel.numberOfLines = 2
                self.giftCodeSuccessLabel.attributedText = priceMutableString
                self.giftCodeSuccessLabel.hidden = false
                self.giftCodeSuccessLabel.animate()
              }
            }
          }
        }
      }
    
    func couponGETFail(){
        // Notify User Coupon does not exist
        var image :UIImage = UIImage(named: "check-pink")!
        self.checkButton.setImage(image, forState: .Normal)
        image = UIImage(named: "gift-code-error")!
        self.giftCodeSuccessImage.image = image
        self.giftCodeSuccessImage.velocity = 0.5
        self.giftCodeSuccessImage.animation = "flash"
        self.giftCodeSuccessImage.animate()
        checkButton.userInteractionEnabled = true
    }

  func cameraIsNowFree(){
    // Set number of Photos Purchased equal to num Of Photos the Coupon is good for
    // self.cameraData.numberOfPhotosPurchased = 3 // FIXME this line. It's for testing
    self.cameraData.numberOfPhotosPurchased = self.cameraData.couponNumOfPhotos
    self.cameraData.createNewCamera(nil, userId : self.userDatabaseData.user_id!) { (backendError) in
      if backendError == nil {
        self.goToUnwrapAnimation()
      }
      else {
        Alert(title: "Sorry!", message: "\(backendError)").show()
      }
    }
    // Enable the check button
    // and remove the text and message
    // once the user has moved on to the camera
    var delta: Int64 = 2 * Int64(NSEC_PER_SEC)
    var time = dispatch_time(DISPATCH_TIME_NOW, delta)
    dispatch_after(time, dispatch_get_main_queue(), {
      self.resetCouponButtonsAndLabels()
    })
  }
  
  func resetCouponButtonsAndLabels(){
    self.checkButton.userInteractionEnabled = true
    self.giftCodeTextField.text = ""
    self.checkButton.setImage(UIImage(named: "check-blue")!, forState: .Normal)
    self.giftCodeSuccessImage.image = nil
  }
  
  func displayNetworkError(error : String){
    let alert = UIAlertView()
    alert.title = "Network Failure"
    alert.addButtonWithTitle("OK")
    alert.message = error
    alert.show()
  }
  
  @IBAction func applePayButtonPressed(sender: AnyObject) {
    if userDatabaseData.user_id == nil || userDatabaseData.username == nil {
      self.userDatabaseData.createNewUser {(networkError) in
        if networkError != nil {
          // display network error
          self.displayNetworkError("\(networkError)")
        }
      }
      return
    }
    
    // Display Real Apple Pay View
    var cameraPriceString : String = ""
    
    if self.cameraData.couponDollarAmount != nil {
      cameraPriceString = "\(self.cameraPrice - Float(self.cameraData.couponDollarAmount))"
    }
    else {
      cameraPriceString = "\(self.cameraPrice)"
    }
    self.paymentRequest.paymentSummaryItems = [PKPaymentSummaryItem(label: "Photojojo: New Camera Roll", amount: NSDecimalNumber(string: cameraPriceString))]
    let paymentAuthViewController = PKPaymentAuthorizationViewController(paymentRequest: self.paymentRequest)
    paymentAuthViewController.delegate = self
    presentViewController(paymentAuthViewController, animated: true, completion: nil)

  }
  
  func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController!) {
    dismissViewControllerAnimated(true, completion: nil)
    println("Apple Pay Returned.")
    // If user successfully purchased camera
    if NSUserDefaults.standardUserDefaults().objectForKey("camera_id") != nil {
      self.goToUnwrapAnimation()
    }
  }
  
  func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController!, didAuthorizePayment payment: PKPayment!, completion: ((PKPaymentAuthorizationStatus) -> Void)!) {
    let apiClient = STPAPIClient(publishableKey: StripeConfig.publishableKey)
    apiClient.createTokenWithPayment(payment, completion: { (token: STPToken!, error: NSError!) -> Void in
      if error == nil {
        
        // Send token to backend to be charged
        self.cameraData.createNewCamera(token, userId: self.userDatabaseData.user_id!){ (backendError) in
          if backendError == nil {
            completion(PKPaymentAuthorizationStatus.Success)
          }
          else {
            completion(PKPaymentAuthorizationStatus.Failure)
            Alert(title: "Apple Pay Error", message: "\(backendError)").show()
          }
        }
      }
      else {
        completion(PKPaymentAuthorizationStatus.Failure)
        Alert(title: "Apple Pay Error", message: "\(error)").show()
      }
    })
  }
  
}



