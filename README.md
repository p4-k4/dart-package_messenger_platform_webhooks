# messenger_platform_webhook

This package provides a set of classes to handle webhook events from the Facebook (Meta) Messenger Platform. It allows you to parse, identify, and work with different types of events such as messages, postbacks, deliveries, reactions, and more.

## Features

- Parse and verify Messenger webhook events
- Identify various event types like messages, postbacks, reactions, etc.
- Handle multiple message types such as text, quick replies, attachments, and more
- Support for Messenger-specific features like account linking, handover protocol, and policy enforcement

## Installation

Add the following to your `pubspec.yaml`:

``` yaml
dependencies:
  messenger_webhook_package: latest_version

```

Install it via `flutter pub get` or `dart pub get`.

## Usage

### Verifying Webhook Token

You can use the `WebhookEvent.verifyToken` method to handle the webhook token verification step from Messenger:

```dart
String? verifyResult = WebhookEvent.verifyToken(
  token: 'received_token',
  verifyToken: 'your_verify_token',
  challenge: 'challenge_string',
);

if (verifyResult != null) {
  print('Token verified successfully: $verifyResult');
} else {
  print('Token verification failed');
}
```

### Parsing Webhook Events

You can create a `WebhookEvent` from the JSON payload sent by Messenger:

```dart
final Map<String, dynamic> jsonPayload = {};
final WebhookEvent event = WebhookEvent.fromJson(jsonPayload);
```

### Identifying Event Types

After parsing the event, you can use the `identifyEvent` method to determine what kind of event occurred:

```dart
Event identifiedEvent = WebhookEvent.identifyEvent(event);

if (identifiedEvent is MessageEvent) {
  print('Received a message: ${identifiedEvent.message.text}');
} else if (identifiedEvent is PostbackEvent) {
  print('Received a postback: ${identifiedEvent.postback.payload}');
} else {
  print('Unknown event type');
}
```

### Handling Message Types

You can also identify the type of message received, such as text, quick replies, attachments, etc.:

```dart
MessageType messageType = WebhookEvent.identifyMessageType(event.entry[0].messaging[0].message);

if (messageType is TextMessage) {
  print('Received text: ${messageType.text}');
} else if (messageType is QuickReplyMessage) {
  print('Received quick reply with payload: ${messageType.quickReply.payload}');
}
```

### Supported Events

The package supports the following event types:
- `MessageEvent`
- `PostbackEvent`
- `DeliveryEvent`
- `ReactionEvent`
- `EchoEvent`
- `PolicyEnforcementEvent`
- `PassThreadControlEvent`
- `TakeThreadControlEvent`
- `RequestThreadControlEvent`
- `ReferralEvent`
- `OptinEvent`
- `MessageEditEvent`
- And more...

For unknown or unsupported event types, the `UnknownEvent` class is used.

## Contributions

Contributions are welcome! Feel free to submit a PR or open an issue for any bugs, features, or improvements.

## License

This package is licensed under the MIT License.

## Author
Paurini Taketakehikuroa Wiringi
