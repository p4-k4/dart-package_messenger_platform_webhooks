// Copyright (c) 2024 [Your Name or Organization]
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/// Represents the root webhook event received from the Messenger Platform.
class WebhookEvent {
  /// The object type, which is typically "page".
  final String object;

  /// The list of entries, each representing a different event that occurred.
  final List<Entry> entry;

  /// Constructor for `WebhookEvent`.
  WebhookEvent({
    required this.object,
    required this.entry,
  });

  /// Verifies the token sent by the Messenger Platform during webhook setup.
  ///
  /// [token] is the token received from the Messenger verification request.
  /// [verifyToken] is a user specified token that will be used to verify [token].
  /// The method compares the provided token with your predefined token.
  ///
  /// Returns a challenge as a response to the webhook callback being called if
  /// the token is successfully verified, otherwise returns null.
  static String? verifyToken({
    required String token,
    required String verifyToken,
    required String challenge,
  }) {
    if (token == verifyToken) {
      return challenge;
    } else {
      return null;
    }
  }

  /// Creates a `WebhookEvent` from a JSON map.
  factory WebhookEvent.fromJson(Map<String, dynamic> json) {
    return WebhookEvent(
      object: json['object'],
      entry: List<Entry>.from(json['entry'].map((e) => Entry.fromJson(e))),
    );
  }

  /// Converts the `WebhookEvent` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'object': object,
      'entry': entry.map((e) => e.toJson()).toList(),
    };
  }

  static Event identifyEvent(WebhookEvent webhookEvent) {
    if (webhookEvent.entry.isEmpty || webhookEvent.entry[0].messaging.isEmpty) {
      // TODO Not the most elegant solution to return this - needs revising.
      return UnknownEvent(
          Messaging(sender: User(id: ''), recipient: User(id: '')));
    }
    var entry = webhookEvent.entry[0];
    var messaging = entry.messaging[0];
    if (messaging.order != null) {
      return SendCartEvent(messaging);
    } else if (messaging.field == 'group_feed') {
      return GroupFeedEvent(messaging);
    } else if (messaging.messagingCustomerInformation != null) {
      return CustomerInformationEvent(messaging);
    } else if (messaging.messageEdit != null) {
      return MessageEditEvent(messaging);
    } else if (messaging.message != null) {
      return MessageEvent(messaging);
    } else if (messaging.accountLinking != null) {
      return AccountLinkingEvent(messaging);
    } else if (messaging.postback != null) {
      return PostbackEvent(messaging);
    } else if (messaging.delivery != null) {
      return DeliveryEvent(messaging);
    } else if (messaging.read != null) {
      return ReadEvent(messaging);
    } else if (messaging.reaction != null) {
      return ReactionEvent(messaging);
    } else if (messaging.echo != null) {
      return EchoEvent(messaging);
    } else if (messaging.gamePlay != null) {
      return GamePlayEvent(messaging);
    } else if (messaging.passThreadControl != null) {
      return PassThreadControlEvent(messaging);
    } else if (messaging.takeThreadControl != null) {
      return TakeThreadControlEvent(messaging);
    } else if (messaging.requestThreadControl != null) {
      return RequestThreadControlEvent(messaging);
    } else if (messaging.optin != null) {
      return OptinEvent(messaging);
    } else if (messaging.referral != null) {
      return ReferralEvent(messaging);
    } else if (messaging.policyEnforcement != null) {
      return PolicyEnforcementEvent(messaging);
    } else if (messaging.messageEdit != null) {
      return MessageEditEvent(messaging);
    }
    return UnknownEvent(messaging);
  }

  static MessageType identifyMessageType(Message? message) {
    if (message == null) return UnknownMessage();

    // Check for echo first
    if (message.isEcho == true) {
      return EchoMessage(message: message, text: message.text);
    }

    if (message.quickReply != null) {
      return QuickReplyMessage(
          quickReply: message.quickReply!, text: message.text);
    }

    if (message.replyTo != null) {
      return ReplyMessage(replyTo: message.replyTo!, text: message.text);
    }

    if (message.attachments != null && message.attachments!.isNotEmpty) {
      if (message.attachments!.any((attachment) =>
          attachment.type == 'template' &&
          attachment.payload.templateType == 'product')) {
        return ProductTemplateMessage(
            productElements: message.attachments!.first.payload.elements ?? [],
            text: message.text);
      }
      return AttachmentMessage(
          attachments: message.attachments!, text: message.text);
    }

    if (message.referral != null) {
      if (message.referral!.source == 'ADS') {
        return AdsReferralMessage(
            referral: message.referral!, text: message.text);
      }
      return ShopsProductDetailMessage(
          referral: message.referral!, text: message.text);
    }

    if (message.commands != null && message.commands!.isNotEmpty) {
      return CommandMessage(commands: message.commands!, text: message.text);
    }

    if (message.text != null) {
      return TextMessage(text: message.text);
    }

    return UnknownMessage();
  }
}

/// Represents an entry in the webhook event, containing the actual event data.
class Entry {
  /// The page ID of the page that received the event.
  final String id;

  /// The time the event was received, in epoch time (milliseconds).
  final int time;

  /// The list of messaging events within this entry.
  final List<Messaging> messaging;

  /// Constructor for `Entry`.
  Entry({
    required this.id,
    required this.time,
    required this.messaging,
  });

  /// Creates an `Entry` from a JSON map.
  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'],
      time: json['time'],
      messaging: List<Messaging>.from(
          json['messaging'].map((e) => Messaging.fromJson(e))),
    );
  }

  /// Converts the `Entry` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'messaging': messaging.map((e) => e.toJson()).toList(),
    };
  }
}

/// Represents a messaging event, which can contain various types of notifications from the Messenger Platform.
class Messaging {
  /// The sender of the message, identified by a unique ID.
  final User sender;

  /// The recipient of the message, identified by a unique ID.
  final User recipient;

  /// The message sent by the user, if applicable.
  final Message? message;

  /// The postback received from a button click, if applicable.
  final Postback? postback;

  /// The delivery confirmation for a message, if applicable.
  final Delivery? delivery;

  /// The reaction to a message, if applicable.
  final Reaction? reaction;

  /// The read receipt for a message, if applicable.
  final Read? read;

  /// An echo of a message sent by the business, if applicable.
  final Echo? echo;

  /// The edit to a previously sent message, if applicable.
  final MessageEdit? messageEdit;

  /// Details of gameplay activity, if applicable.
  final GamePlay? gamePlay;

  /// Information about a handover protocol event (pass or take thread control).
  final PassThreadControl? passThreadControl;
  final TakeThreadControl? takeThreadControl;
  final RequestThreadControl? requestThreadControl;

  /// Feedback from a customer, if applicable.
  final MessagingFeedback? feedback;

  /// Account linking or unlinking event details, if applicable.
  final AccountLinking? accountLinking;

  final PolicyEnforcement? policyEnforcement;

  final Optin? optin;

  final Referral? referral;

  final MessagingCustomerInformation? messagingCustomerInformation;

  // Fields for group feed events
  final String? groupId;
  final String? commentId;
  final String? postId;
  final int? createdTime;
  final String? item;
  final String? verb;
  final String? field;
  final String? parentId;

  final Order? order;

  /// Constructor for `Messaging`.
  Messaging({
    required this.sender,
    required this.recipient,
    this.message,
    this.postback,
    this.delivery,
    this.reaction,
    this.read,
    this.echo,
    this.messageEdit,
    this.gamePlay,
    this.passThreadControl,
    this.takeThreadControl,
    this.requestThreadControl,
    this.feedback,
    this.accountLinking,
    this.policyEnforcement,
    this.optin,
    this.referral,
    this.messagingCustomerInformation,
    // Group feed fields
    this.groupId,
    this.commentId,
    this.postId,
    this.createdTime,
    this.item,
    this.verb,
    this.field,
    this.parentId,
    this.order,
  });

  /// Creates a `Messaging` object from a JSON map.
  factory Messaging.fromJson(Map<String, dynamic> json) {
    return Messaging(
      sender: User.fromJson(json['sender']),
      recipient: User.fromJson(json['recipient']),
      message:
          json['message'] != null ? Message.fromJson(json['message']) : null,
      postback:
          json['postback'] != null ? Postback.fromJson(json['postback']) : null,
      delivery:
          json['delivery'] != null ? Delivery.fromJson(json['delivery']) : null,
      reaction:
          json['reaction'] != null ? Reaction.fromJson(json['reaction']) : null,
      read: json['read'] != null ? Read.fromJson(json['read']) : null,
      echo: json['echo'] != null ? Echo.fromJson(json['echo']) : null,
      messageEdit: json['message_edit'] != null
          ? MessageEdit.fromJson(json['message_edit'])
          : null,
      gamePlay: json['game_play'] != null
          ? GamePlay.fromJson(json['game_play'])
          : null,
      passThreadControl: json['pass_thread_control'] != null
          ? PassThreadControl.fromJson(json['pass_thread_control'])
          : null,
      takeThreadControl: json['take_thread_control'] != null
          ? TakeThreadControl.fromJson(json['take_thread_control'])
          : null,
      requestThreadControl: json['request_thread_control'] != null
          ? RequestThreadControl.fromJson(json['request_thread_control'])
          : null,
      feedback: json['feedback'] != null
          ? MessagingFeedback.fromJson(json['feedback'])
          : null,
      accountLinking: json['account_linking'] != null
          ? AccountLinking.fromJson(json['account_linking'])
          : null,
      policyEnforcement: json['policy_enforcement'] != null
          ? PolicyEnforcement.fromJson(json['policy_enforcement'])
          : null,
      optin: json['optin'] != null ? Optin.fromJson(json['optin']) : null,
      referral:
          json['referral'] != null ? Referral.fromJson(json['referral']) : null,
      messagingCustomerInformation:
          json['messaging_customer_information'] != null
              ? MessagingCustomerInformation.fromJson(
                  json['messaging_customer_information'])
              : null,
      groupId: json['group_id'],
      commentId: json['comment_id'],
      postId: json['post_id'],
      createdTime: json['created_time'],
      item: json['item'],
      verb: json['verb'],
      field: json['field'],
      parentId: json['parent_id'],
      order: json['order'] != null ? Order.fromJson(json['order']) : null,
    );
  }

  /// Converts the `Messaging` object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'sender': sender.toJson(),
      'recipient': recipient.toJson(),
      'message': message?.toJson(),
      'postback': postback?.toJson(),
      'delivery': delivery?.toJson(),
      'reaction': reaction?.toJson(),
      'read': read?.toJson(),
      'echo': echo?.toJson(),
      'message_edit': messageEdit?.toJson(),
      'game_play': gamePlay?.toJson(),
      'pass_thread_control': passThreadControl?.toJson(),
      'take_thread_control': takeThreadControl?.toJson(),
      'request_thread_control': requestThreadControl?.toJson(),
      'feedback': feedback?.toJson(),
      'account_linking': accountLinking?.toJson(),
      'policy_enforcement': policyEnforcement?.toJson(),
      'optin': optin?.toJson(),
      'referral': referral?.toJson(),
      'messaging_customer_information': messagingCustomerInformation?.toJson(),
      'group_id': groupId,
      'comment_id': commentId,
      'post_id': postId,
      'created_time': createdTime,
      'item': item,
      'verb': verb,
      'field': field,
      'parent_id': parentId,
      'order': order?.toJson(),
    };
  }
}

/// Represents a user, which could be a sender or recipient in a messaging event.
class User {
  /// The unique ID of the user.
  final String id;

  /// Constructor for `User`.
  User({
    required this.id,
  });

  /// Creates a `User` from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
    );
  }

  /// Converts the `User` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}

/// Represents the message object in a messaging event.
class Message {
  /// The unique ID of the message.
  final String mid;

  /// The text content of the message, if applicable.
  final String? text;

  /// The quick reply payload, if the message is a response to a quick reply button.
  final QuickReply? quickReply;

  /// The reference to the message ID that this message is replying to, if applicable.
  final ReplyTo? replyTo;

  /// A list of attachments associated with the message, if any.
  final List<Attachment>? attachments;

  /// The referral information, if the message was sent from a Shops product detail page or an ad referral.
  final Referral? referral;

  /// The list of commands associated with the message, if applicable.
  final List<Command>? commands;

  /// Whether or not this message is an echo.
  final bool? isEcho;

  /// Constructor for `Message`.
  Message({
    required this.mid,
    this.text,
    this.quickReply,
    this.replyTo,
    this.attachments,
    this.referral,
    this.commands,
    this.isEcho,
  });

  /// Creates a `Message` object from a JSON map.
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      mid: json['mid'],
      text: json['text'],
      quickReply: json['quick_reply'] != null
          ? QuickReply.fromJson(json['quick_reply'])
          : null,
      replyTo:
          json['reply_to'] != null ? ReplyTo.fromJson(json['reply_to']) : null,
      attachments: json['attachments'] != null
          ? List<Attachment>.from(json['attachments']
              .map((attachment) => Attachment.fromJson(attachment)))
          : null,
      referral:
          json['referral'] != null ? Referral.fromJson(json['referral']) : null,
      commands: json['commands'] != null
          ? List<Command>.from(
              json['commands'].map((command) => Command.fromJson(command)))
          : null,
      isEcho: json['is_echo'],
    );
  }

  /// Converts the `Message` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'mid': mid,
      'text': text,
      'quick_reply': quickReply?.toJson(),
      'reply_to': replyTo?.toJson(),
      'attachments':
          attachments?.map((attachment) => attachment.toJson()).toList(),
      'referral': referral?.toJson(),
      'commands': commands?.map((command) => command.toJson()).toList(),
      'is_echo': isEcho,
    };
  }
}

/// Represents a postback event, triggered by interactions with buttons, such as
/// the Get Started button, a persistent menu item, or a postback button.
class Postback {
  /// The ID for the message associated with the postback event.
  final String? mid;

  /// The title for the Call To Action (CTA) that a person clicked.
  final String? title;

  /// The payload defined in the CTA.
  final String payload;

  /// The referral information, containing details of how the conversation started.
  final Referral? referral;

  /// Constructor for `Postback`.
  Postback({
    this.mid,
    this.title,
    required this.payload,
    this.referral,
  });

  /// Creates a `Postback` object from a JSON map.
  factory Postback.fromJson(Map<String, dynamic> json) {
    return Postback(
      mid: json['mid'],
      title: json['title'],
      payload: json['payload'],
      referral:
          json['referral'] != null ? Referral.fromJson(json['referral']) : null,
    );
  }

  /// Converts the `Postback` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'mid': mid,
      'title': title,
      'payload': payload,
      'referral': referral?.toJson(),
    };
  }
}

/// Represents the delivery event for a message that has been sent by your business.
class Delivery {
  /// List of message IDs that have been delivered. This field may not be present.
  final List<String>? mids;

  /// The watermark indicating the timestamp of the last message delivered.
  final int watermark;

  /// The sequence number associated with the delivery.
  final int? seq;

  /// Constructor for `Delivery`.
  Delivery({
    this.mids,
    required this.watermark,
    this.seq,
  });

  /// Creates a `Delivery` object from a JSON map.
  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      mids: json['mids'] != null ? List<String>.from(json['mids']) : null,
      watermark: _parseWatermark(json['watermark']),
      seq: json['seq'] != null ? int.tryParse(json['seq'].toString()) : null,
    );
  }

  /// Converts the `Delivery` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'mids': mids,
      'watermark': watermark,
      'seq': seq,
    };
  }

  /// Helper method to parse the watermark value
  static int _parseWatermark(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw FormatException('Invalid watermark value: $value');
  }
}

/// Represents a reaction to a message in the Messenger Platform.
class Reaction {
  /// The textual description of the reaction.
  /// Possible values: smile, angry, sad, wow, love, like, dislike, other.
  final String? reaction;

  /// The emoji corresponding to the reaction.
  final String? emoji;

  /// The action performed by the user (e.g., "react" or "unreact").
  final String? action;

  /// The Message ID that the user reacted to.
  final String? mid;

  /// Constructor for `Reaction`.
  Reaction({
    this.reaction,
    this.emoji,
    this.action,
    this.mid,
  });

  /// Creates a `Reaction` object from a JSON map.
  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      reaction: json['reaction'] as String?,
      emoji: json['emoji'] as String?,
      action: json['action'] as String?,
      mid: json['mid'] as String?,
    );
  }

  /// Converts the `Reaction` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'reaction': reaction,
      'emoji': emoji,
      'action': action,
      'mid': mid,
    };
  }
}

/// Represents the read receipt for a message in the Messenger Platform.
class Read {
  /// The watermark indicating the timestamp of the last message read.
  ///
  /// All messages that were sent before or at this timestamp were read by the recipient.
  /// The watermark field is a Unix timestamp (in milliseconds) representing the latest message read by the user.
  final int watermark;

  /// Constructor for `Read`.
  ///
  /// [watermark] is required and represents the time (in milliseconds) of the last message read by the user.
  Read({
    required this.watermark,
  });

  /// Creates a `Read` object from a JSON map.
  factory Read.fromJson(Map<String, dynamic> json) {
    return Read(
      watermark: json['watermark'] is int
          ? json['watermark']
          : int.parse(json['watermark'].toString()),
    );
  }

  /// Converts the `Read` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'watermark': watermark,
    };
  }
}

/// Represents an echo of a message sent by the business.
class Echo {
  /// The unique ID of the echoed message.
  final String mid;

  /// Indicates the message sent from the page itself.
  final bool isEcho;

  /// The ID of the app from which the message was sent.
  final String? appId;

  /// Custom metadata sent along with the message.
  final String? metadata;

  /// The text of the echoed message, if applicable.
  final String? text;

  /// The list of attachments sent with the echoed message, if any.
  final List<Attachment>? attachments;

  /// Constructor for `Echo`.
  Echo({
    required this.mid,
    required this.isEcho,
    this.appId,
    this.metadata,
    this.text,
    this.attachments,
  });

  /// Creates an `Echo` object from a JSON map.
  factory Echo.fromJson(Map<String, dynamic> json) {
    return Echo(
      mid: json['mid'],
      isEcho: json['is_echo'],
      appId: json['app_id']?.toString(),
      metadata: json['metadata'],
      text: json['text'],
      attachments: json['attachments'] != null
          ? List<Attachment>.from(json['attachments']
              .map((attachment) => Attachment.fromJson(attachment)))
          : null,
    );
  }

  /// Converts the `Echo` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'mid': mid,
      'is_echo': isEcho,
      'app_id': appId,
      'metadata': metadata,
      'text': text,
      'attachments':
          attachments?.map((attachment) => attachment.toJson()).toList(),
    };
  }
}

/// Represents an edit to a previously sent message in the Messenger Platform.
class MessageEdit {
  /// The unique ID of the edited message.
  final String mid;

  /// The new text of the edited message.
  final String? text;

  /// The number of times the message has been edited.
  /// Messenger clients allow editing a message up to five times.
  final int? numEdit;

  /// Constructor for `MessageEdit`.
  MessageEdit({
    required this.mid,
    this.text,
    this.numEdit,
  });

  /// Creates a `MessageEdit` object from a JSON map.
  factory MessageEdit.fromJson(Map<String, dynamic> json) {
    return MessageEdit(
      mid: json['mid'],
      text: json['text'],
      numEdit: json['num_edit'],
    );
  }

  /// Converts the `MessageEdit` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'mid': mid,
      'text': text,
      'num_edit': numEdit,
    };
  }
}

/// Represents when a person plays an Instant Game on the Messenger Platform.
class GamePlay {
  /// The Meta app ID for the game.
  final String gameId;

  /// The ID for the player in the Instant Game namespace.
  final String playerId;

  /// The locale for the player.
  final String? locale;

  /// The social context of the game (e.g., GROUP, SOLO, THREAD).
  final String? contextType;

  /// The ID for the social context type if the type is not SOLO.
  /// This ID is in the Instant Game namespace.
  final String? contextId;

  /// The best score achieved by the player during this round of gameplay.
  /// Only available for Classic score-based games.
  final int? score;

  /// The JSON encoded object set using FBInstant.setSessionData().
  /// Only available for Rich Games.
  final String? payload;

  /// Constructor for `GamePlay`.
  ///
  /// [gameId] and [playerId] are required. Other fields are optional.
  GamePlay({
    required this.gameId,
    required this.playerId,
    this.locale,
    this.contextType,
    this.contextId,
    this.score,
    this.payload,
  });

  /// Creates a `GamePlay` object from a JSON map.
  factory GamePlay.fromJson(Map<String, dynamic> json) {
    return GamePlay(
      gameId: json['game_id'],
      playerId: json['player_id'],
      locale: json['locale'],
      contextType: json['context_type'],
      contextId: json['context_id'],
      score: json['score'],
      payload: json['payload'],
    );
  }

  /// Converts the `GamePlay` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'player_id': playerId,
      'locale': locale,
      'context_type': contextType,
      'context_id': contextId,
      'score': score,
      'payload': payload,
    };
  }
}

/// Represents a pass thread control event in the Messenger Platform.
class PassThreadControl {
  /// The App ID that thread control is passed to.
  final String newOwnerAppId;

  /// The App ID that thread control is passed from.
  /// This could be null if the thread was in idle mode.
  final String? previousOwnerAppId;

  /// Custom metadata specified in the API request.
  final String? metadata;

  /// Constructor for `PassThreadControl`.
  PassThreadControl({
    required this.newOwnerAppId,
    this.previousOwnerAppId,
    this.metadata,
  });

  /// Creates a `PassThreadControl` object from a JSON map.
  factory PassThreadControl.fromJson(Map<String, dynamic> json) {
    return PassThreadControl(
      newOwnerAppId: json['new_owner_app_id'],
      previousOwnerAppId: json['previous_owner_app_id'],
      metadata: json['metadata'],
    );
  }

  /// Converts the `PassThreadControl` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'new_owner_app_id': newOwnerAppId,
      'previous_owner_app_id': previousOwnerAppId,
      'metadata': metadata,
    };
  }
}

/// Represents a take thread control event in the Messenger Platform.
class TakeThreadControl {
  /// The App ID that thread control was taken from.
  /// This could be null if the thread was in idle mode.
  final String previousOwnerAppId;

  /// The App ID that thread control is given to.
  final String? newOwnerAppId;

  /// Custom metadata specified in the API request.
  final String? metadata;

  /// Constructor for `TakeThreadControl`.
  TakeThreadControl({
    required this.previousOwnerAppId,
    this.newOwnerAppId,
    this.metadata,
  });

  /// Creates a `TakeThreadControl` object from a JSON map.
  factory TakeThreadControl.fromJson(Map<String, dynamic> json) {
    return TakeThreadControl(
      previousOwnerAppId: json['previous_owner_app_id'],
      newOwnerAppId: json['new_owner_app_id'],
      metadata: json['metadata'],
    );
  }

  /// Converts the `TakeThreadControl` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'previous_owner_app_id': previousOwnerAppId,
      'new_owner_app_id': newOwnerAppId,
      'metadata': metadata,
    };
  }
}

/// Represents a request for thread control by a secondary app.
class RequestThreadControl {
  /// The App ID of the secondary receiver that is requesting thread control.
  final String requestedOwnerAppId;

  /// Custom metadata specified in the API request.
  final String? metadata;

  /// Constructor for `RequestThreadControl`.
  RequestThreadControl({
    required this.requestedOwnerAppId,
    this.metadata,
  });

  /// Creates a `RequestThreadControl` object from a JSON map.
  factory RequestThreadControl.fromJson(Map<String, dynamic> json) {
    return RequestThreadControl(
      requestedOwnerAppId: json['requested_owner_app_id'],
      metadata: json['metadata'],
    );
  }

  /// Converts the `RequestThreadControl` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'requested_owner_app_id': requestedOwnerAppId,
      'metadata': metadata,
    };
  }
}

/// Represents an app role change event in the Messenger Platform.
class AppRoles {
  /// A map of app IDs to their roles (e.g., "primary_receiver", "secondary_receiver").
  final Map<String, List<String>> roles;

  /// Constructor for `AppRoles`.
  AppRoles({
    required this.roles,
  });

  /// Creates an `AppRoles` object from a JSON map.
  factory AppRoles.fromJson(Map<String, dynamic> json) {
    return AppRoles(
      roles: Map<String, List<String>>.from(json['app_roles'].map(
          (appId, roleList) => MapEntry(appId, List<String>.from(roleList)))),
    );
  }

  /// Converts the `AppRoles` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'app_roles': roles.map((appId, roleList) => MapEntry(appId, roleList)),
    };
  }
}

/// Represents an opt-in event triggered by a plugin or checkbox selection in the Messenger Platform.
class Optin {
  /// Additional information that you want to include in the webhook's notification.
  final String? payload;

  /// The title displayed in the opt-in template.
  final String? title;

  /// The token that represents the person who opted in for Marketing Messages.
  final String? notificationMessagesToken;

  /// The frequency of Marketing Messages.
  /// Possible values are DAILY, WEEKLY, MONTHLY.
  final String? notificationMessagesFrequency;

  /// The timezone for the person receiving the message.
  final String? notificationMessagesTimezone;

  /// The timestamp when the notification message token expires.
  final int? tokenExpiryTimestamp;

  /// The status of the user token.
  /// Possible values are REFRESHED, NOT_REFRESHED.
  final String? userTokenStatus;

  /// The status of the Marketing Messages notifications.
  /// Possible values are STOP NOTIFICATIONS, RESUME NOTIFICATIONS.
  final String? notificationMessagesStatus;

  /// The type of the opt-in event, should be "notification_messages".
  final String type;

  /// Constructor for `Optin`.
  Optin({
    this.payload,
    this.title,
    this.notificationMessagesToken,
    this.notificationMessagesFrequency,
    this.notificationMessagesTimezone,
    this.tokenExpiryTimestamp,
    this.userTokenStatus,
    this.notificationMessagesStatus,
    required this.type,
  });

  /// Creates an `Optin` object from a JSON map.
  factory Optin.fromJson(Map<String, dynamic> json) {
    return Optin(
      payload: json['payload'],
      title: json['title'],
      notificationMessagesToken: json['notification_messages_token'],
      notificationMessagesFrequency: json['notification_messages_frequency'],
      notificationMessagesTimezone: json['notification_messages_timezone'],
      tokenExpiryTimestamp: json['token_expiry_timestamp'],
      userTokenStatus: json['user_token_status'],
      notificationMessagesStatus: json['notification_messages_status'],
      type: json['type'],
    );
  }

  /// Converts the `Optin` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'payload': payload,
      'title': title,
      'notification_messages_token': notificationMessagesToken,
      'notification_messages_frequency': notificationMessagesFrequency,
      'notification_messages_timezone': notificationMessagesTimezone,
      'token_expiry_timestamp': tokenExpiryTimestamp,
      'user_token_status': userTokenStatus,
      'notification_messages_status': notificationMessagesStatus,
      'type': type,
    };
  }
}

class PolicyEnforcement {
  /// The enforcement action taken, such as "warning", "block", or "unblock".
  final String action;

  /// The reason for the enforcement action, typically absent when the action is "unblock".
  final String? reason;

  /// Constructor for `PolicyEnforcement`.
  PolicyEnforcement({
    required this.action,
    this.reason,
  });

  /// Creates a `PolicyEnforcement` object from a JSON map.
  factory PolicyEnforcement.fromJson(Map<String, dynamic> json) {
    return PolicyEnforcement(
      action: json['action'],
      reason: json['reason'],
    );
  }

  /// Converts the `PolicyEnforcement` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'reason': reason,
    };
  }
}

/// Represents a referral event, triggered by sources such as m.me links, ads, or the customer chat plugin.
class Referral {
  /// The optional ref attribute set in the referrer. It can contain alphanumeric characters and -, _, and =.
  final String? ref;

  /// The source of the referral. Possible values include SHORTLINK, ADS, CUSTOMER_CHAT_PLUGIN.
  final String source;

  /// The type of referral. Currently supports OPEN_THREAD.
  final String type;

  /// The URI of the website where the message was sent via the Facebook Chat Plugin.
  final String? refererUri;

  /// Indicates whether the user is a guest user from the Facebook Chat Plugin.
  final bool? isGuestUser;

  /// The ad-related context data when the referral comes from an ad.
  final AdsContextData? adsContextData;

  /// Constructor for `Referral`.
  Referral({
    this.ref,
    required this.source,
    required this.type,
    this.refererUri,
    this.isGuestUser,
    this.adsContextData,
  });

  /// Creates a `Referral` object from a JSON map.
  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      ref: json['ref'],
      source: json['source'],
      type: json['type'],
      refererUri: json['referer_uri'],
      isGuestUser: json['is_guest_user'] != null
          ? json['is_guest_user'] == "true"
          : null,
      adsContextData: json['ads_context_data'] != null
          ? AdsContextData.fromJson(json['ads_context_data'])
          : null,
    );
  }

  /// Converts the `Referral` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'ref': ref,
      'source': source,
      'type': type,
      'referer_uri': refererUri,
      'is_guest_user': isGuestUser?.toString(),
      'ads_context_data': adsContextData?.toJson(),
    };
  }
}

/// Represents the ad-related context data when a referral is triggered by an ad.
class AdsContextData {
  /// The title of the ad.
  final String? adTitle;

  /// The URL of the image from the ad the user is interested in.
  final String? photoUrl;

  /// The thumbnail URL of the video from the ad.
  final String? videoUrl;

  /// The ID of the post related to the ad.
  final String? postId;

  /// The optional product ID from the ad the user is interested in.
  final String? productId;

  /// Constructor for `AdsContextData`.
  AdsContextData({
    this.adTitle,
    this.photoUrl,
    this.videoUrl,
    this.postId,
    this.productId,
  });

  /// Creates an `AdsContextData` object from a JSON map.
  factory AdsContextData.fromJson(Map<String, dynamic> json) {
    return AdsContextData(
      adTitle: json['ad_title'],
      photoUrl: json['photo_url'],
      videoUrl: json['video_url'],
      postId: json['post_id'],
      productId: json['product_id'],
    );
  }

  /// Converts the `AdsContextData` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'ad_title': adTitle,
      'photo_url': photoUrl,
      'video_url': videoUrl,
      'post_id': postId,
      'product_id': productId,
    };
  }
}

/// Represents when a message has been seen by a user.
class Seen {
  /// The watermark indicating the timestamp of the last message seen.
  final int watermark;

  /// Constructor for `Seen`.
  Seen({
    required this.watermark,
  });

  /// Creates a `Seen` object from a JSON map.
  factory Seen.fromJson(Map<String, dynamic> json) {
    return Seen(
      watermark: json['watermark'],
    );
  }

  /// Converts the `Seen` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'watermark': watermark,
    };
  }
}

/// Represents an event received in the standby channel during the Handover Protocol.
class Standby {
  /// The sender of the standby event, identified by a unique ID.
  final String senderId;

  /// The recipient of the standby event, typically the Facebook Page ID.
  final String recipientId;

  /// The timestamp of the standby event.
  final int timestamp;

  /// The message received in standby mode.
  final Message? message;

  /// The read receipt event received in standby mode.
  final Read? read;

  /// The delivery event received in standby mode.
  final Delivery? delivery;

  /// The postback event received in standby mode.
  final Postback? postback;

  /// Constructor for `Standby`.
  Standby({
    required this.senderId,
    required this.recipientId,
    required this.timestamp,
    this.message,
    this.read,
    this.delivery,
    this.postback,
  });

  /// Creates a `Standby` object from a JSON map.
  factory Standby.fromJson(Map<String, dynamic> json) {
    return Standby(
      senderId: json['sender']['id'],
      recipientId: json['recipient']['id'],
      timestamp: json['timestamp'],
      message:
          json['message'] != null ? Message.fromJson(json['message']) : null,
      read: json['read'] != null ? Read.fromJson(json['read']) : null,
      delivery:
          json['delivery'] != null ? Delivery.fromJson(json['delivery']) : null,
      postback:
          json['postback'] != null ? Postback.fromJson(json['postback']) : null,
    );
  }

  /// Converts the `Standby` object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'sender': {'id': senderId},
      'recipient': {'id': recipientId},
      'timestamp': timestamp,
      'message': message?.toJson(),
      'read': read?.toJson(),
      'delivery': delivery?.toJson(),
      'postback': postback?.toJson(),
    };
  }
}

class Order {
  final List<Product> products;
  final String? note;
  final String? source;

  Order({
    required this.products,
    this.note,
    this.source,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var productList = json['products'] as List;
    List<Product> products =
        productList.map((i) => Product.fromJson(i)).toList();

    return Order(
      products: products,
      note: json['note'],
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((product) => product.toJson()).toList(),
      'note': note,
      'source': source,
    };
  }
}

/// Represents a product in the order.
class Product {
  /// The product ID from the Facebook product catalog.
  final String id;

  /// The retailer's external ID associated with the product (e.g., SKU).
  final String retailerId;

  /// The name of the product.
  final String name;

  /// The price per unit of the product.
  final double unitPrice;

  /// The currency in which the price is listed (e.g., USD).
  final String currency;

  /// The quantity of the product ordered.
  final int quantity;

  /// Constructor for `Product`.
  Product({
    required this.id,
    required this.retailerId,
    required this.name,
    required this.unitPrice,
    required this.currency,
    required this.quantity,
  });

  /// Creates a `Product` object from a JSON map.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      retailerId: json['retailer_id'],
      name: json['name'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      currency: json['currency'],
      quantity: json['quantity'],
    );
  }

  /// Converts the `Product` object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'retailer_id': retailerId,
      'name': name,
      'unit_price': unitPrice,
      'currency': currency,
      'quantity': quantity,
    };
  }
}

/// Represents the feedback submitted by a customer via the Messenger Platform's Customer Feedback Template.
class MessagingFeedback {
  /// The list of feedback screens that the customer interacted with.
  final List<FeedbackScreen> feedbackScreens;

  /// Constructor for `MessagingFeedback`.
  MessagingFeedback({
    required this.feedbackScreens,
  });

  /// Creates a `MessagingFeedback` object from a JSON map.
  factory MessagingFeedback.fromJson(Map<String, dynamic> json) {
    return MessagingFeedback(
      feedbackScreens: List<FeedbackScreen>.from(json['feedback_screens']
          .map((screen) => FeedbackScreen.fromJson(screen))),
    );
  }

  /// Converts the `MessagingFeedback` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'feedback_screens':
          feedbackScreens.map((screen) => screen.toJson()).toList(),
    };
  }
}

/// Represents a screen in the customer feedback template.
class FeedbackScreen {
  /// The ID of the feedback screen.
  final int screenId;

  /// The list of questions and customer responses on this feedback screen.
  final Map<String, QuestionResponse> questions;

  /// Constructor for `FeedbackScreen`.
  FeedbackScreen({
    required this.screenId,
    required this.questions,
  });

  /// Creates a `FeedbackScreen` object from a JSON map.
  factory FeedbackScreen.fromJson(Map<String, dynamic> json) {
    return FeedbackScreen(
      screenId: json['screen_id'],
      questions: Map<String, QuestionResponse>.from(json['questions'].map(
          (questionId, response) =>
              MapEntry(questionId, QuestionResponse.fromJson(response)))),
    );
  }

  /// Converts the `FeedbackScreen` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'screen_id': screenId,
      'questions': questions.map(
          (questionId, response) => MapEntry(questionId, response.toJson())),
    };
  }
}

/// Represents the response to a question in the customer feedback form.
class QuestionResponse {
  /// The type of question (e.g., "csat", "nps", "ces", "free_form").
  final String type;

  /// The payload representing the customer's selected score or response.
  final String payload;

  /// Optional follow-up response from the customer (free-form input).
  final FollowUpResponse? followUp;

  /// Constructor for `QuestionResponse`.
  QuestionResponse({
    required this.type,
    required this.payload,
    this.followUp,
  });

  /// Creates a `QuestionResponse` object from a JSON map.
  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionResponse(
      type: json['type'],
      payload: json['payload'],
      followUp: json['follow_up'] != null
          ? FollowUpResponse.fromJson(json['follow_up'])
          : null,
    );
  }

  /// Converts the `QuestionResponse` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'payload': payload,
      'follow_up': followUp?.toJson(),
    };
  }
}

/// Represents a free-form text response submitted by the customer as additional feedback.
class FollowUpResponse {
  /// The type of follow-up response, always "free_form".
  final String type;

  /// The free-form text input provided by the customer.
  final String payload;

  /// Constructor for `FollowUpResponse`.
  FollowUpResponse({
    required this.type,
    required this.payload,
  });

  /// Creates a `FollowUpResponse` object from a JSON map.
  factory FollowUpResponse.fromJson(Map<String, dynamic> json) {
    return FollowUpResponse(
      type: json['type'],
      payload: json['payload'],
    );
  }

  /// Converts the `FollowUpResponse` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'payload': payload,
    };
  }
}

/// Represents an account linking or unlinking event in the Messenger Platform.
class AccountLinking {
  /// The status of the account linking, which can be either "linked" or "unlinked".
  final String status;

  /// The authorization code provided during the account linking process.
  ///
  /// This field is only present if the account linking was successful (status is "linked").
  final String? authorizationCode;

  /// Constructor for `AccountLinking`.
  ///
  /// [status] is required and should be either "linked" or "unlinked".
  /// [authorizationCode] is optional and will be provided only if the account was successfully linked.
  AccountLinking({
    required this.status,
    this.authorizationCode,
  });

  /// Creates an `AccountLinking` object from a JSON map.
  factory AccountLinking.fromJson(Map<String, dynamic> json) {
    return AccountLinking(
      status: json['status'],
      authorizationCode: json['authorization_code'],
    );
  }

  /// Converts the `AccountLinking` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'authorization_code': authorizationCode,
    };
  }
}

/// Represents a generic attachment that can be used in both webhooks and the Send API.
class Attachment {
  /// The type of the attachment (e.g., image, audio, video, file, template, fallback).
  final String type;

  /// The payload associated with the attachment, which can contain different fields depending on the type.
  final AttachmentPayload payload;

  /// Constructor for `Attachment`.
  Attachment({
    required this.type,
    required this.payload,
  });

  /// Creates an `Attachment` object from a JSON map.
  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      type: json['type'],
      payload: AttachmentPayload.fromJson(json['payload']),
    );
  }

  /// Converts the `Attachment` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'payload': payload.toJson(),
    };
  }
}

/// Represents the payload of an attachment.
class AttachmentPayload {
  /// The URL of the attachment, if applicable (e.g., for image, audio, video, or file attachments).
  final String? url;

  /// The reusable attachment ID, if available.
  final String? attachmentId;

  /// Indicates if the attachment is reusable for future messages.
  final bool? isReusable;

  /// The template type, if this is a template attachment.
  final String? templateType;

  /// The elements contained in the template, such as media or products.
  final List<Element>? elements;

  /// Constructor for `AttachmentPayload`.
  AttachmentPayload({
    this.url,
    this.attachmentId,
    this.isReusable,
    this.templateType,
    this.elements,
  });

  /// Creates an `AttachmentPayload` object from a JSON map.
  factory AttachmentPayload.fromJson(Map<String, dynamic> json) {
    return AttachmentPayload(
      url: json['url'],
      attachmentId: json['attachment_id'],
      isReusable: json['is_reusable'],
      templateType: json['template_type'],
      elements: json['elements'] != null
          ? List<Element>.from(
              json['elements'].map((element) => Element.fromJson(element)))
          : null,
    );
  }

  /// Converts the `AttachmentPayload` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'attachment_id': attachmentId,
      'is_reusable': isReusable,
      'template_type': templateType,
      'elements': elements?.map((element) => element.toJson()).toList(),
    };
  }
}

/// Represents an element within a template attachment, such as media or product details.
class Element {
  /// The media type (e.g., image) or product ID.
  final String? mediaType;

  /// The URL of the media or product image.
  final String? url;

  /// The ID of the attachment or product.
  final String? id;

  /// The title of the product, if applicable.
  final String? title;

  /// The subtitle of the product, if applicable.
  final String? subtitle;

  /// Constructor for `Element`.
  Element({
    this.mediaType,
    this.url,
    this.id,
    this.title,
    this.subtitle,
  });

  /// Creates an `Element` object from a JSON map.
  factory Element.fromJson(Map<String, dynamic> json) {
    return Element(
      mediaType: json['media_type'],
      url: json['url'],
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
    );
  }

  /// Converts the `Element` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'media_type': mediaType,
      'url': url,
      'id': id,
      'title': title,
      'subtitle': subtitle,
    };
  }
}

/// Represents a Quick Reply button in a Messenger message.
class QuickReply {
  /// The type of the quick reply button.
  ///
  /// Must be one of the following:
  /// - `text`: Sends a text button.
  /// - `user_phone_number`: Sends a button allowing the recipient to send their phone number.
  /// - `user_email`: Sends a button allowing the recipient to send their email address.
  final String? contentType;

  /// The text to display on the quick reply button.
  ///
  /// Required if `contentType` is 'text'. This text is displayed on the button (20 character limit).
  final String? title;

  /// Custom data that will be sent back via the `messaging_postbacks` webhook event.
  ///
  /// Required if `contentType` is 'text'. This payload can hold any developer-defined information (1000 character limit).
  final String? payload;

  /// URL of the image to display on the quick reply button for text quick replies.
  ///
  /// Optional. Image should be a minimum of 24px x 24px. Larger images will be automatically cropped and resized.
  final String? imageUrl;

  /// Constructor for `QuickReply`.
  ///
  /// [contentType] is required and can be 'text', 'user_phone_number', or 'user_email'.
  /// If `contentType` is 'text', [title] and [payload] are required.
  QuickReply({
    required this.contentType,
    this.title,
    this.payload,
    this.imageUrl,
  }) : assert(
            contentType == 'text'
                ? title != null && payload != null
                : title == null && payload == null && imageUrl == null,
            'Title and payload are only required for text quick replies');

  /// Creates a `QuickReply` object from a JSON map.
  factory QuickReply.fromJson(Map<String, dynamic> json) {
    return QuickReply(
      contentType: json['content_type'] as String?,
      title: json['title'] as String?,
      payload: json['payload'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  /// Converts the `QuickReply` object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'content_type': contentType,
      'title': title,
      'payload': payload,
      'image_url': imageUrl,
    };
  }
}

/// Represents the reference to a message that this message is replying to.
class ReplyTo {
  /// The ID of the message that this message is replying to.
  ///
  /// This is the unique message ID (`mid`) of the original message being replied to.
  final String mid;

  /// Constructor for `ReplyTo`.
  ///
  /// [mid] is required and represents the message ID of the original message being replied to.
  ReplyTo({
    required this.mid,
  });

  /// Creates a `ReplyTo` object from a JSON map.
  factory ReplyTo.fromJson(Map<String, dynamic> json) {
    return ReplyTo(
      mid: json['mid'],
    );
  }

  /// Converts the `ReplyTo` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'mid': mid,
    };
  }
}

/// Represents a command within a message.
class Command {
  /// The name of the command.
  ///
  /// This is the name of the action or command specified in the message, such as "flights".
  final String name;

  /// Constructor for `Command`.
  ///
  /// [name] is required and represents the name of the command.
  Command({
    required this.name,
  });

  /// Creates a `Command` object from a JSON map.
  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(
      name: json['name'],
    );
  }

  /// Converts the `Command` to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}

// Sealed class for different event types
sealed class Event {
  final Messaging messaging;
  Event(this.messaging);
}

class SendCartEvent extends Event {
  SendCartEvent(super.messaging);
}

class CustomerInformationEvent extends Event {
  final MessagingCustomerInformation customerInformation;
  CustomerInformationEvent(super.messaging)
      : customerInformation = messaging.messagingCustomerInformation!;
}

class MessageEditEvent extends Event {
  final MessageEdit edit;
  MessageEditEvent(super.messaging) : edit = messaging.messageEdit!;
}

class MessageEvent extends Event {
  final Message message;
  MessageEvent(super.messaging) : message = messaging.message!;
}

class PostbackEvent extends Event {
  final Postback postback;
  PostbackEvent(super.messaging) : postback = messaging.postback!;
}

class DeliveryEvent extends Event {
  final Delivery delivery;
  DeliveryEvent(super.messaging) : delivery = messaging.delivery!;
}

class ReadEvent extends Event {
  final Read read;
  ReadEvent(super.messaging) : read = messaging.read!;
}

class ReactionEvent extends Event {
  final Reaction reaction;
  ReactionEvent(super.messaging) : reaction = messaging.reaction!;
}

class EchoEvent extends Event {
  final Echo echo;
  EchoEvent(super.messaging) : echo = messaging.echo!;
}

class GamePlayEvent extends Event {
  final GamePlay gamePlay;
  GamePlayEvent(super.messaging) : gamePlay = messaging.gamePlay!;
}

class PassThreadControlEvent extends Event {
  final PassThreadControl passThreadControl;
  PassThreadControlEvent(super.messaging)
      : passThreadControl = messaging.passThreadControl!;
}

class TakeThreadControlEvent extends Event {
  final TakeThreadControl takeThreadControl;
  TakeThreadControlEvent(super.messaging)
      : takeThreadControl = messaging.takeThreadControl!;
}

class RequestThreadControlEvent extends Event {
  final RequestThreadControl requestThreadControl;
  RequestThreadControlEvent(super.messaging)
      : requestThreadControl = messaging.requestThreadControl!;
}

class OptinEvent extends Event {
  final Optin optin;
  OptinEvent(super.messaging) : optin = messaging.optin!;
}

class ReferralEvent extends Event {
  final Referral referral;
  ReferralEvent(super.messaging) : referral = messaging.referral!;
}

/// Represents a policy enforcement event on a page in the Messenger Platform.
class PolicyEnforcementEvent extends Event {
  final PolicyEnforcement policyEnforcement;
  PolicyEnforcementEvent(super.messaging)
      : policyEnforcement = messaging.policyEnforcement!;
}

class UnknownEvent extends Event {
  UnknownEvent(super.messaging);
}

class AccountLinkingEvent extends Event {
  final AccountLinking accountLinking;
  AccountLinkingEvent(super.messaging)
      : accountLinking = messaging.accountLinking!;
}

class GroupFeedEvent extends Event {
  GroupFeedEvent(super.messaging);
}

sealed class MessageType {
  final String? text;

  MessageType({this.text});
}

class TextMessage extends MessageType {
  TextMessage({super.text});
}

class QuickReplyMessage extends MessageType {
  final QuickReply quickReply;

  QuickReplyMessage({required this.quickReply, super.text});
}

class ReplyMessage extends MessageType {
  final ReplyTo replyTo;

  ReplyMessage({required this.replyTo, super.text});
}

class AttachmentMessage extends MessageType {
  final List<Attachment> attachments;

  AttachmentMessage({required this.attachments, super.text});
}

class ProductTemplateMessage extends MessageType {
  final List<Element> productElements;

  ProductTemplateMessage({required this.productElements, super.text});
}

class ShopsProductDetailMessage extends MessageType {
  final Referral referral;

  ShopsProductDetailMessage({required this.referral, super.text});
}

class AdsReferralMessage extends MessageType {
  final Referral referral;

  AdsReferralMessage({required this.referral, super.text});
}

class CommandMessage extends MessageType {
  final List<Command> commands;

  CommandMessage({required this.commands, super.text});
}

class UnknownMessage extends MessageType {
  UnknownMessage({super.text});
}

class EchoMessage extends MessageType {
  final Message message;
  EchoMessage({required this.message, super.text});
}

// Templates

class MessagingCustomerInformation {
  final List<Screen> screens;

  MessagingCustomerInformation({required this.screens});

  factory MessagingCustomerInformation.fromJson(Map<String, dynamic> json) {
    var screensList = json['screens'] as List;
    List<Screen> screens =
        screensList.map((screenJson) => Screen.fromJson(screenJson)).toList();
    return MessagingCustomerInformation(screens: screens);
  }

  Map<String, dynamic> toJson() {
    return {
      'screens': screens.map((screen) => screen.toJson()).toList(),
    };
  }
}

class Screen {
  final String screenId;
  final List<ScreenResponse> responses;

  Screen({required this.screenId, required this.responses});

  factory Screen.fromJson(Map<String, dynamic> json) {
    var responsesList = json['responses'] as List;
    List<ScreenResponse> responses = responsesList
        .map((responseJson) => ScreenResponse.fromJson(responseJson))
        .toList();
    return Screen(
      screenId: json['screen_id'],
      responses: responses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'screen_id': screenId,
      'responses': responses.map((response) => response.toJson()).toList(),
    };
  }
}

class ScreenResponse {
  final String key;
  final String value;

  ScreenResponse({required this.key, required this.value});

  factory ScreenResponse.fromJson(Map<String, dynamic> json) {
    return ScreenResponse(
      key: json['key'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
    };
  }
}
