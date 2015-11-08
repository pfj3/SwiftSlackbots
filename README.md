# SwiftSlackbots
### An implementation of the Slack webhook API for Swift.
http://www.slack.com



To implement the class, create a new Slackbot object and designate the webhook URL at the time of initialization

```swift
var webhookbot = Slackbot(url: "https://hooks.slack.com/services/Your_webhook_address")
```


As an alternative, the webhook URL can be set by changing the ```slackWebhookURL``` attribute of the bot at any time. Or by designating a default value by changing the code in ```init()``` in the Slackbot class.

```swift
var webhookbot = Slackbot()

webhookbot.slackWebhookUrl = "https://hooks.slack.com/services/Your_webhook_address"
```




####Sending Simple Messages

Simple messages can be sent a short line of code, and can include simple markup, like the new line flag.

```swift
webhookbot.sendMessage(message: "This is a line of text in a channel.\nAnd this is another line of text.")
```

You can also send messages with links:

```swift
webhookbot.sendMessage(message: "A very important thing has occurred! <https://alert-system.com/alerts/1234|Click here> for details!")
```

Attributes like the bot's name and icon can be set by the user. The channel can be set in advance of sending a message. Or the channel may be overridden by specifying channel parameter in a call to any of the send message functions.

```swift
webhookbot.botname = "webhookbot"
webhookbot.icon = ":ghost:"
webhookbot.channel = "#test"
webhookbot.sendMessage(message: "This is posted to #test and comes from a bot named webhookbot.")
```


The icon can be an emoji from http://emoji-cheat-sheet.com or it can be the URL of an image. If the icon string does not match the pattern of an emoji (e.g. ```:iphone:```) then it is assumed to be a URL.

```swift
webhookbot.icon = "https://slack.com/img/icons/app-57.png"
```




####Send Richly Formatted Messages

Slack provides for the ability to send more complex messages, which involve a number of parameters.

```swift
webhookbot.sendRichTextMessage(
	fallback: "New open task [Urgent]: <http://url_to_task|Test out Slack message attachments>",
	pretext: "New open task [Urgent]: <http://url_to_task|Test out Slack message attachments>",
	text: nil,
	color: "#D00000",
	title: "Notes",
	value: "This is much easier than I thought it would be.",
	short: false,
	channel: nil)
```

Unneeded fields may be specified as "nil" or ignored entirely; they each default to nil. If all parameters are nil, the app will crash, via an ```assert``` statement

####Send Side by Side Messages

Slack provides for the ability to send "short" messages. In practice, these make sense to me as "side by side" messages. To send messages of this type, the left message and right message must be sent as an array of ```slackFields``` objects

```swift
let webhookbot = Slackbot()
webhookbot.markdown = true
      
let pretext = "*Side by Side Message Incoming* from an app written in Swift"

let fields = [slackFields(title: "Left Column", 
			value: "This text\nis in the left column", 
			short: true), 
		slackFields(title: "Right Column", 
			value: "But this text\nis in the right column", 
			short: true)]

webhookbot.sendSideBySideMessage(fallback: "New Side by Side Message", pretext: pretext, fields: fields)
```

#####Slack's documentation describes the fields for a rich text message as follows:

```
* "fallback": "Required text summary of the attachment that is shown by clients that understand attachments but choose not to show them."
* "text": "Optional text that should appear within the attachment"
* "pretext": "Optional text that should appear above the formatted data"
* "color": "#36a64f", // Can either be one of 'good', 'warning', 'danger', or any hex color code
  
Fields are displayed in a table on the message
* "title": "Required Field Title", // The title may not contain markup and will be escaped for you
* "value": "Text value of the field. May contain standard message markup and must be escaped as normal. May be multi-line.",
* "short": false // Optional flag indicating whether the "value" is short enough to be displayed side-by-side with other values```
