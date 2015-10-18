//
//  ViewController.swift
//  SwiftSlackbots
//
//  Created by Peter Johnson
//  https://github.com/pfj3/SwiftSlackbots
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    
    @IBAction func sendToSlack() {
        
        let webhookbot = Slackbot(url: "https://hooks.slack.com/services/YOUR_WEBHOOK_URL")
        
        webhookbot.channel = "#test"
        
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

