// models/message_model.dart
class MessageModel {
  String senderId;
  String receverId;
  String message;
  dynamic timestamp;
  String day;
  bool isSeen;
  String? messageType;
  String? fileName;
  String? fileExtension;
  double? latitude;
  double? longitude;
  String? address;

  // ✅ ADD THESE NEW FIELDS
  String? messageId; // Add this field
  String? status; // "sent", "delivered", "read"
  DateTime? deliveredAt;
  DateTime? readAt;

  // WhatsApp जैसे Live Location के लिए
  bool? isLive;
  String? sessionId;
  int? expiryTime;
  int? duration;
  bool? isActive;
  String? previewImage; // Base64 encoded map preview

  // home_screen Data
  String? senderName;
  String? receiverName;
  String? name;
  String? lastmessage;
  String? time;
  int? unreadCount;
  bool? isOnline;
  String? avatarUrl;
  DateTime? lastSeen;
  String? chatPartnerName;
  bool? isTyping;

  final bool? isDeletedForMe;
  final bool? isDeletedForEveryone;
  final String? deletedAt;

  MessageModel({
    required this.senderId,
    required this.receverId,
    required this.message,
    required this.timestamp,
    required this.day,
    required this.isSeen,
    this.messageType = "text",
    this.fileName,
    this.fileExtension,
    this.latitude,
    this.longitude,
    this.address,

    // ✅ ADD THESE TO CONSTRUCTOR
    this.messageId,
    this.status = "sent",
    this.deliveredAt,
    this.readAt,

    this.isLive = false,
    this.sessionId,
    this.expiryTime,
    this.duration,
    this.isActive = false,
    this.previewImage,
    this.senderName,
    this.receiverName,
    this.name,
    this.lastmessage,
    this.time,
    this.unreadCount = 0,
    this.isOnline = false,
    this.avatarUrl = "no",
    this.lastSeen,
    this.chatPartnerName,
    this.isTyping = false,
    this.isDeletedForMe = false,
    this.isDeletedForEveryone = false,
    this.deletedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      senderId: json['senderId']?.toString() ?? '',
      receverId: json['receverId']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timestamp: json['timestamp'] ?? 0,
      day: json['day']?.toString() ?? 'Today',
      isSeen: json['isSeen'] ?? false,
      messageType: json['messageType']?.toString() ?? 'text',
      fileName: json['fileName']?.toString(),
      fileExtension: json['fileExtension']?.toString(),
      latitude: json['latitude'] != null ?
      double.parse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ?
      double.parse(json['longitude'].toString()) : null,
      address: json['address']?.toString(),

      // ✅ ADD THESE TO fromJson
      messageId: json['messageId']?.toString(),
      status: json['status']?.toString() ?? 'sent',
      deliveredAt: json['deliveredAt'] != null ?
      DateTime.tryParse(json['deliveredAt'].toString()) : null,
      readAt: json['readAt'] != null ?
      DateTime.tryParse(json['readAt'].toString()) : null,

      isLive: json['isLive'] ?? false,
      sessionId: json['sessionId']?.toString(),
      expiryTime: json['expiryTime'] != null ?
      int.parse(json['expiryTime'].toString()) : null,
      duration: json['duration'] != null ?
      int.parse(json['duration'].toString()) : null,
      isActive: json['isActive'] ?? false,
      previewImage: json['previewImage']?.toString(),
      senderName: json['senderName']?.toString(),
      receiverName: json['receiverName']?.toString(),
      name: json['name']?.toString(),
      lastmessage: json['lastmessage']?.toString(),
      time: json['time']?.toString(),
      unreadCount: json['unreadCount'] != null ?
      int.parse(json['unreadCount'].toString()) : 0,
      isOnline: json['isOnline'] ?? false,
      avatarUrl: json['avatarUrl']?.toString() ?? "no",
      lastSeen: json['lastSeen'] != null ?
      DateTime.tryParse(json['lastSeen'].toString()) : null,
      chatPartnerName: json['chatPartnerName']?.toString(),
      isTyping: json['isTyping'] ?? false,
      isDeletedForMe: json['isDeletedForMe'] ?? false,
      isDeletedForEveryone: json['isDeletedForEveryone'] ?? false,
      deletedAt: json['deletedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receverId': receverId,
      'message': message,
      'timestamp': timestamp,
      'day': day,
      'isSeen': isSeen,
      'messageType': messageType,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,

      // ✅ ADD THESE TO toJson
      'messageId': messageId,
      'status': status,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),

      'isLive': isLive,
      'sessionId': sessionId,
      'expiryTime': expiryTime,
      'duration': duration,
      'isActive': isActive,
      'previewImage': previewImage,
      'senderName': senderName,
      'receiverName': receiverName,
      'name': name,
      'lastmessage': lastmessage,
      'time': time,
      'unreadCount': unreadCount,
      'isOnline': isOnline,
      'avatarUrl': avatarUrl,
      'lastSeen': lastSeen?.toIso8601String(),
      'chatPartnerName': chatPartnerName,
      'isTyping': isTyping,
      'isDeletedForMe': isDeletedForMe,
      'isDeletedForEveryone': isDeletedForEveryone,
      'deletedAt': deletedAt,
    };
  }

  // Home screen के लिए chat summary बनाने का method
  Map<String, dynamic> toChatSummary(String currentUserId) {
    bool isMe = senderId == currentUserId;

    return {
      'chatId': isMe ? receverId : senderId,
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'formattedTime': _getFormattedTime(timestamp),
      'unreadCount': isMe ? 0 : (isSeen ? 0 : 1), // Only count unread messages from others
      'isOnline': isOnline ?? false,
      'avatarUrl': avatarUrl ?? "no",
      'lastSeen': lastSeen?.toIso8601String(),
      'chatPartnerName': isMe ? receiverName : senderName,
      'name': name ?? (isMe ? receiverName : senderName), // ADDED
      'isTyping': isTyping ?? false,
      'messageType': messageType,
    };
  }

  MessageModel copyWith({
    String? senderId,
    String? receverId,
    String? message,
    dynamic timestamp,
    String? day,
    bool? isSeen,
    String? messageType,
    String? name,
    String? lastmessage,
    String? time,
    int? unreadCount,
    bool? isOnline,
    String? avatarUrl,
    DateTime? lastSeen,
    String? chatPartnerName,
  }) {
    return MessageModel(
      senderId: senderId ?? this.senderId,
      receverId: receverId ?? this.receverId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      day: day ?? this.day,
      isSeen: isSeen ?? this.isSeen,
      messageType: messageType ?? this.messageType,
      name: name ?? this.name,
      lastmessage: lastmessage ?? this.lastmessage,
      time: time ?? this.time,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastSeen: lastSeen ?? this.lastSeen,
      chatPartnerName: chatPartnerName ?? this.chatPartnerName,
    );
  }

  // MessageModel class में ये method add करें
  int getTimestampAsInt() {
    if (timestamp is int) {
      return timestamp as int;
    } else if (timestamp is String) {
      return int.tryParse(timestamp) ?? 0;
    } else if (timestamp is double) {
      return timestamp.toInt();
    }
    return 0;
  }

// और toChatSummary method में भी fix करें
  String _getFormattedTime(dynamic timestamp) {
    try {
      int time = getTimestampAsInt();
      DateTime date = DateTime.fromMillisecondsSinceEpoch(time);
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }
}