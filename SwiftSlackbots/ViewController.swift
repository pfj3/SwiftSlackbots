//
//  ViewController.swift
//  SwiftSlackbots
//
//  Created by Peter Johnson on 5/13/15.
//  Copyright (c) 2015 Peter Johnson. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    
    
    @IBAction func sendToSlack() {
        let webhookbot = Slackbot()
        
        if let message = textField.text {
            webhookbot.sendMessage(message: message)
        }     
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

