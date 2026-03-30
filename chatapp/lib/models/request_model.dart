// models/request_model.dart
class RequestModel {
  String? id;
  String? senderId;
  String? senderName;
  String? senderEmail;
  String? senderAvatarUrl; // ✅ New field
  String? receiverId;
  String? receiverName;
  String? receiverEmail;
  String? receiverAvatarUrl; // ✅ New field
  bool? isAccepted;
  bool? isRejected;
  DateTime? timestamp;
  DateTime? acceptedAt;
  DateTime? rejectedAt;

  RequestModel({
    this.id,
    this.senderId,
    this.senderName,
    this.senderEmail,
    this.senderAvatarUrl,
    this.receiverId,
    this.receiverName,
    this.receiverEmail,
    this.receiverAvatarUrl,
    this.isAccepted = false,
    this.isRejected = false,
    this.timestamp,
    this.acceptedAt,
    this.rejectedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'senderAvatarUrl': senderAvatarUrl, // ✅ Save to database
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverEmail': receiverEmail,
      'receiverAvatarUrl': receiverAvatarUrl, // ✅ Save to database
      'isAccepted': isAccepted,
      'isRejected': isRejected,
      'timestamp': timestamp?.millisecondsSinceEpoch,
      'acceptedAt': acceptedAt?.millisecondsSinceEpoch,
      'rejectedAt': rejectedAt?.millisecondsSinceEpoch,
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map) {
    return RequestModel(
      id: map['id'] as String?,
      senderId: map['senderId'] as String?,
      senderName: map['senderName'] as String?,
      senderEmail: map['senderEmail'] as String?,
      senderAvatarUrl: map['senderAvatarUrl'] as String?, // ✅ Load from database
      receiverId: map['receiverId'] as String?,
      receiverName: map['receiverName'] as String?,
      receiverEmail: map['receiverEmail'] as String?,
      receiverAvatarUrl: map['receiverAvatarUrl'] as String?, // ✅ Load from database
      isAccepted: map['isAccepted'] as bool? ?? false,
      isRejected: map['isRejected'] as bool? ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : null,
      acceptedAt: map['acceptedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['acceptedAt'] as int)
          : null,
      rejectedAt: map['rejectedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['rejectedAt'] as int)
          : null,
    );
  }

  // Get display name (first name only)
  String get senderFirstName {
    if (senderName == null || senderName!.isEmpty) return 'User';
    return senderName!.split(' ').first;
  }

  String get receiverFirstName {
    if (receiverName == null || receiverName!.isEmpty) return 'User';
    return receiverName!.split(' ').first;
  }

  // Check if avatar is base64
  bool get isSenderAvatarBase64 {
    if (senderAvatarUrl == null || senderAvatarUrl!.isEmpty) return false;
    return !senderAvatarUrl!.startsWith('http') &&
        senderAvatarUrl!.length > 100;
  }

  bool get isReceiverAvatarBase64 {
    if (receiverAvatarUrl == null || receiverAvatarUrl!.isEmpty) return false;
    return !receiverAvatarUrl!.startsWith('http') &&
        receiverAvatarUrl!.length > 100;
  }

  // Get initials for avatar fallback
  String get senderInitials {
    if (senderName == null || senderName!.isEmpty) return 'U';
    final nameParts = senderName!.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return senderName!.isNotEmpty ? senderName![0].toUpperCase() : 'U';
  }

  String get receiverInitials {
    if (receiverName == null || receiverName!.isEmpty) return 'U';
    final nameParts = receiverName!.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return receiverName!.isNotEmpty ? receiverName![0].toUpperCase() : 'U';
  }
}