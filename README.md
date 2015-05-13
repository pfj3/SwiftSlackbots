# SwiftSlackbots
### An implementation of the Slack webhook API for Swift.
http://www.slack.com



To implement the class, create a new Slackbot object

```swift
var webhookbot = Slackbot()
```


The webhook URL can be set as an attribute of the bot, or set by default value, specified in the Slackbot class.

```swift
webhookbot.slackWebhookUrl = "https://hooks.slack.com/services/Your_webhook_address"
```




#####This class can send simple messages:

```swift
webhookbot.sendMessage(message: "This is a line of text in a channel.\nAnd this is another line of text.")
```

And also messages with links, detailed in Slack's documentation

```swift
webhookbot.sendMessage(message: "A very important thing has occurred! <https://alert-system.com/alerts/1234|Click here> for details!")
```

Attributes such as the bot's name and icon can be set by the user, and the channel can be set in advance. Channel may be overridden by specifying a channel by specifying a channel parameter in call to a send message function

```swift
webhookbot.botname = "webhookbot"
webhookbot.icon = ":ghost:"
webhookbot.channel = "#test"
webhookbot.sendMessage(message: "This is posted to #test and comes from a bot named webhookbot.")
```


The icon can be an emoji from http://emoji-cheat-sheet.com or it can be the URL of an image. If the icon string does not match the pattern of an emoji (i.e. ```:iphone:```) then it is assumed to be a URL.

```swift
webhookbot.icon = "https://slack.com/img/icons/app-57.png"
```




#####This class can also send more richly formatted messages:

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

Unneeded fields may be specified as "nil" or ignored entirely; they each default to nil.

#####Slack's documentation describes the fields for a rich text message as follows:

* "fallback": "Required text summary of the attachment that is shown by clients that understand attachments but choose not to show them."
* "text": "Optional text that should appear within the attachment"
* "pretext": "Optional text that should appear above the formatted data"
* "color": "#36a64f", // Can either be one of 'good', 'warning', 'danger', or any hex color code
  
Fields are displayed in a table on the message
* "title": "Required Field Title", // The title may not contain markup and will be escaped for you
* "value": "Text value of the field. May contain standard message markup and must be escaped as normal. May be multi-line.",
* "short": false // Optional flag indicating whether the "value" is short enough to be displayed side-by-side with other values
