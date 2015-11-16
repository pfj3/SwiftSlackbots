//
//  Slackbot.swift
//  SwiftSlackbots
//
//  Created by Peter Johnson
//  See readme at https://github.com/pfj3/SwiftSlackbots
//

import Foundation

class Slackbot {
    
    //MARK: - User accessible attributes
    
    var slackWebhookURL: String {
        //The webhook URL is immediately converted to NSURL as soon as it is set. This allows an error to be thrown long before an attempt is made at transmitting data
        didSet {
            if let coercedURL = NSURL(string: slackWebhookURL) {
                slackWebhookURLasNSURL = coercedURL
            } else {
                fatalError("The webhook URL is not a valid URL")
            }
        }
    }
    private var slackWebhookURLasNSURL: NSURL //Automatically populated when slackWebhookURL is set
    
    var botname: String?
    var icon: String?
    var channel: String?
    var markdown: Bool = true
    
    
    
    //MARK: - Inits
    
    /*
    There are two ways to deliver your webhook URL to Slackbot. One, by placing it in the line below, which will
    cause every Slackbot instance to have the same webhook URL. Or two, by initializing each Slackbot with the
    webhook URL, like this:
    var webhookbot = Slackbot(url: "someURLinStringForm")
    */
    
    init(url: String) {
        self.slackWebhookURL = url
        
        if let coercedURL = NSURL(string: url) {
            slackWebhookURLasNSURL = coercedURL
        } else {
            fatalError("The webhook URL is not a valid URL")
        }
    }
    
    convenience init() {
        self.init(url: "https://hooks.slack.com/services/YOUR_WEBHOOK_URL")
    }
    
    init(url: NSURL) {
        self.slackWebhookURLasNSURL = url
        self.slackWebhookURL = "\(url)"        
    }
    
    
    
    //MARK: - Message sending public functions
    
    func sendMessage(message message: String, channel: String? = nil) {
        sendRichTextMessage(text: message, channel: channel)
    }
    
    func sendRichTextMessage(fallback: String? = nil, pretext: String? = nil, text: String? = nil, color: String? = nil, title: String? = nil, value: String? = nil, short: Bool? = false, channel: String? = nil) {
        
        sendSideBySideMessage(fallback, pretext: pretext, text: text, color: color, fields: [slackFields(title: title, value: value, short: short)], channel: channel)
    }
    
    func sendSideBySideMessage(fallback: String? = nil, pretext: String? = nil, text: String? = nil, color: String? = nil, fields:[slackFields]?, channel: String? = nil) {
        //If user passes nil to every field, this function will crash the app at the assert command, below.
        
        //Initialize the three arrays to be used
        var slackJsonElements  = [String:AnyObject]()
        var slackJsonAttachments  = [String:AnyObject]()
        var slackJsonFields = [[String:String]]()
        
        
        //Elements: username, icon, channel, text
        if botname != nil {
            slackJsonElements["username"] = botname!
        }
        
        if channel != nil {
            slackJsonElements["channel"] = channel!
        } else if self.channel != nil {
            slackJsonElements["channel"] = self.channel!
        }
        
        if icon != nil {
            if let emojiRange = icon!.rangeOfString(":[a-z_0-9-+]+:", options: .RegularExpressionSearch) {
                slackJsonElements["icon_emoji"] = icon!.substringWithRange(emojiRange)
            } else {
                slackJsonElements["icon_url"] = icon!
            }
        }
        
        if text != nil {
            slackJsonElements["text"] = text!
        }
        
        
        //Markdown
        if markdown {
            slackJsonElements["mrkdwn"] = markdown.description
            slackJsonAttachments["mrkdwn_in"] = ["fallback","pretext", "fields"]
        }
        
        
        //Attachments: fallback, pretext, color
        if fallback != nil {
            slackJsonAttachments["fallback"] = fallback
            slackJsonAttachments["pretext"] = pretext ?? fallback
        } else if pretext != nil {
            slackJsonAttachments["pretext"] = pretext
            slackJsonAttachments["fallback"] = pretext
        }
        
        if color != nil {
            slackJsonAttachments["color"] = color!
        }
        
        
        //Fields: title, value, short
        if fields != nil {
            for element in fields! {
                var dict = [String: String]()
                
                if let t = element.title {
                    dict["title"] = t
                }
                if let v = element.value {
                    dict["value"] = v
                }
                if let s = element.short?.description {
                    dict["short"] = s
                }
                
                slackJsonFields.append(dict)
            }
        }
        
        
        //Add Fields array into the Attachments array, and then add the Attachments array into the Elements array
        if !slackJsonFields.isEmpty {
            slackJsonAttachments["fields"] = slackJsonFields
        }
        if !slackJsonAttachments.isEmpty {
            slackJsonElements["attachments"] = [slackJsonAttachments]
        }
        
        
        
        //If user has passed nil to every field, crash.
        assert(slackJsonElements.isEmpty == false, "ERROR: No information to transmit")       
        
        //Create the JSON payload
        let payloadData = try? NSJSONSerialization.dataWithJSONObject(slackJsonElements, options: NSJSONWritingOptions.PrettyPrinted)
        
        //Transmit JSON payload
        httpJsonPost(url: self.slackWebhookURLasNSURL, jsonPayload: payloadData!, completion: { (let error, let data, let response) in
            if (error != nil) {
                //print(error)
            }
            if (data != nil) {
                //print(NSString(data: data!, encoding: NSUTF8StringEncoding) as! String)
            }
        })
    }
    
    
    
    //MARK: - Private HTTP Function
    
    private func httpJsonPost(url url: NSURL, jsonPayload: NSData, completion: ((NSError?, NSData?, NSURLResponse?) -> Void)) -> Void {
        
        let cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        let request = NSMutableURLRequest(URL: url, cachePolicy: cachePolicy, timeoutInterval: 10.0)
        request.HTTPMethod = "POST"
        request.HTTPBody = jsonPayload
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) { (let data, let response, let error) in
            completion(error, data, response)
            return
        }
        task.resume()
    }
}


//MARK: - Slack Fields Struct

struct slackFields {
    var title: String?
    var value: String?
    var short: Bool?
    
    init(title t:String?, value v: String?, short s:Bool?) {
        title = t
        value = v
        short = s
    }
}
