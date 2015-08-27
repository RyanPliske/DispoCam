// Subclass of UILabel with font and color set to look like a heading.
import UIKit

class HeadingLabel: UILabel {
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.textColor = ColorScheme.blue
    self.font = UIFont(name: "DIN-Bold", size: 30.0)
    self.textAlignment = .Center
    
    // Ensure that label allows for arbitrary height content.
    self.numberOfLines = 0
  }
}