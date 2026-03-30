import 'package:chat_application/models/user_model.dart';
import 'package:chat_application/models/request_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact_model.dart';
import '../models/message_model.dart';
import 'dart:async';

import '../shared_pref/sharedpref.dart';

class DataBaseService {

  final FirebaseDatabase _database1 = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DatabaseReference get _database => FirebaseDatabase.instance.ref();
  String get currentUserUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<String> get currentUserName async {
    String uid = currentUserUid;
    if (uid.isEmpty) return "";

    DataSnapshot snapshot =
    await FirebaseDatabase.instance.ref("users/$uid/name").get();

    return snapshot.value?.toString() ?? "";
  }

  Future<void> updateUserStatus(bool isOnline) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final updateData = {
          'isOnline': isOnline,
          'lastSeen': isOnline ? null : DateTime.now().toIso8601String(),
          'lastSeenTimestamp': isOnline ? null : DateTime.now().millisecondsSinceEpoch,
        };

        await _database1.ref("users/${currentUser.uid}").update(updateData);
        print('✅ User status updated: $isOnline');
      } else {
        print('⚠️ No current user found, cannot update status');
      }
    } catch (e) {
      print('❌ Error updating user status: $e');
      // Don't rethrow, just log the error
    }
  }

  // Force set user offline (for logout)
  Future<void> forceSetUserOffline() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final updateData = {
          'isOnline': false,
          'lastSeen': DateTime.now().toIso8601String(),
          'lastSeenTimestamp': DateTime.now().millisecondsSinceEpoch,
        };

        await _database1.ref("users/${currentUser.uid}").update(updateData);
        print('✅ User forced offline');
      } else {
        print('⚠️ No current user found, cannot force offline');
      }
    } catch (e) {
      print('❌ Error forcing user offline: $e');
    }
  }

  // Get user status
  Future<Map<String, dynamic>?> getUserStatus(String userId) async {
    try {
      final snapshot = await _database1.ref("users/$userId").once();
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(
            snapshot.snapshot.value as Map<dynamic, dynamic>
        );
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error getting user status: $e');
      return null;
    }
  }


  Stream<List<MessageModel>> getChatSummariesStream() {
    String userId = currentUserUid;
    return FirebaseDatabase.instance
        .ref("ChatSummaries/$userId")
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return [];
      }

      Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      List<MessageModel> chats = [];

      data.forEach((chatId, chatData) {
        if (chatData != null) {
          try {
            Map<String, dynamic> chatMap = Map<String, dynamic>.from(chatData);
            MessageModel chatSummary = MessageModel(
              senderId: chatMap['chatId'] ?? '',
              receverId: userId,
              message: chatMap['lastMessage'] ?? '',
              timestamp: chatMap['lastMessageTime'] ?? 0,
              day: 'Today',
              isSeen: true,
              messageType: chatMap['messageType'] ?? 'text',
              name: chatMap['chatPartnerName'] ?? 'Unknown',
              lastmessage: chatMap['lastMessage'] ?? '',
              time: chatMap['formattedTime'] ?? '',
              unreadCount: chatMap['unreadCount'] ?? 0,
              isOnline: chatMap['isOnline'] ?? false,
              avatarUrl: chatMap['avatarUrl'] ?? "no",
              lastSeen: chatMap['lastSeen'] != null
                  ? DateTime.tryParse(chatMap['lastSeen'].toString())
                  : null,
            );
            chats.add(chatSummary);
          } catch (e) {
            print('Error parsing chat summary: $e');
          }
        }
      });

      // Sort by last message time (newest first)
      chats.sort((a, b) => (b.timestamp as int).compareTo(a.timestamp as int));
      return chats;
    });
  }

  Future<void> saveUser(UserModel user) async {
    await _database.child('users').child(user.uid!).set(user.toJson());
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _database.child('users').get();

    if (!snapshot.exists) {
      return [];
    }
    String myUid = currentUserUid;

    List<UserModel> users = [];

    snapshot.children.forEach((child) {
      try {
        final data = Map<String, dynamic>.from(child.value as Map);
        UserModel user = UserModel.fromJson(data);

        if (user.uid != myUid) {
          users.add(user);
        }
      } catch (e) {
        print("Error parsing user: $e");
      }
    });

    return users;
  }

  Future<String?> getUserThemePreference(String userId) async {
    try {
      final snapshot = await _database.child('users').child(userId).child('themePreference').once();
      if (snapshot.snapshot.value != null) {
        return snapshot.snapshot.value as String;
      }
      return null;
    } catch (e) {
      print('Error getting theme preference: $e');
      return null;
    }
  }

  // Get current user details
  Future<UserModel> getCurrentUser() async {
    try {
      final snapshot = await _database.child('users').child(currentUserUid).get();

      if (!snapshot.exists) {
        throw Exception("Current user not found in database");
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return UserModel.fromJson(data);
    } catch (e) {
      print("Error getting current user: $e");
      rethrow;
    }
  }

  // Check request status between two users - FIXED VERSION
  Future<RequestStatus> checkRequestStatus(String otherUserId) async {
    try {
      final currentUserId = currentUserUid;

      // Query all requests
      final snapshot = await _database.child('requests').get();

      if (!snapshot.exists) {
        return RequestStatus.none;
      }

      // Check all requests between these two users
      for (final child in snapshot.children) {
        final data = Map<String, dynamic>.from(child.value as Map);
        final senderId = data['senderId'] as String?;
        final receiverId = data['receiverId'] as String?;
        final isAccepted = data['isAccepted'] as bool? ?? false;
        final isRejected = data['isRejected'] as bool? ?? false;

        // If current user sent request to other user
        if (senderId == currentUserId && receiverId == otherUserId) {
          if (isAccepted) {
            return RequestStatus.accepted;
          } else if (isRejected) {
            return RequestStatus.rejected;
          } else {
            return RequestStatus.pending;
          }
        }

        // If other user sent request to current user
        if (senderId == otherUserId && receiverId == currentUserId) {
          if (isAccepted) {
            return RequestStatus.accepted;
          } else if (isRejected) {
            return RequestStatus.rejected;
          } else {
            return RequestStatus.received;
          }
        }
      }

      return RequestStatus.none;
    } catch (e) {
      print("Error checking request status: $e");
      return RequestStatus.none;
    }
  }

  Future<void> sendFriendRequest(UserModel receiverUser) async {
    try {
      final senderId = currentUserUid;
      final receiverId = receiverUser.uid!;
      final status = await checkRequestStatus(receiverId);

      if (status == RequestStatus.pending) {
        throw Exception("You already sent a request to ${receiverUser.name}");
      }

      if (status == RequestStatus.accepted) {
        throw Exception("You are already connected with ${receiverUser.name}");
      }

      if (status == RequestStatus.received) {
        throw Exception("${receiverUser.name} has already sent you a request. Check your Friend Requests.");
      }

      if (status == RequestStatus.rejected) {
        await _deleteExistingRequest(senderId, receiverId);
      }

      final senderUser = await getCurrentUser();
      final requestId = _database.child('requests').push().key!;

      // ✅ Get sender's avatar from users node
      String? senderAvatarUrl = "no";
      final senderDataSnapshot = await _database.child('users').child(senderId).get();
      if (senderDataSnapshot.value != null) {
        final senderData = Map<String, dynamic>.from(senderDataSnapshot.value as Map);
        senderAvatarUrl = senderData['avatarUrl']?.toString() ?? "no";
      }

      // ✅ Get receiver's avatar from users node
      String? receiverAvatarUrl = "no";
      final receiverDataSnapshot = await _database.child('users').child(receiverId).get();
      if (receiverDataSnapshot.value != null) {
        final receiverData = Map<String, dynamic>.from(receiverDataSnapshot.value as Map);
        receiverAvatarUrl = receiverData['avatarUrl']?.toString() ?? "no";
      }

      final request = RequestModel(
        id: requestId,
        senderId: senderId,
        senderName: senderUser.name,
        senderEmail: senderUser.email,
        senderAvatarUrl: senderAvatarUrl, // ✅ Sender का Base64 avatar
        receiverId: receiverId,
        receiverName: receiverUser.name,
        receiverEmail: receiverUser.email,
        receiverAvatarUrl: receiverAvatarUrl, // ✅ Receiver का Base64 avatar
        isAccepted: false,
        isRejected: false,
        timestamp: DateTime.now(),
      );

      await _database
          .child('requests')
          .child(requestId)
          .set(request.toMap());

      print("✅ Friend request sent to ${receiverUser.name}");
      print("📸 Sender Avatar (Base64 preview): ${senderAvatarUrl?.substring(0, min(50, senderAvatarUrl?.length ?? 0))}...");
      print("📸 Receiver Avatar (Base64 preview): ${receiverAvatarUrl?.substring(0, min(50, receiverAvatarUrl?.length ?? 0))}...");
    } catch (e) {
      print("❌ Error sending friend request: $e");
      rethrow;
    }
  }

  int min(int a, int b) => a < b ? a : b;

  // Delete existing request between two users
  Future<void> _deleteExistingRequest(String senderId, String receiverId) async {
    try {
      final snapshot = await _database.child('requests').get();

      if (snapshot.exists) {
        for (final child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          final requestSenderId = data['senderId'] as String?;
          final requestReceiverId = data['receiverId'] as String?;

          if (requestSenderId == senderId && requestReceiverId == receiverId) {
            await _database.child('requests').child(child.key!).remove();
            print("Deleted existing request from $senderId to $receiverId");
          }
        }
      }
    } catch (e) {
      print("Error deleting existing request: $e");
    }
  }

  // ✅ Get all friend requests for current user WITH AVATARS
  Future<List<RequestModel>> getFriendRequests() async {
    try {
      final receiverId = currentUserUid;
      if (receiverId.isEmpty) return [];

      final snapshot = await _database
          .child('requests')
          .orderByChild('receiverId')
          .equalTo(receiverId)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      List<RequestModel> requests = [];

      for (final child in snapshot.children) {
        try {
          final data = Map<String, dynamic>.from(child.value as Map);

          if (data['senderId'] != null && data['receiverId'] != null) {
            // ✅ Get sender's avatar from users node
            String? senderAvatarUrl = "no";
            final senderId = data['senderId'] as String;

            final senderSnapshot = await _database.child('users').child(senderId).get();
            if (senderSnapshot.value != null) {
              final senderData = Map<String, dynamic>.from(senderSnapshot.value as Map);
              senderAvatarUrl = senderData['avatarUrl']?.toString() ?? "no";
            }

            // ✅ Get receiver's avatar from users node
            String? receiverAvatarUrl = "no";
            final receiverSnapshot = await _database.child('users').child(receiverId).get();
            if (receiverSnapshot.value != null) {
              final receiverData = Map<String, dynamic>.from(receiverSnapshot.value as Map);
              receiverAvatarUrl = receiverData['avatarUrl']?.toString() ?? "no";
            }

            final request = RequestModel.fromMap({
              ...data,
              'senderAvatarUrl': senderAvatarUrl,
              'receiverAvatarUrl': receiverAvatarUrl,
            });

            // Only get pending requests (not accepted and not rejected)
            if (request.isAccepted == false && request.isRejected == false) {
              requests.add(request);
            }
          }
        } catch (e) {
          print("Error parsing request data: $e");
        }
      }

      // Sort by timestamp (newest first)
      requests.sort((a, b) {
        final timeA = a.timestamp ?? DateTime(1970);
        final timeB = b.timestamp ?? DateTime(1970);
        return timeB.compareTo(timeA);
      });

      return requests;
    } catch (e) {
      print("Error getting friend requests: $e");
      return [];
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final snapshot = await _database.child('users').child(userId).get();

      if (!snapshot.exists) {
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return UserModel.fromJson(data);
    } catch (e) {
      print("Error getting user by ID: $e");
      return null;
    }
  }

  // ✅ Accept friend request and add to contacts WITH AVATARS
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      // First get the request details
      final snapshot = await _database.child('requests').child(requestId).get();

      if (!snapshot.exists) {
        throw Exception("Request not found");
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final request = RequestModel.fromMap(data);

      // Get avatars from the request
      final senderAvatarUrl = request.senderAvatarUrl ?? "no";
      final receiverAvatarUrl = request.receiverAvatarUrl ?? "no";

      // Update request status to accepted
      await _database
          .child('requests')
          .child(requestId)
          .update({
        'isAccepted': true,
        'isRejected': false,
        'acceptedAt': DateTime.now().millisecondsSinceEpoch
      });

      // ✅ Add both users to each other's contacts WITH AVATARS
      await _addToContactsWithAvatars(
          request.senderId!,
          request.senderName!,
          request.senderEmail!,
          senderAvatarUrl,
          request.receiverId!,
          request.receiverName!,
          request.receiverEmail!,
          receiverAvatarUrl
      );

      print("✅ Request $requestId accepted and contacts added with avatars");
    } catch (e) {
      print("Error accepting friend request: $e");
      rethrow;
    }
  }

  // ✅ Reject friend request
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      // Mark request as rejected instead of deleting
      await _database
          .child('requests')
          .child(requestId)
          .update({
        'isRejected': true,
        'rejectedAt': DateTime.now().millisecondsSinceEpoch
      });

      print("Request $requestId marked as rejected");
    } catch (e) {
      print("Error rejecting friend request: $e");
      rethrow;
    }
  }

  // ✅ Add both users to each other's contacts WITH AVATARS
  Future<void> _addToContactsWithAvatars(
      String userId1,
      String userName1,
      String userEmail1,
      String userAvatar1,
      String userId2,
      String userName2,
      String userEmail2,
      String userAvatar2
      ) async {
    try {
      // Get both users' details
      final user1 = await getUserById(userId1);
      final user2 = await getUserById(userId2);

      if (user1 == null || user2 == null) {
        throw Exception("One or both users not found");
      }

      // Create contact entries for both users
      final contactTimestamp = DateTime.now().millisecondsSinceEpoch;
      final contactKey1 = _database.child('contacts').child(userId1).push().key!;
      final contactKey2 = _database.child('contacts').child(userId2).push().key!;

      // ✅ Add user2 to user1's contacts WITH AVATAR
      await _database.child('contacts').child(userId1).child(contactKey1).set({
        'id': contactKey1,
        'userId': userId2,
        'name': userName2,
        'email': userEmail2,
        'avatarUrl': userAvatar2, // ✅ Store receiver's avatar for sender
        'addedAt': contactTimestamp,
      });

      // ✅ Add user1 to user2's contacts WITH AVATAR
      await _database.child('contacts').child(userId2).child(contactKey2).set({
        'id': contactKey2,
        'userId': userId1,
        'name': userName1,
        'email': userEmail1,
        'avatarUrl': userAvatar1, // ✅ Store sender's avatar for receiver
        'addedAt': contactTimestamp,
      });

      print("✅ Contacts added with avatars: $userId1 ↔ $userId2");
    } catch (e) {
      print("Error adding to contacts: $e");
      rethrow;
    }
  }

  // ✅ Get all contacts of current user WITH AVATARS
  Future<List<Contact>> getContacts() async {
    try {
      final userId = currentUserUid;
      if (userId.isEmpty) return [];

      final snapshot = await _database.child('contacts').child(userId).get();

      if (!snapshot.exists) {
        return [];
      }

      List<Contact> contacts = [];

      for (final child in snapshot.children) {
        try {
          final data = Map<String, dynamic>.from(child.value as Map);
          final contact = Contact.fromMap(data);
          contacts.add(contact);
        } catch (e) {
          print("Error parsing contact data: $e");
        }
      }

      // Sort by added time (newest first)
      contacts.sort((a, b) => b.addedAt.compareTo(a.addedAt));

      print("✅ Loaded ${contacts.length} contacts with avatars");
      return contacts;
    } catch (e) {
      print("Error getting contacts: $e");
      return [];
    }
  }

  // ✅ Stream for real-time friend requests WITH AVATARS
  Stream<List<RequestModel>> getFriendRequestsStream() {
    final receiverId = currentUserUid;

    return _database
        .child('requests')
        .orderByChild('receiverId')
        .equalTo(receiverId)
        .onValue
        .asyncMap((event) async {
      if (event.snapshot.value == null) {
        return [];
      }

      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      List<RequestModel> requests = [];

      for (var entry in data.entries) {
        try {
          final requestData = Map<String, dynamic>.from(entry.value as Map);

          // ✅ Get sender's avatar from users node
          String? senderAvatarUrl = "no";
          final senderId = requestData['senderId'] as String?;

          if (senderId != null) {
            final senderSnapshot = await _database.child('users').child(senderId).get();
            if (senderSnapshot.value != null) {
              final senderUserData = Map<String, dynamic>.from(senderSnapshot.value as Map);
              senderAvatarUrl = senderUserData['avatarUrl']?.toString() ?? "no";
            }
          }

          // ✅ Get receiver's avatar from users node
          String? receiverAvatarUrl = "no";
          final receiverSnapshot = await _database.child('users').child(receiverId).get();
          if (receiverSnapshot.value != null) {
            final receiverData = Map<String, dynamic>.from(receiverSnapshot.value as Map);
            receiverAvatarUrl = receiverData['avatarUrl']?.toString() ?? "no";
          }

          final request = RequestModel.fromMap({
            ...requestData,
            'senderAvatarUrl': senderAvatarUrl,
            'receiverAvatarUrl': receiverAvatarUrl,
          });

          // Only include pending requests (not accepted and not rejected)
          if (!request.isAccepted! && !request.isRejected!) {
            requests.add(request);
          }
        } catch (e) {
          print("Error parsing request: $e");
        }
      }

      // Sort by timestamp
      requests.sort((a, b) {
        final timeA = a.timestamp ?? DateTime(1970);
        final timeB = b.timestamp ?? DateTime(1970);
        return timeB.compareTo(timeA);
      });

      return requests;
    });
  }

  // Check if friend request is sent
  Future<bool> isFriendRequestSent(String currentUserId, String targetUserId) async {
    try {
      final snapshot = await _database
          .child('requests')
          .orderByChild('senderId')
          .equalTo(currentUserId)
          .get();

      if (!snapshot.exists) return false;

      for (final child in snapshot.children) {
        final data = Map<String, dynamic>.from(child.value as Map);
        final receiverId = data['receiverId'] as String?;
        final isAccepted = data['isAccepted'] as bool? ?? false;
        final isRejected = data['isRejected'] as bool? ?? false;

        if (receiverId == targetUserId && !isAccepted && !isRejected) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print("Error checking friend request: $e");
      return false;
    }
  }

  // Cancel friend request
  Future<void> cancelFriendRequest(String currentUserId, String targetUserId) async {
    try {
      final snapshot = await _database
          .child('requests')
          .orderByChild('senderId')
          .equalTo(currentUserId)
          .get();

      if (snapshot.exists) {
        for (final child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          final receiverId = data['receiverId'] as String?;

          if (receiverId == targetUserId) {
            await _database.child('requests').child(child.key!).remove();
            print("Friend request cancelled: ${child.key}");
            break;
          }
        }
      }
    } catch (e) {
      print("Error cancelling friend request: $e");
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getSentFriendRequests(String userId) async {
    try {
      DatabaseReference requestsRef = FirebaseDatabase.instance.ref("requests");

      // Query for friend requests where current user is the sender
      DatabaseEvent event = await requestsRef
          .orderByChild("senderId")
          .equalTo(userId)
          .once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> sentRequests = [];

        data.forEach((requestId, requestData) {
          if (requestData != null) {
            Map<String, dynamic> request = Map<String, dynamic>.from(requestData);

            // Add request ID to the request data
            request['requestId'] = requestId.toString();

            // Only include active requests (not cancelled or accepted)
            if (request['status'] == 'pending' || request['status'] == null) {
              sentRequests.add(request);
            }
          }
        });

        print("📤 Sent friend requests loaded: ${sentRequests.length}");
        return sentRequests;
      }

      return [];
    } catch (e) {
      print("❌ Error loading sent friend requests: $e");
      return [];
    }
  }
}

// Enum for request status
enum RequestStatus {
  none,      // No request exists
  pending,   // Request sent (waiting for response)
  received,  // Request received from other user
  accepted,  // Request accepted
  rejected   // Request rejected
}