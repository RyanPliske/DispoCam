//
//  WebViewController.swift
//  photojojo
//
//  Created by Ryan Pliske on 3/1/15.
//  Copyright (c) 2015 Ochre. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate {

    var urlString : String!
    var goForwardButton : UIBarButtonItem!
    var goBackButton : UIBarButtonItem!
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
      super.viewDidLoad()
      self.webView.delegate = self
      
      self.goForwardButton = UIBarButtonItem( title: "  >  ", style: UIBarButtonItemStyle.Bordered, target: self, action: Selector("goForward") )
      self.goBackButton = UIBarButtonItem( title: "<  ", style: UIBarButtonItemStyle.Bordered, target: self, action: Selector("goBack") )
      
      self.goBackButton.enabled = false
      self.goForwardButton.enabled = false
      // self.navigationController?.navigationBar.barTintColor = UIColor.ht_jayColor()
      
      // Display Store
      var url = NSURL(string: self.urlString)
      var requestObj : NSURLRequest = NSURLRequest(URL: url!)
      self.webView.loadRequest(requestObj)
    }
  
    override func viewWillAppear(animated: Bool) {
      self.navigationController?.navigationBarHidden = false
      self.navigationController?.navigationBar.topItem?.setRightBarButtonItems([self.goForwardButton, self.goBackButton], animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
  
    func webViewDidStartLoad(webView: UIWebView) {
      println("loading web page")
      if self.webView.canGoBack
      {
        self.goBackButton.enabled = true
      }
      else
      {
        self.goBackButton.enabled = false
      }
      if self.webView.canGoForward
      {
        self.goForwardButton.enabled = true
      }
      else
      {
        self.goForwardButton.enabled = false
      }
    }
    
    func goBack(){
      self.webView.goBack()
    }
    
    func goForward(){
      self.webView.goForward()
    }
}
