// Subclass of UITextField that has padding and cannot be cleared
import UIKit

class TextFieldWithoutClearing: UITextField {
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.layer.cornerRadius = 4.0
    self.textColor = ColorScheme.blue
    self.font = UIFont(name: "DIN-BlackAlternate", size: 15.0)
    self.tintColor = ColorScheme.blue
    self.clearButtonMode = UITextFieldViewMode.Never
  }
  
  // Text fields should have 16px of padding on the sides
  override func textRectForBounds(bounds: CGRect) -> CGRect {
    return CGRectInset(bounds, 16, 0)
  }
  
  override func editingRectForBounds(bounds: CGRect) -> CGRect {
    return self.textRectForBounds(bounds)
  }
}
