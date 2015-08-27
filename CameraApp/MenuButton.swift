// Subclass of UIButton that is styled just how we want it
import UIKit

class MenuButton: UIButton {
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    self.backgroundColor = UIColor.whiteColor()
    
    styleText()
  }
  
  func styleText() {
    self.setTitle(self.currentTitle?.uppercaseString, forState: .Normal)
    self.tintColor = ColorScheme.blue
    
    if let label = self.titleLabel {
      label.textColor = ColorScheme.blue
      label.font = UIFont(name: "DIN-Bold", size: 21.0)
      label.textAlignment = .Center
    }
  }
}