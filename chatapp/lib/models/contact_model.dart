class Contact {
  String? id;
  String? userId;
  String? name;
  String? email;
  String? profilePic;
  String? avatarUrl;
  int addedAt;

  Contact({
    this.id,
    this.userId,
    this.name,
    this.email,
    this.profilePic,
    this.avatarUrl,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'profilePic': profilePic,
      'avatarUrl': avatarUrl,
      'addedAt': addedAt,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as String?,
      userId: map['userId'] as String?,
      name: map['name'] as String?,
      email: map['email'] as String?,
      profilePic: map['profilePic'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      addedAt: map['addedAt'] as int,
    );
  }

  DateTime get addedDate => DateTime.fromMillisecondsSinceEpoch(addedAt);

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(addedDate);

    if (difference.inMinutes < 1) return "Just now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    if (difference.inDays < 7) return "${difference.inDays}d ago";
    return "${difference.inDays ~/ 7}w ago";
  }
}