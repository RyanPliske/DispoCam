import Foundation

struct AvailableDate {
  static var thisMonth: Int {
    return NSCalendar.currentCalendar().component(NSCalendarUnit.CalendarUnitMonth, fromDate: NSDate())
  }
  
  static var thisYear: Int {
    return NSCalendar.currentCalendar().component(NSCalendarUnit.CalendarUnitYear, fromDate: NSDate())
  }
  
  static let months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ]
  
  static var years: [Int] {
    let manyYearsFromNow = thisYear + 30
    
    return (thisYear...manyYearsFromNow).map { $0 }
  }
}

class ExpirationDate: Printable {
  // Intended to be an index of availableMonths
  var month: Int
  
  // Intended to be an index of availableYears
  var year: Int

  init(month: String, year: Int) {
    if let monthIndex = find(AvailableDate.months, month) {
      self.month = monthIndex
    } else {
      self.month = 0
    }
    if let yearIndex = find(AvailableDate.years, year){
      self.year = yearIndex
    }
    else {
      self.year = 0
    }
  }
  
  var monthInTwoDigits: String {
    return String(format: "%02d", month + 1)
  }
  
  var yearInTwoDigits: String {
    let yearString = "\(AvailableDate.years[year])"
    return yearString[advance(yearString.startIndex, 2) ..< yearString.endIndex]
  }
  
  var description: String {
    if !monthInTwoDigits.isEmpty && !yearInTwoDigits.isEmpty {
      return "\(monthInTwoDigits)/\(yearInTwoDigits)"
    } else {
      return ""
    }
  }
}
