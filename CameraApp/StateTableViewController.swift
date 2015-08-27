//
//  StateTableViewController.swift
//  photojojo
//
//  Created by Adam Bowen on 1/20/15.
//  Copyright (c) 2015 Ochre. All rights reserved.
//

import UIKit

class StateTableViewController: UITableViewController {
  let states = StateListModel().names
  var selectedState: String?
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.states.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("state", forIndexPath: indexPath) as! UITableViewCell
    cell.textLabel!.text = states[indexPath.row]
    return cell
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    self.selectedState = states[indexPath.row]
    performSegueWithIdentifier("unwindToShippingForm", sender: self)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "unwindToShippingForm" {
      var viewController = segue.destinationViewController as! ShippingFormViewController
      viewController.selectedState = self.selectedState
    }
  }
  
  override func shouldAutorotate() -> Bool {
    return false
  }
}
