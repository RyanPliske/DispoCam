// Subclass of UIButton that is styled just how we want it
import UIKit

class Button: UIButton {
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    self.layer.cornerRadius = 4.0
    self.backgroundColor = ColorScheme.gold
    
    styleText()
  }
  
  func styleText() {
    self.setTitle(self.currentTitle?.uppercaseString, forState: .Normal)
    
    if let label = self.titleLabel {
      label.textColor = UIColor.whiteColor()
      label.font = UIFont(name: "DIN-Bold", size: 27.0)
    }
  }
}