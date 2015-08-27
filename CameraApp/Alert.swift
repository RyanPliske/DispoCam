import UIKit

struct Alert {
  let title: String
  let message: String
  
  init(title: String, message: String) {
    self.title = title
    self.message = message
  }
  
  func show() {
    let alert = UIAlertView()
    alert.title = title
    alert.message = message
    alert.addButtonWithTitle("OK")
    alert.show()
  }
}