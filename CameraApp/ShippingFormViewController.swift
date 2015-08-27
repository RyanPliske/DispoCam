//
//  ShippingFormViewController.swift
//  photojojo
//
//  Created by Adam Bowen on 12/10/14.
//  Copyright (c) 2014 Ochre. All rights reserved.
//

import UIKit
import Crashlytics
import Alamofire

class ShippingFormViewController: UIViewController, UITextFieldDelegate {
  var userDatabaseData: UserModel!
  // Make the App Delegate methods available to this view controller
  let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
  
  var shippingHeader = false
  var cameFromCamera = false
  var cameFromMenu = false
  var failedtoUpdateCompletedRoll = false
  var attemptsToUpdateRoll = 0
  var cameraData = CameraModel(apiHandler: ApiHandlerModel(baseUrl: ApiConfig.baseUrl, user: ApiConfig.user, password: ApiConfig.password))
  let jojoAPIHandler: ApiHandlerModel = ApiHandlerModel(baseUrl: ApiConfig.baseUrl, user: ApiConfig.user, password: ApiConfig.password)
  @IBOutlet weak var shippingAndBillingHeaderImage: UIImageView!
  @IBOutlet weak var firstNameField: TextField!
  @IBOutlet weak var lastNameField:  TextField!
  @IBOutlet weak var emailField:     TextField!
  @IBOutlet weak var addressField:   TextField!
  @IBOutlet weak var suiteField:     TextField!
  @IBOutlet weak var cityField:      TextField!
  @IBOutlet weak var stateButton:    SelectButton!
  @IBOutlet weak var zipcodeField:   TextField!
  @IBOutlet weak var submitButton:   Button!
  @IBOutlet weak var goBackButton: UIButton!
  @IBOutlet weak var hiddenGoToBillingButton: UIButton!
  @IBOutlet weak var shippingBillingLabel: UIImageView!
    
  
  @IBAction func submit(sender: AnyObject) {
    self.view.endEditing(true)
    submit()
  }
  
  @IBAction func showStateTable(sender: AnyObject) {
    goToStateView()
  }
  
  @IBAction func goBack(sender: AnyObject) {
    for viewController in self.navigationController!.viewControllers! {
      if viewController.isKindOfClass(MenuViewController)
      {
        self.performSegueWithIdentifier("unwindToMenuFromShipping", sender: nil)
        return
      }
    }
    // Else return to buy new
    self.performSegueWithIdentifier("unwindToBuyNewFromShipping", sender: nil)
  }
    
  var selectedState: String?
  var shippingAddress: AddressModel!
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  /* viewDidLoad occurs once when it's loaded. If you return to this view, it's not called */
  /* ------------------------------------------------------------------------------------------- */
  override func viewDidLoad() {
    self.cameraData = appDelegate.getCameraInfo()
    self.navigationController?.navigationBarHidden = true

    if cameFromCamera {
      self.goBackButton.userInteractionEnabled = false
      self.goBackButton.hidden = true
      self.hiddenGoToBillingButton.userInteractionEnabled = false
      self.shippingBillingLabel.hidden = true
    }
    if shippingHeader {
      self.shippingAndBillingHeaderImage.image = UIImage(named: "shipping-header")
      self.shippingBillingLabel.hidden = true
      var image = UIImage(named: "shipping-form-save-button")
      self.submitButton.setImage(image, forState: UIControlState.Normal)
    }
    // Check for saved Shipping Address
    self.shippingAddress = self.checkForExistingAddress()
    if self.shippingAddress != nil {
      println("found shipping Address on phone. Adding info to submission form...")
      // Display info in the text labels
      firstNameField.text = self.shippingAddress.firstName
      lastNameField.text  = self.shippingAddress.lastName
      emailField.text     = self.shippingAddress.email
      addressField.text   = self.shippingAddress.address1
      suiteField.text     = self.shippingAddress.address2
      cityField.text      = self.shippingAddress.city
      zipcodeField.text   = self.shippingAddress.zipcode
      self.selectedState  = self.shippingAddress.state
    }
    // Grab current User info (user_id in particular, which is set in the BuyNewRollViewController)
    self.userDatabaseData = appDelegate.getUserInfo()
  }
  
  override func viewDidAppear(animated: Bool) {}
  
  /* Called when View is about to appear */
  /* ------------------------------------------------------------------------------------------- */
  override func viewWillAppear(animated: Bool) {
    // Check for Selected State
    if let state = self.selectedState {
      self.stateButton.setTitle(state.uppercaseString, forState: UIControlState.Normal)
    }
  }
  
  /* Function to allow user to go from Text Field to Next Text Field by pressing Return on their Keyboard */
  /* ------------------------------------------------------------------------------------------- */
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    
    if textField == firstNameField {
      lastNameField.becomeFirstResponder()
    } else if textField == lastNameField {
      emailField.becomeFirstResponder()
    } else if textField == emailField {
      addressField.becomeFirstResponder()
    } else if textField == addressField {
      suiteField.becomeFirstResponder()
    } else if textField == suiteField {
      cityField.becomeFirstResponder()
    } else if textField == cityField {
      self.goToStateView()
    }
    
    return true
  }
  
  func goToStateView() {
    performSegueWithIdentifier("goToStateTableView", sender: self)
  }
  
  /* Function to Submit the Form */
  /* ------------------------------------------------------------------------------------------- */
  func submit() {
    self.submitButton.userInteractionEnabled = false
    let alert = UIAlertView()
    alert.title = "Wait!"
    alert.addButtonWithTitle("OK")
    
    // do some error checking
    if self.firstNameField.text == "" {
      alert.message = "Please Add your First Name."
      self.firstNameField.becomeFirstResponder()
      alert.show()
      self.submitButton.userInteractionEnabled = true
      return
    }
    if self.lastNameField.text == "" {
      alert.message = "Please Add your Last Name."
      self.lastNameField.becomeFirstResponder()
      alert.show()
      self.submitButton.userInteractionEnabled = true
      return
    }
    if self.emailField.text == "" {
      alert.message = "Please Add your Email."
      self.emailField.becomeFirstResponder()
      alert.show()
      self.submitButton.userInteractionEnabled = true
      return
    }
    if self.addressField.text == "" {
      alert.message = "Please Add your Address."
      self.addressField.becomeFirstResponder()
      alert.show()
      self.submitButton.userInteractionEnabled = true
      return
    }
    if self.cityField.text == "" {
      alert.message = "Please Enter City."
      self.cityField.becomeFirstResponder()
      alert.show()
      self.submitButton.userInteractionEnabled = true
      return
    }
    if self.selectedState == nil {
      alert.message = "Please Select a State."
      alert.show()
      self.submitButton.userInteractionEnabled = true
      return
    }
    if self.zipcodeField.text == "" {
      alert.message = "Please Enter your Zip Code."
      self.zipcodeField.becomeFirstResponder()
      alert.show()
      self.submitButton.userInteractionEnabled = true
      return
    }
    // Submit text fields with trimmed whitespaces from front/end of string
    self.shippingAddress = AddressModel(
      firstName: self.firstNameField.text,
      lastName: self.lastNameField.text,
      email: self.emailField.text,
      address1: self.addressField.text,
      address2: self.suiteField.text,
      city: self.cityField.text,
      state: self.selectedState!,
      zipcode: self.zipcodeField.text
    )
    uploadShippingInformationToAPI()
  }
    
  func uploadShippingInformationToAPI() {
    let parameters = [
      "first_name":           self.shippingAddress.firstName,
      "last_name":            self.shippingAddress.lastName,
      "email":                self.shippingAddress.email,
      "shipping_address1":    self.shippingAddress.address1,
      "shipping_address2":    self.shippingAddress.address2,
      "shipping_city":        self.shippingAddress.city,
      "shipping_state":       self.shippingAddress.state,
      "shipping_postal_code": self.shippingAddress.zipcode,
      "shipping_country":     self.shippingAddress.country
    ]
    
    var alertMessage: String = ""
    // unwrap user_id
    if let user_id = self.userDatabaseData.user_id {

      Alamofire.request(.PUT, "\(ApiConfig.baseUrl)users/\(user_id)", parameters: parameters)
        .authenticate(user: ApiConfig.user, password: ApiConfig.password)
        .responseJSON{ (request, response, JSON, error) in
          // If we receive any response
          if response != nil {
              // If No Error, append parsed JSON message to Alert Message
              if error == nil {
                  // Save Address Data to Device
                  let ns_data = NSKeyedArchiver.archivedDataWithRootObject(self.shippingAddress)
                  NSUserDefaults.standardUserDefaults().setObject(ns_data, forKey: "shippingAddressData")
                
                  // If user just finished with their camera roll, then make sure all photos were uploaded
                  if self.cameFromCamera{
                    // Go to Uploading View Controller
                    self.performSegueWithIdentifier("showFailureFromShipping", sender: nil)
                    return
                  }
                
                  if self.cameFromMenu{
                    // Go back to menu and dealloc this viewcontroller from memory since we dont need it
                    self.performSegueWithIdentifier("unwindToMenuFromShipping", sender: nil)
                    return
                  }
                
                  // Else allow user to go to payment form
                  self.performSegueWithIdentifier("showCustomPaymentViewController", sender: self)
                  self.submitButton.userInteractionEnabled = true
                  return
              } else { // Else, append error to Alert Message
                  alertMessage = "Received Error From Server: \(error?.localizedDescription)"
              }
          } else { // Else, We didn't receive a response
              alertMessage = "Whoops! Looks like you don't have an internet connection."
          }
          // Display popup Alert
          Alert(title: "Sorry!", message: alertMessage).show()
          self.submitButton.userInteractionEnabled = true
      }
    }
    else {
        self.userDatabaseData.getUserId()
        self.submitButton.userInteractionEnabled = true
    }
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if shippingHeader && segue.identifier == "showCustomPaymentViewController" {
      var viewController = segue.destinationViewController as! CustomPaymentViewController
      viewController.shippingAndBillingHeader = true
    }
    if segue.identifier == "showFailureFromShipping" {
      var viewController = segue.destinationViewController as! UploadingViewController
      viewController.cameFromCamera = true
    }
  }

  @IBAction func skipShippingForm(sender: AnyObject) {
    self.performSegueWithIdentifier("showCustomPaymentViewController", sender: self)
  }
    
    
  @IBAction func cancel() {
    self.performSegueWithIdentifier("segueToHomeFromShipping", sender: nil)
  }
  
  /* Function to check for Existing AddressModel Object stored on Phone */
  /* ------------------------------------------------------------------------------------------- */
  func checkForExistingAddress() -> AddressModel! {
    if let addressSavedOnPhone = NSUserDefaults.standardUserDefaults().objectForKey("shippingAddressData") as? NSData {
      // Unarchive data to Array
      return NSKeyedUnarchiver.unarchiveObjectWithData(addressSavedOnPhone) as! AddressModel?
    } else {
      return nil
    }
  }
  
  /* Function for other View Controllers to unwind to this ViewController. The IBAction is created for storyboard purposes */
  /* ------------------------------------------------------------------------------------------- */
  @IBAction func unwindToShippingForm(segue: UIStoryboardSegue) {}
  
  override func shouldAutorotate() -> Bool {
    return false
  }
  
}