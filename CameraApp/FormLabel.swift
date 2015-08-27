// Subclass of UILabel with font and color set
import UIKit

class FormLabel: UILabel {
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.textColor = ColorScheme.blue
    self.font = UIFont(name: "DIN-BlackAlternate", size: 14.0)
    self.text = self.text?.uppercaseString
  }
}