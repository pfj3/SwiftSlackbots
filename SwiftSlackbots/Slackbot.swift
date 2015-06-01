//
//  Slackbot.swift
//  SwiftSlackbots
//
//  Created by Peter Johnson on 5/11/15.
//


/*
//To implement the class create a new object of type Slackbot:

var webhookbot = Slackbot()



//The webhook URL can be set as an attribute of the bot, or set by default value, specified in the Slackbot class.

webhookbot.slackWebhookUrl = "https://hooks.slack.com/services/Your_webhook_address"



//This class can send simple messages:

webhookbot.sendMessage(message: "This is a line of text in a channel.\nAnd this is another line of text.")



//And also messages with links, detailed in Slack's documentation

webhookbot.sendMessage(message: "A very important thing has occurred! <https://alert-system.com/alerts/1234|Click here> for details!")



//Attributes such as the bot's name and icon can be set by the user, and the channel can be set in advance of sending a message. The channel may be overridden by specifying a channel parameter in a call to one of the send message function

webhookbot.botname = "webhookbot"
webhookbot.icon = ":ghost:"
webhookbot.channel = "#test"
webhookbot.sendMessage(message: "This is posted to #test and comes from a bot named webhookbot.")

//The icon can be an emoji from http://emoji-cheat-sheet.com or it can be the URL of an image. If the icon string does not match the pattern of an emoji (i.e. :iphone:) then it is assumed to be a URL.

webhookbot.icon = "https://slack.com/img/icons/app-57.png"


//This class can also send more richly formatted messages:

webhookbot.sendRichTextMessage(
fallback: "New open task [Urgent]: <http://url_to_task|Test out Slack message attachments>",
pretext: "New open task [Urgent]: <http://url_to_task|Test out Slack message attachments>",
text: nil,
color: "#D00000",
title: "Notes",
value: "This is much easier than I thought it would be.",
short: false,
channel: nil)


//Unneeded fields may be specified as "nil" or ignored entirely; they each default to nil
//Slacks documentation describes the fields for a rich message as follows:

// "fallback": "Required text summary of the attachment that is shown by clients that understand attachments but choose not to show them."
// "text": "Optional text that should appear within the attachment"
// "pretext": "Optional text that should appear above the formatted data"
// "color": "#36a64f", // Can either be one of 'good', 'warning', 'danger', or any hex color code

// Fields are displayed in a table on the message
// "fields":
// "title": "Required Field Title", // The title may not contain markup and will be escaped for you
// "value": "Text value of the field. May contain standard message markup and must be escaped as normal. May be multi-line.",
// "short": false // Optional flag indicating whether the `value` is short enough to be displayed side-by-side with other values
*/


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
    
    func sendMessage(#message: String) {
        sendMessage(message: message, channel: nil)
    }
    
    func sendMessage(#message: String, channel: String?) {
        sendRichTextMessage(text: message, channel: channel)
    }
    
    func sendRichTextMessage(fallback: String? = nil, pretext: String? = nil, text: String? = nil, color: String? = nil, title: String? = nil, value: String? = nil, short: Bool? = false, channel: String? = nil) {
        
        sendSideBySideMessage(fallback: fallback, pretext: pretext, text: text, color: color, fields: [slackFields(title: title, value: value, short: short)], channel: channel)
    }
    
    //MARK: - Experimental
    
    func sendSideBySideMessage(fallback: String? = nil, pretext: String? = nil, text: String? = nil, color: String? = nil, fields:[slackFields]?, channel: String? = nil) {
        
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
        //        var slackJsonFieldsArray = [[String:String]]()
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
        
        //If user passes nil to every field, crash.
        assert(slackJsonElements.isEmpty == false, "ERROR: No information to transmit")
        
        //Create the JSON payload
        let payloadData = NSJSONSerialization.dataWithJSONObject(slackJsonElements, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
        
        //Transmit JSON payload off the main queue
        dispatch_async(Constants.asynchUtilityQueue) {
            self.httpJsonPost(url: slackWebhookUrl, jsonPayload: payloadData!)
        }
    }
    
    
    //MARK: - Private HTTP Function
    
    private func httpJsonPost(#url: String, jsonPayload: NSData) -> Bool {
        //Credit to rakeshbs for the basis of this function
        //http://stackoverflow.com/questions/28270560/call-slack-webincoming-hook-in-swift-but-get-interrupted-reason-exc-bad-instr
        var success = false
        
        if let readableJson = NSString(data: jsonPayload, encoding: NSUTF8StringEncoding) {
            println("Attempting to send json: \(readableJson) to \(url)")
        }
        
        let cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        
        if let url = NSURL(string: url)
        {
            var request = NSMutableURLRequest(URL: url, cachePolicy: cachePolicy, timeoutInterval: 10.0)
            
            request.HTTPMethod = "POST"
            request.HTTPBody = jsonPayload
            
            var error : NSError? = nil
            if let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: nil, error: &error) {
                let results = NSString(data:data, encoding:NSUTF8StringEncoding)
                println("JSON Results: \(results!)")
                success = true
            }
            else
            {
                println("Data Invalid")
                println(error)
                success = false
            }
        }
        else {
            println("URL Invalid")
            success = false
        }
        return success
    }
}

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
