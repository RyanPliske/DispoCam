import UIKit

class AddressModel: NSObject, NSCoding {
  var firstName, lastName, email, address1, address2, city, state, zipcode: String
  
  var country = "United States"
  
  init(
    firstName: String,
    lastName:  String,
    email:     String,
    address1:  String,
    address2:  String,
    city:      String,
    state:     String,
    zipcode:   String
  ) {
    self.firstName = firstName.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
    self.lastName  = lastName.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
    self.email     = email.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
    self.address1  = address1.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
    self.address2  = address2.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
    self.city      = city.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
    self.state     = state.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
    self.zipcode   = zipcode.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
  }
  
  required init(coder aDecoder: NSCoder) {
    // I don't really understand
    // why I have to put this here,
    // instead of within
    // the greater body of the class
    func getStringFromKeyWithCoder(key: String, coder aDecoder: NSCoder) -> String {
      if let string = aDecoder.decodeObjectForKey(key) as? String {
        return string
      } else {
        return ""
      }
    }
    
    self.firstName = getStringFromKeyWithCoder("firstName", coder: aDecoder)
    self.lastName  = getStringFromKeyWithCoder("lastName",  coder: aDecoder)
    self.email     = getStringFromKeyWithCoder("email",     coder: aDecoder)
    self.address1  = getStringFromKeyWithCoder("address1",  coder: aDecoder)
    self.address2  = getStringFromKeyWithCoder("address2",  coder: aDecoder)
    self.city      = getStringFromKeyWithCoder("city",      coder: aDecoder)
    self.state     = getStringFromKeyWithCoder("state",     coder: aDecoder)
    self.zipcode   = getStringFromKeyWithCoder("zipcode",   coder: aDecoder)
    super.init()
  }
  

  
  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(self.firstName, forKey: "firstName")
    aCoder.encodeObject(self.lastName,  forKey: "lastName")
    aCoder.encodeObject(self.email,     forKey: "email")
    aCoder.encodeObject(self.address1,  forKey: "address1")
    aCoder.encodeObject(self.address2,  forKey: "address2")
    aCoder.encodeObject(self.city,      forKey: "city")
    aCoder.encodeObject(self.state,     forKey: "state")
    aCoder.encodeObject(self.zipcode,   forKey: "zipcode")
  }
}