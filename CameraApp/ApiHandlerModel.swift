//
//  ApiHandlerModel.swift
//  photojojo
//
//  Created by Adam Bowen on 1/26/15.
//  Copyright (c) 2015 Ochre. All rights reserved.
//

import Alamofire
import UIKit

class ApiHandlerModel {
  let baseUrl, user, password, userAgent: String

  init(baseUrl: String, user: String, password: String) {
    self.baseUrl  = baseUrl
    self.user     = user
    self.password = password
    self.userAgent = "DispoCam v" + AppVersionConfig.appVersion
  }
  
  func GET(route: String, parameters: [String: AnyObject]?, completion: (NSDictionary?) -> ()) {
    request(Alamofire.Method.GET, route: route, parameters: parameters, completion: completion)
  }
  
  func POST(route: String, parameters: [String: AnyObject]?, completion: (NSDictionary?) -> ()) {
    request(Alamofire.Method.POST, route: route, parameters: parameters, completion: completion)
  }
  
  func PUT(route: String, parameters: [String: AnyObject]?, completion: (NSDictionary?) -> ()) {
    request(Alamofire.Method.PUT, route: route, parameters: parameters, completion: completion)
  }
  
  private func request(method: Alamofire.Method, route: String, parameters: [String: AnyObject]?, completion: (NSDictionary?) -> ()) {
    Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders = ["User-Agent" : self.userAgent]
    Alamofire.request(method, self.baseUrl + route, parameters: parameters)
      .authenticate(user: user, password: password).responseJSON { (_, serverResponse, serverJson, serverError) in
      if let response = serverResponse {
        if let error = serverError {
          println("There was an error making the request: \(error)")
          completion(nil)
        } else {
          if let json = serverJson as? NSDictionary {
            completion(json)
          } else {
            println("Could not parse the server's JSON as NSDictionary")
            completion(nil)
          }
        }
      } else {
        println("The server did not respond")
        completion(nil)
      }
    }
  }
  
  // GET
  // Deprecated in v1.1.0
  @availability(*, deprecated=1.1.0) func get(route: String, parameters: [String:AnyObject]?) {
    var failMessage = ""
    Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders = ["User-Agent" : self.userAgent]
    Alamofire.request(.GET, self.baseUrl + route, parameters: parameters)
      .authenticate(user: user, password: password)
      .responseJSON { (request, response, data, error) in
      if (response != nil)
      {
        if (error == nil)
        {
          // Unwrap optional
          if let jsonData = data as? NSDictionary {
            // println(jsonData)
            // the following is done for GET requests to coupons
            if parameters == nil {
              let errorBoolean = jsonData.objectForKey("error") as! Bool
              if !errorBoolean {
                if let jsonData2 = jsonData.objectForKey("coupon") as? NSDictionary {
                  let uses_left = jsonData2.objectForKey("uses_left") as! Int
                  let numOfPhotosCouponAppliesTo = jsonData2.objectForKey("photos") as! Int
                  let dollarAmountString = jsonData2.objectForKey("amount") as! NSString
                  let couponCode = jsonData2.objectForKey("code") as! String
                  let dollarAmountFloat = dollarAmountString.floatValue
                  // send alert to BuyNewRollViewcontroller with Coupon Information.
                  var couponDict = ["uses_left" : uses_left,
                    "numOfPhotosCouponAppliesTo" : numOfPhotosCouponAppliesTo,
                    "dollar_amt" : dollarAmountFloat,
                    "coupon_code" : couponCode
                  ]
                  NSNotificationCenter.defaultCenter().postNotificationName("couponSuccess", object: nil, userInfo: couponDict as [NSObject : AnyObject])
                  return
                }
                if let user = jsonData.objectForKey("user") as? NSDictionary {
                  if let username = user.objectForKey("username") as? String {
                    var userDict = ["username" : username]
                    NSNotificationCenter.defaultCenter().postNotificationName("getUsernameSuccessful", object: nil, userInfo: userDict)
                    
                  }
                  if let userID = user.objectForKey("id") as? Int {
                    var userDict = ["user_id" : userID]
                    // println(userDict)
                    NSNotificationCenter.defaultCenter().postNotificationName("getUserIdSuccessful", object: nil, userInfo: userDict)
                    return
                  }
                }
              }
            }
          }
        }
        else
        { // Append error to response
          failMessage = "\(error?.localizedDescription)"
          /*
          /* TODO : If we send the user ID and get an internal server error, We may need to recover from this...
          * perhaps create a new user */
          if response?.statusCode == 500 {
            NSLog("Failed to Find User in Photo jojo Db. User Does Not Exist")
            responseMessage = "User Does Not Exist"
          }
          */
        }
      }
      else
      {
        failMessage = "Whoops! Looks like you don't have an internet connection."
      }
      var responseDict = ["failMessage" : failMessage]
      NSNotificationCenter.defaultCenter().postNotificationName("getResponseFailed", object: nil, userInfo: responseDict)
    }
  }
  
  // POST
  // Purpose: creates POST requests in order to create New User, new camera and new photos within PhotoJOJO Database.
  // Upon Success of:
  //      1. new photo, Logs the success and then ends.
  //      2. new camera, lets cameraViewController it was successful.
  //      3. new user, save user_id to phone.
  // Upon Failure of:
  //      1. new Photo, we need to either try again or save the parameters to attempt the request later.
  //      2. new Camera, we need to either try again or save the parameters to attempt the request later.
  //      3. new User, we need to either try again or save the parameters to attempt the request later.
  @availability(*, deprecated=1.1.0) func post(route: String, parameters: [String:AnyObject]?) {
    Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders = ["User-Agent" : self.userAgent]
    Alamofire.request(.POST, self.baseUrl + route, parameters: parameters)
      .authenticate(user: user, password: password)
      .responseJSON{ (request, response, JSON, error) in
          // If the HTTP Request fails, then the user may have a network issue
          if error == nil {
            // Unwrap otional
            if let jsonData = JSON as? NSDictionary {
              // Grab the data from the JSON
              let JSONerror = jsonData.objectForKey("error") as! Bool
              let jojoMessage = jsonData.objectForKey("message") as! String
              // If Message has no error in it
              if !JSONerror {
                // If creating new camera
                if parameters!["shots"] != nil {
                  let ID = jsonData.objectForKey("id") as! Int
                  NSLog("Successfull created new Camera [\(ID)]in JoJo Db.")
                  // Post response to the Notification Center and send the response message with it.
                  var photoDictionary = ["camera_id" : ID]
                  NSNotificationCenter.defaultCenter().postNotificationName("createdCamera", object: nil, userInfo:photoDictionary)
                } else if parameters!["email"] != nil {
                  // If creating new user
                  // Save User ID to phone
                  let ID = jsonData.objectForKey("id") as! Int
                  NSLog("Successfull created New User in JoJo Db: USER_ID={\(ID)}")
                  let data = NSKeyedArchiver.archivedDataWithRootObject(jsonData.objectForKey("id")!)
                  NSUserDefaults.standardUserDefaults().setObject(data, forKey: "user_id")
                  // send alert to BuyNewRollViewcontroller with User Id.
                  var userDictionary = ["userID" : ID]
                  NSNotificationCenter.defaultCenter().postNotificationName("createUserSuccess", object: nil, userInfo:userDictionary)
                }
                return
              } else {
                // If creating new user
                if parameters!["email"] != nil {
                  // If Duplicate UserName
                  if jojoMessage.rangeOfString("Duplicate entry") != nil{
                    // send alert to viewcontroller to tell the User that the User exists
                    NSNotificationCenter.defaultCenter().postNotificationName("alertUserThatUserExists", object: nil)
                  }
                }
                // If creating new camera
                if parameters!["shots"] != nil{
                  var cameraDictionary = ["failure_message" : jojoMessage]
                  NSNotificationCenter.defaultCenter().postNotificationName("didNotCreateCameraInDatabaseDueToJoJo", object: nil, userInfo:cameraDictionary)
                }
              }
            }
          } else {
            // Else, append error to Alert Message
            NSLog("POST to JoJo Failed: \(error!.localizedDescription)")
            
            // If creating new camera
            if parameters!["shots"] != nil {
              NSNotificationCenter.defaultCenter().postNotificationName("didNotCreateCameraInDatabaseDueToNetworkError", object: nil)
            }
            
            // If creating a new user 
            if parameters!["email"] != nil {
              NSNotificationCenter.defaultCenter().postNotificationName("createUserFailed", object: nil)
            }
            
          }
        } // End Request
  } // End post function
  
  @availability(*, deprecated=1.1.0) func post(route: String, parameters: NSDictionary, completion : (NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> ()) {
    var params : [String: AnyObject]
    // If creating new photo
    if parameters["camera_id"] != nil {
      params = [
        "camera_id" : parameters["camera_id"]!,
        "bucket" : parameters["bucket"]!,
        "file_name" : parameters["file_name"]!,
        "sort_id" : ""
      ]
    } else if parameters["coupon_code"] != nil {
      // Else creating new camera with coupon code
      params = [
        "user_id" : parameters["user_id"]!,
        "shots" : parameters["shots"]!,
        "shots_used" : parameters["shots_used"]!,
        "coupon_code" : parameters["coupon_code"]!
      ]
    } else {
      // Else creating new camera without coupon code
      params = [
        "user_id" : parameters["user_id"]!,
        "shots" : parameters["shots"]!,
        "shots_used" : parameters["shots_used"]!,
        "stripe_token" : parameters["stripe_token"]!
      ]
      
      #if DEBUG
        params["stripe_test_mode"] = "YESPLEASE"
      #endif
    }
    Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders = ["User-Agent" : self.userAgent]
    Alamofire.request(.POST, self.baseUrl + route, parameters: params)
      .authenticate(user: user, password: password)
      .responseJSON { (request, response, json, networkError) in
        completion(request, response, json, networkError)
    }
  }
  
  @availability(*, deprecated=1.1.0) func postReal(route: String, parameters: [String:AnyObject]?, completion: (NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> ()) {
    Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders = ["User-Agent" : self.userAgent]
    Alamofire.request(.POST, self.baseUrl + route, parameters: parameters)
      .authenticate(user: user, password: password)
      .responseJSON { (request, response, json, networkError) in
        completion(request, response, json, networkError)
    }
  }
}
