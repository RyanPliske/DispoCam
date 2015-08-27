// Subclass of UIButton that is styled just how we want it
import UIKit

class SelectButton: UIButton {
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    self.layer.cornerRadius = 4.0
    self.backgroundColor = UIColor.whiteColor()
    
    styleText()
    
    addDownCaretImageOnTheRightSideOfTheButton()
  }
  
  func styleText() {
    self.setTitle(self.currentTitle?.uppercaseString, forState: .Normal)
    self.tintColor = ColorScheme.blue
    
    if let label = self.titleLabel {
      label.textColor = ColorScheme.blue
      label.font = UIFont(name: "DIN-Bold", size: 15.0)
    }
  }
  
  // Adds the ▼ to the right side of the button
  func addDownCaretImageOnTheRightSideOfTheButton() {
    let downCaret = UIImage(named: "down-caret")
    self.setImage(downCaret, forState: .Normal)
    if let image = downCaret {
      self.titleEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, image.size.width)
      self.imageEdgeInsets = UIEdgeInsetsMake(0.0, self.frame.size.width - (image.size.width + 16.0), 0.0, 0.0)
    }
  }
}