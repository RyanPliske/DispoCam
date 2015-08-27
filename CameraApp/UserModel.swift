//
//  UserModel.swift
//  photojojo
//
//  Created by Adam Bowen on 1/23/15.
//  Copyright (c) 2015 Ochre. All rights reserved.
//
import UIKit
import Crashlytics

class UserModel {
  var user_id : Int?{
    didSet{
      if let id = user_id {
        self.updateUserInfoOnDevice("user_id", value: id)
        let errorWithSavingUser = Locksmith.saveData(["userID": "\(id)"], forUserAccount: "photojojoUserAccount2")
      }
    }
  }
  var username : String? {
    didSet {
      if let name = username {
        self.updateUserInfoOnDevice("username", value: name)
        let errorWithSavingUser = Locksmith.saveData(["username": "\(name)"], forUserAccount: "photojojoUserAccount2")
      }
    }
  }
  
  var apiHandler : ApiHandlerModel
  
  init(apiHandler: ApiHandlerModel) {
    self.apiHandler = apiHandler
  }
  
  func createNewUser(completion: (NSError?)->()) {
    println("Attempting to create New User in PhotoJoJo Db...")
    // Set the parameters to send (all fields are required)
    let params = [
      "username" : UIDevice.currentDevice().identifierForVendor.UUIDString,
      "password" : "",
      "apple_id" : "",
      "phone_id" : "",
      "stripe_charge_id" : "",
      "stripe_card_id" : "",
      "email" : "",
      "first_name": "",
      "last_name" : "",
      "shipping_address1" : "",
      "shipping_address2" : "",
      "shipping_city" : "",
      "shipping_state" : "",
      "shipping_postal_code" : "",
      "shippping_country" : "USA",
      "billing_address1" : "",
      "billing_address2" : "",
      "billing_city" : "",
      "billing_state" : "",
      "billing_postal_code" : "",
      "billing_country" : ""
    ]
    
    apiHandler.postReal("users", parameters: params)
    { (request : NSURLRequest?, response : NSHTTPURLResponse?, json: AnyObject?, networkError : NSError?) in
      if let data = json as? NSDictionary
      {
        let error = data.objectForKey("error") as! Bool
        let message = data.objectForKey("message") as! String
        if error
        {
          // println(message)
          if message.rangeOfString("Duplicate entry") != nil{
            println("User Exists in database, setting current UUID {\(UIDevice.currentDevice().identifierForVendor.UUIDString)} as username in User Defaults")
            self.username = UIDevice.currentDevice().identifierForVendor.UUIDString
            completion(nil)
            return
          }
        }
        if let id = data.objectForKey("id") as? Int
        {
            self.user_id = id
            self.username = UIDevice.currentDevice().identifierForVendor.UUIDString
            CLSLogv("User successfully created. ID: %d Username: %@", getVaList([id, self.username!]))
            NSLog("User successfully created. ID: \(id) Username : \(self.username!)")
            println("Destroying existing data")
            // Delete current data from keychain
            println(Locksmith.deleteDataForUserAccount("photojojoUserAccount2"))
            // Save new data to keychain
            let errorWithSavingUser = Locksmith.saveData(["userID": "\(id)", "username": "\(UIDevice.currentDevice().identifierForVendor.UUIDString)"], forUserAccount: "photojojoUserAccount2")
            completion(nil)
            return
        }
      }
      if networkError != nil {
          completion(networkError)
      }
    }
  }
  
  func getUsername() {
    if self.username == nil {
      if let id = self.user_id {
        CLSLogv("User Does not have a username. Attempting to get username with User Id: %d", getVaList([id]))
        println("User does not have a username. Attempting to get one with User Id: \(id)")
        self.apiHandler.GET("users/\(id)", parameters: nil) { jsonResponse in
            if let
                json = jsonResponse,
                user = json.objectForKey("user") as? NSDictionary,
                username = user.objectForKey("username") as? String {
                    self.username = username
            }
        }
      }
    }
  }
    
  func getUserId() {
    if self.user_id == nil {
      if let username = self.username {
        CLSLogv("User Does not have a user id. Attempting to get user id with User name: %d", getVaList([username]))
        println("User does not have a user id. Attempting to get one with User name: \(username)")
        self.apiHandler.GET("users/find-by-username/\(username)", parameters: nil) { jsonResponse in
            if let
                json = jsonResponse,
                user = json.objectForKey("user") as? NSDictionary,
                userID = user.objectForKey("id") as? Int {
                    self.user_id = userID
            }
        }
      }
    }
  }
    
    func updateUserInfoOnDevice(key : String, value : AnyObject){
        println("Saved \(key) to phone")
        let objectToSave = NSKeyedArchiver.archivedDataWithRootObject(value)
        NSUserDefaults.standardUserDefaults().setObject(objectToSave, forKey: key)
    }
  
}