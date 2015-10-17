//
//  ViewController.swift
//  SwiftSlackbots
//
//  Created by Peter Johnson on 5/13/15.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    
    @IBAction func sendToSlack() {
        
        let webhookbot = Slackbot(url: "https://hooks.slack.com/services/INITIALIZE_WITH_YOUR_WEBHOOK_URL")
        
        if let msg = textField.text {
            webhookbot.sendMessage(message: msg)
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

