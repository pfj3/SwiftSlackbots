//
//  Slackbot.swift
//  SwiftSlackbots
//
//  Created by Peter Johnson on 5/11/15.
//

import Foundation

class Slackbot {
    
    //MARK: - User accessible attributes
    
    var botname: String?
    var icon: String?
    var channel: String?
    var slackWebhookUrl = "https://hooks.slack.com/services/YOUR_WEBHOOK_URL"
    
    var markdown: Bool?
    
    //MARK: - Privately accessible constants
    
    private struct Constants {
        static let asynchBackgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0) // prefetching, cleaning up a database, etc.
        static let asynchUserInitiatedQueue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0) // high priority, might take time, but user really needs it now
        static let asynchUtilityQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0) // user didn't ask, but just need to do in background, something that matters right now, so it'd be nice if it returned soon
        static let dispatchMainQueue = dispatch_get_main_queue()
    }
    
    //MARK: - Message sending public functions
    
    func sendMessage(message message: String) {
        sendMessage(message: message, channel: nil)
    }
    
    func sendMessage(message message: String, channel: String?) {
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
        
        if markdown != nil {
            slackJsonElements["mrkdwn"] = markdown?.description
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
        
        //Transmit JSON payload off the main queue
        dispatch_async(Constants.asynchUtilityQueue) {
            self.httpJsonPost(url: slackWebhookUrl, jsonPayload: payloadData!)
        }
    }
    
    
    //MARK: - Private HTTP Function
    
    private func httpJsonPost(url url: String, jsonPayload: NSData) -> Bool {
        //Credit to rakeshbs for the basis of this function
        //http://stackoverflow.com/questions/28270560/call-slack-webincoming-hook-in-swift-but-get-interrupted-reason-exc-bad-instr
        var success = false
        
        if let readableJson = NSString(data: jsonPayload, encoding: NSUTF8StringEncoding) {
            print("Attempting to send json: \(readableJson) to \(url)")
        }
        
        let cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        if let url = NSURL(string: url)
        {
            let request = NSMutableURLRequest(URL: url, cachePolicy: cachePolicy, timeoutInterval: 10.0)
            
            request.HTTPMethod = "POST"
            request.HTTPBody = jsonPayload
            
            var error : NSError? = nil
            do {
                let data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: nil)
                let results = NSString(data:data, encoding:NSUTF8StringEncoding)
                print("JSON Results: \(results!)")
                success = true
            } catch let error1 as NSError {
                error = error1
                print("Data Invalid")
                print(error)
                success = false
            }
        }
        else {
            print("URL Invalid")
            success = false
        }
        return success
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
