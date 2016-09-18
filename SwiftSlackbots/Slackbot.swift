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
            if let coercedURL = URL(string: slackWebhookURL) {
                slackWebhookURLasURLType = coercedURL
            } else {
                fatalError("The webhook URL is not a valid URL")
            }
        }
    }
    fileprivate var slackWebhookURLasURLType: URL //Automatically populated when slackWebhookURL is set
    
    var botname: String?
    var icon: String?
    var channel: String?
    var markdown: Bool = true
    
    //MARK: - Inits
    init(url: String) {
        self.slackWebhookURL = url
        
        if let coercedURL = URL(string: url) {
            slackWebhookURLasURLType = coercedURL
        } else {
            fatalError("The webhook URL is not a valid URL")
        }
    }
    
    init(url: URL) {
        self.slackWebhookURL = String(describing: url)
        self.slackWebhookURLasURLType = url
    }
    
    convenience init(url: URL, botname: String? = nil, icon: String? = nil, channel: String? = nil) {
        self.init(url: url)
        self.botname = botname
        self.icon = icon
        self.channel = channel
    }
    
    convenience init(url: String, botname: String? = nil, icon: String? = nil, channel: String? = nil) {
        self.init(url: url)
        self.botname = botname
        self.icon = icon
        self.channel = channel
    }
    
    //MARK: - Message sending public functions
    func sendMessage(message: String, channel: String? = nil) {
        sendRichTextMessage(text: message, channel: channel)
    }
    
    func sendRichTextMessage(fallback: String? = nil, pretext: String? = nil, text: String? = nil, color: String? = nil, title: String? = nil, value: String? = nil, short: Bool? = false, channel: String? = nil) {
        sendSideBySideMessage(fallback: fallback, pretext: pretext, text: text, color: color, fields: [slackFields(title: title, value: value, short: short)], channel: channel)
    }
    
    func sendSideBySideMessage(fallback: String? = nil, pretext: String? = nil, text: String? = nil, color: String? = nil, fields:[slackFields]?, channel: String? = nil) {
        //Initialize the three arrays to be used
        var slackJsonElements  = [String:Any]()
        var slackJsonAttachments  = [String:Any]()
        var slackJsonFields = [[String:String]]()
        
        //Elements: username, icon, channel, text
        if botname != nil {
            slackJsonElements["username"] = botname
        }
        
        if channel != nil {
            slackJsonElements["channel"] = channel
        } else if self.channel != nil {
            slackJsonElements["channel"] = self.channel
        }
        
        if icon != nil {
            if let emojiRange = icon!.range(of: ":[a-z_0-9-+]+:", options: .regularExpression) {
                slackJsonElements["icon_emoji"] = icon!.substring(with: emojiRange)
            } else {
                slackJsonElements["icon_url"] = icon
            }
        }
        
        if text != nil {
            slackJsonElements["text"] = text
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
        
        //If user has passed nil to every field, return
        if (slackJsonElements.isEmpty) {
            return
        }
        
        //Create the JSON payload
        let payloadData = try? JSONSerialization.data(withJSONObject: slackJsonElements, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        //Transmit JSON payload
        httpJsonPost(url: self.slackWebhookURLasURLType, jsonPayload: payloadData!, completion: { (error, data, response) in
            if (error != nil) {
                //print(error)
            }
            if (data != nil) {
                //print(NSString(data: data!, encoding: NSUTF8StringEncoding) as! String)
            }
        })
    }
    
    //MARK: - Private HTTP Function
    fileprivate func httpJsonPost(url: URL, jsonPayload: Data, completion: @escaping ((Error?, Data?, URLResponse?) -> Void)) -> Void {
        
        let cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
        let request = NSMutableURLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.httpBody = jsonPayload
        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            completion(error, data, response)
            return
        }).resume()
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
