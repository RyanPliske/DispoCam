//
//  CustomPaymentViewController.swift
//  NOTE: This viewcontroller is no longer being used. If PhotoJoJo wants a custom payment screen, 
//  we can look to utilize this one. For now, we're using the one that is included with Stripe's SDK.
//
//  Created by Ryan Pliske on 1/21/15.
//  Copyright (c) 2015 Ochre. All rights reserved.
//


import UIKit

class CustomPaymentViewController : UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {

  var shippingAndBillingHeader = false
  
  @IBOutlet weak var shippingAndBillingHeaderImage: UIImageView!
  @IBOutlet weak var paymentField: TextField!
  @IBOutlet weak var securityCodeField: TextField!
  @IBOutlet weak var monthField: TextField!
  @IBOutlet weak var purchaseButton: Button!
  
  // Make the App Delegate methods available to this view controller
  let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
  var cameraData: CameraModel!
  var userDatabaseData : UserModel!
  let jojoAPIHandler: ApiHandlerModel = ApiHandlerModel(baseUrl: ApiConfig.baseUrl, user: ApiConfig.user, password: ApiConfig.password)
  var expirationDate = ExpirationDate(
    month: AvailableDate.months[AvailableDate.thisMonth - 1],
    year: AvailableDate.years[0]
  )
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.userDatabaseData = appDelegate.getUserInfo()
    var monthPicker = UIPickerView()
    self.monthField.inputView = monthPicker
    monthPicker.dataSource = self
    monthPicker.delegate = self
    monthPicker.selectRow(AvailableDate.thisMonth - 1, inComponent: 0, animated: false)
    monthField.text = expirationDate.description
    
    if shippingAndBillingHeader {
      shippingAndBillingHeaderImage.image = UIImage(named: "shipping-and-billing")
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    self.cameraData = appDelegate.getCameraInfo()
    println("Coupon uses left: \(self.cameraData.couponUsesLeft)   Coupon num OF Photos: \(self.cameraData.couponNumOfPhotos)")
  }
  
  @IBAction func purchaseButtonSubmitted(sender: AnyObject) {
    purchaseButton.userInteractionEnabled = false
    // If user has a current camera prevent user from purchasing new camera
    if let cameraNSData = NSUserDefaults.standardUserDefaults().objectForKey("camera_id") as? NSData {
      // Notify user they already have a current camera
      let alert = UIAlertView()
      alert.title = "Sorry!"
      alert.message = "It appears you already have a camera!."
      alert.addButtonWithTitle("OK")
      alert.show()
      return
    }
    self.grabUsersPaymentInformation()
  }
  
  // Dynamically format the credit card input.
  // Implementation based on http://stackoverflow.com/a/19161529/1709587
  // However, we'll take advantage of PaymentKit to handle the actual
  // credit card formatting.
  func reformatAsCardNumber(textField: TextField) {
    var targetCursorPosition = 0
    var cardNumberWithoutSpaces = ""
    if let selectedTextRange = textField.selectedTextRange {
      targetCursorPosition = textField.offsetFromPosition(textField.beginningOfDocument, toPosition: selectedTextRange.start)
      (cardNumberWithoutSpaces, targetCursorPosition) = TextFieldStringFormatter.getDigitsFromString(textField.text, position: targetCursorPosition)
      
      let paymentKitCardNumber = PTKCardNumber(string: cardNumberWithoutSpaces)
      let formattedCardNumber = paymentKitCardNumber.formattedString()
      
      textField.text = formattedCardNumber
      targetCursorPosition = TextFieldStringFormatter.findPositionInSpacedString(formattedCardNumber, position: targetCursorPosition)
      
      if let position = textField.positionFromPosition(textField.beginningOfDocument, offset: targetCursorPosition) {
        if let range = textField.textRangeFromPosition(position, toPosition: position) {
          textField.selectedTextRange = range
        }
      }
    }
  }
  
  @IBAction func cardNumberChanged(sender: TextField) {
    reformatAsCardNumber(sender)
  }
  
  func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
    return 2
  }
  
  func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    if component == 0 {
      return AvailableDate.months.count
    } else {
      return AvailableDate.years.count
    }
  }
  
  func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
    if component == 0 {
      return String(AvailableDate.months[row] as NSString)
    } else {
      return String("\(AvailableDate.years[row])" as NSString)
    }
  }
  
  func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    if component == 0 {
      expirationDate.month = row
    } else if component == 1 {
      expirationDate.year = row
    }
    println(expirationDate.description)
    self.monthField.text = expirationDate.description
  }
  
  func grabUsersPaymentInformation() {
    // create Token
    let card = STPCard()
    // error check and pass in values to be sent to Stripe
    if self.paymentField.text != "" {
      card.number = self.paymentField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    else { self.paymentField.becomeFirstResponder(); return }
  
    if self.securityCodeField.text != "" {
      card.cvc = self.securityCodeField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    else { self.securityCodeField.becomeFirstResponder(); return }
    
    card.expMonth = UInt(expirationDate.month) + UInt(1)

    card.expYear = UInt(AvailableDate.years[expirationDate.year])

    
    // After everything is checked, send card to Stripe
    STPAPIClient.sharedClient().createTokenWithCard(card, completion: { (token: STPToken!, error: NSError!) -> Void in
      if ((error) != nil)
      {
        if (error.code == 70)
        {
          // Display result in a Pop Up Window
          self.displayAlert(error.localizedDescription)
        }
        else
        {
          self.displayAlert("Sorry. You do not have a connection to the internet. Please try back later.")
        }
        self.purchaseButton.userInteractionEnabled = true
      }
      else
      {
        self.cameraData.createNewCamera(token, userId: self.userDatabaseData.user_id!) { backendError in
          if backendError == nil {
            self.purchaseButton.userInteractionEnabled = true
            self.performSegueWithIdentifier("showUnwrapViewControllerFromPayment", sender: self)
          }
          else {
            self.purchaseButton.userInteractionEnabled = true
            Alert(title: "Sorry!", message: "\(backendError)").show()
          }
        }
      }
    })
    
  }

    
  func displayAlert(alert : String){
    var alert = UIAlertController(title: "Sorry!", message: "\(alert)", preferredStyle: UIAlertControllerStyle.Alert)
    alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel, handler: nil))
    self.presentViewController(alert, animated: true, completion: nil)
  }

  @IBAction func unwindToCustomPayment(segue: UIStoryboardSegue) {}
    
  @IBAction func goBack(sender: AnyObject) {
    self.performSegueWithIdentifier("unwindtoShippingFromPayment", sender: self)
  }
  
  @IBAction func shippingButtonPressed(sender: AnyObject) {
    self.performSegueWithIdentifier("unwindtoShippingFromPayment", sender: self)
  }
  
}
