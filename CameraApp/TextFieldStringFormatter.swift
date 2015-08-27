// Struct for formatting strings in text fields, while preserving cursor position
struct TextFieldStringFormatter {
  // Returns a string with all non-digit characters stripped out.
  // Also takes the current cursor position,
  // and keeps track of the position as the string is mutated,
  // so the cursor can be placed into a logical position once
  // mutation is complete.
  static func getDigitsFromString(string: String, position: Int) -> (String, Int) {
    var stringWithOnlyDigits = ""
    var newPosition = position
    for (index, character) in enumerate(string) {
      if let digit = "\(character)".toInt() {
        stringWithOnlyDigits.append(character)
      } else if index < position {
        // Non-digit characters that occur before the current cursor position
        // will require us to reposition the cursor.
        newPosition--
      }
    }
    return (stringWithOnlyDigits, newPosition)
  }
  
  // Returns the new position a cursor should be,
  // assuming the given cursor corresponds to 
  // a version of the given string
  // that has no spaces
  static func findPositionInSpacedString(string: String, position: Int) -> Int {
    var newPosition = position
    var spacesSoFar = 0
    for (index, character) in enumerate(string) {
      if character == " " {
        spacesSoFar++
        if index < position + spacesSoFar {
          newPosition++
        }
      }
    }
    return newPosition
  }
}