
import 'user_model.dart';

class ChatUser {
  String uid;
  String name;
  String email;
  String avatarUrl;
  bool isOnline;
  DateTime? lastSeen;
  DateTime createdAt;

  ChatUser({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl = "no",
    this.isOnline = false,
    this.lastSeen,
    required this.createdAt,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'] ?? "no",
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Convert UserModel to ChatUser
  factory ChatUser.fromUserModel(UserModel user) {
    return ChatUser(
      uid: user.uid,
      name: user.name,
      email: user.email ?? '',
      avatarUrl: user.avatarUrl ?? "no",
      isOnline: user.isOnline ?? false,
      lastSeen: user.lastSeen,
      createdAt: user.createdAt ?? DateTime.now(),
    );
  }
}