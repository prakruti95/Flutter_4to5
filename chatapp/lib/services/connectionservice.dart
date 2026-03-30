import 'package:firebase_database/firebase_database.dart';

class ConnectionService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Add connection between two users
  Future<void> addConnection(String userId1, String userId2) async {
    await _database
        .child('Connections')
        .child(userId1)
        .child(userId2)
        .set({
      'connectedAt': DateTime.now().millisecondsSinceEpoch,
      'status': 'connected'
    });

    await _database
        .child('Connections')
        .child(userId2)
        .child(userId1)
        .set({
      'connectedAt': DateTime.now().millisecondsSinceEpoch,
      'status': 'connected'
    });
  }

  // Remove connection
  Future<void> removeConnection(String userId1, String userId2) async {
    await _database
        .child('Connections')
        .child(userId1)
        .child(userId2)
        .remove();

    await _database
        .child('Connections')
        .child(userId2)
        .child(userId1)
        .remove();
  }

  // Get all connections for a user
  Stream<List<String>> getConnections(String userId) {
    return _database.child('Connections').child(userId).onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return [];

      return data.keys.cast<String>().toList();
    });
  }

  // Get connection details between two users
  Future<Map<String, dynamic>?> getConnectionDetails(String userId1, String userId2) async {
    try {
      final snapshot = await _database
          .child('Connections')
          .child(userId1)
          .child(userId2)
          .get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      print('Error getting connection details: $e');
      return null;
    }
  }

  // Check if two users are connected
  Future<bool> areUsersConnected(String userId1, String userId2) async {
    try {
      final snapshot = await _database
          .child('Connections')
          .child(userId1)
          .child(userId2)
          .get();

      return snapshot.exists;
    } catch (e) {
      print('Error checking connection: $e');
      return false;
    }
  }

  // Get all connected users with details
  Stream<List<Map<String, dynamic>>> getConnectedUsersWithDetails(String userId) {
    return _database.child('Connections').child(userId).onValue.asyncMap((event) async {
      final Map<dynamic, dynamic>? connections = event.snapshot.value as Map?;
      if (connections == null) return [];

      List<Map<String, dynamic>> connectedUsers = [];

      for (final connectedUserId in connections.keys) {
        try {
          // Get user details
          final userSnapshot = await _database
              .child('users')
              .child(connectedUserId.toString())
              .get();

          if (userSnapshot.exists) {
            final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
            final connectionData = Map<String, dynamic>.from(connections[connectedUserId]);

            connectedUsers.add({
              'userId': connectedUserId.toString(),
              'userData': userData,
              'connectionData': connectionData,
            });
          }
        } catch (e) {
          print('Error getting user details: $e');
        }
      }

      return connectedUsers;
    });
  }

  // Get connection count for a user
  Stream<int> getConnectionCount(String userId) {
    return _database.child('Connections').child(userId).onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return 0;

      return data.length;
    });
  }

  // Search users in connections
  Future<List<Map<String, dynamic>>> searchInConnections(String userId, String query) async {
    try {
      final snapshot = await _database
          .child('Connections')
          .child(userId)
          .get();

      if (!snapshot.exists) return [];

      final connections = Map<String, dynamic>.from(snapshot.value as Map);
      List<Map<String, dynamic>> results = [];

      for (final connectedUserId in connections.keys) {
        try {
          // Get user details
          final userSnapshot = await _database
              .child('users')
              .child(connectedUserId.toString())
              .get();

          if (userSnapshot.exists) {
            final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
            final userName = userData['name']?.toString().toLowerCase() ?? '';

            if (userName.contains(query.toLowerCase())) {
              results.add({
                'userId': connectedUserId.toString(),
                'userData': userData,
              });
            }
          }
        } catch (e) {
          print('Error searching in connections: $e');
        }
      }

      return results;
    } catch (e) {
      print('Error searching connections: $e');
      return [];
    }
  }

// Add this method to your ConnectionService class

  Future<List<String>> getUserConnections(String userId) async {
    try {
      print("🔄 Loading connections for user: $userId");

      // Reference to user's connections in Firebase
      DatabaseReference connectionsRef = FirebaseDatabase.instance
          .ref("connections")
          .child(userId);

      DatabaseEvent event = await connectionsRef.once();

      if (event.snapshot.exists && event.snapshot.value != null) {
        // Check if the value is a Map or a List
        final dynamic connectionsData = event.snapshot.value;

        List<String> connections = [];

        if (connectionsData is Map) {
          // If it's a Map (Firebase stores as key-value pairs)
          Map<dynamic, dynamic> connectionsMap = connectionsData;

          connectionsMap.forEach((key, value) {
            if (key != null && key.toString().isNotEmpty) {
              // Check if this is a valid connection (value can be true, timestamp, etc.)
              if (value != null && value != false) {
                connections.add(key.toString());
                print("   ✅ Connection found: ${key.toString().substring(0, 8)}");
              }
            }
          });
        } else if (connectionsData is List) {
          // If it's a List (less common in Firebase but possible)
          List<dynamic> connectionsList = connectionsData;

          for (var connectionId in connectionsList) {
            if (connectionId != null && connectionId.toString().isNotEmpty) {
              connections.add(connectionId.toString());
              print("   ✅ Connection found: ${connectionId.toString().substring(0, 8)}");
            }
          }
        }

        print("✅ Total connections loaded: ${connections.length}");
        return connections;
      } else {
        print("ℹ️ No connections found for user: $userId");
        return [];
      }
    } catch (e) {
      print("❌ Error loading user connections: $e");
      print("📋 Stack trace: ${e.toString()}");
      return [];
    }
  }

  Future<void> acceptConnectionRequest(String senderId, String receiverId) async {
    try {
      final database = FirebaseDatabase.instance;

      // 1. Add to connections (both ways)
      await Future.wait([
        database.ref("connections/$senderId/$receiverId").set(true),
        database.ref("connections/$receiverId/$senderId").set(true),
      ]);

      // 2. Add to contacts (both ways with auto-generated keys)
      await Future.wait([
        // Add receiver to sender's contacts
        database.ref("contacts/$senderId").push().set({
          'contactId': receiverId,
          'addedAt': ServerValue.timestamp,
          'acceptedAt': ServerValue.timestamp,
        }),

        // Add sender to receiver's contacts
        database.ref("contacts/$receiverId").push().set({
          'contactId': senderId,
          'addedAt': ServerValue.timestamp,
          'acceptedAt': ServerValue.timestamp,
        }),
      ]);

      // 3. Delete the request from requests node
      await _deleteRequest(senderId, receiverId);

      print("✅ Connection accepted: $senderId and $receiverId are now connected");

    } catch (e) {
      print("❌ Error accepting connection request: $e");
      throw e;
    }
  }

  Future<void> _deleteRequest(String senderId, String receiverId) async {
    try {
      final database = FirebaseDatabase.instance;
      final requestsRef = database.ref("requests");

      final query = requestsRef.orderByChild("senderId").equalTo(senderId);
      final event = await query.once();
      final snapshot = event.snapshot;

      if (snapshot.value != null) {
        final allRequests = Map<String, dynamic>.from(snapshot.value as Map);

        for (var requestId in allRequests.keys) {
          final requestData = allRequests[requestId];
          if (requestData != null) {
            final data = Map<String, dynamic>.from(requestData);
            final reqReceiverId = data['receiverId']?.toString();

            if (reqReceiverId == receiverId) {
              await requestsRef.child(requestId).remove();
              print("🗑️ Deleted request: $requestId");
              return;
            }
          }
        }
      }
    } catch (e) {
      print("Error deleting request: $e");
    }
  }
}