import 'dart:ui';

import 'package:flutter/material.dart';

class UserModel {
  String uid;
  String name;
  String? mobileNo;
  String? email;
  String? avatarUrl;
  bool? isOnline;
  DateTime? lastSeen;
  DateTime? createdAt;
  String? bio;
  String? status;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    this.email,
    this.mobileNo,
    this.avatarUrl = "no",
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
    this.bio,
    this.status = "Hey there! I'm using ChatApp",
    this.fcmToken,
  });

  // Factory method from JSON (for compatibility)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel.fromMap(json);
  }

  // Factory method from Map (newly added)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Handle different timestamp formats
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;

      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        // Try parsing ISO string
        DateTime? date = DateTime.tryParse(value);
        if (date != null) return date;

        // Try parsing milliseconds from string
        final intValue = int.tryParse(value);
        if (intValue != null) {
          return DateTime.fromMillisecondsSinceEpoch(intValue);
        }
      } else if (value is DateTime) {
        return value;
      }
      return null;
    }

    return UserModel(
      uid: map['uid']?.toString() ?? map['userId']?.toString() ?? '',
      name: map['name']?.toString() ?? map['userName']?.toString() ?? 'Unknown',
      email: map['email']?.toString(),
      mobileNo: map['mobileNo']?.toString(),
      avatarUrl: map['avatarUrl']?.toString() ?? map['profilePic']?.toString() ?? "no",
      isOnline: map['isOnline'] ?? map['online'] ?? false,
      lastSeen: parseDateTime(map['lastSeen']),
      createdAt: parseDateTime(map['createdAt']),
      bio: map['bio']?.toString(),
      status: map['status']?.toString() ?? "Hey there! I'm using ChatApp",
      fcmToken: map['fcmToken']?.toString(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return toMap();
  }

  // Convert to Map (newly added)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'mobileNo':mobileNo,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'bio': bio,
      'status': status,
      'fcmToken': fcmToken,
    };
  }

  // Get display name (first name only)
  String get firstName {
    return name.split(' ').first;
  }

  // Get formatted last seen time
  String get formattedLastSeen {
    if (lastSeen == null) return '';

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}m ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  // Check if user is currently active
  bool get isActive {
    if (isOnline == true) return true;
    if (lastSeen == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);
    return difference.inMinutes < 5; // Active within last 5 minutes
  }

  // Get initials for avatar
  String get initials {
    if (name.isEmpty) return 'U';

    final nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      final firstChar = nameParts[0].isNotEmpty ? nameParts[0][0] : '';
      final secondChar = nameParts[1].isNotEmpty ? nameParts[1][0] : '';
      return '${firstChar}${secondChar}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  // Create copy with method
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? mobileNo,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    String? bio,
    String? status,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      mobileNo:mobileNo ?? this.mobileNo,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  // Check if user is equal to another user
  bool isEqual(UserModel other) {
    return uid == other.uid;
  }

  // Get avatar color based on user ID for consistent colors
  Color get avatarColor {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    final hash = uid.hashCode.abs();
    return colors[hash % colors.length];
  }

  // Get abbreviated status
  String get abbreviatedStatus {
    if (status == null || status!.isEmpty) return '';

    if (status!.length <= 30) return status!;
    return '${status!.substring(0, 27)}...';
  }

  // Get online status text
  String get onlineStatusText {
    if (isOnline == true) return 'Online';
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inMinutes < 5) return 'Active now';
    if (difference.inHours < 1) return 'Active ${difference.inMinutes}m ago';
    if (difference.inDays < 1) return 'Active ${difference.inHours}h ago';

    return 'Offline';
  }
}