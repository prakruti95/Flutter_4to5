import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:chat_application/services/database_service.dart';
import 'package:chat_application/services/auth_service.dart';
import 'package:chat_application/models/user_model.dart';
import '../services/connectionservice.dart';
import 'request_user.dart';
import 'chat_screen.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  List<UserModel> users = [];
  Map<String, ConnectionStatus> connectionStatusMap = {};
  Map<String, bool> requestStatusMap = {};
  Map<String, bool> isLoadingMap = {};
  bool isInitialLoading = true;
  bool isRefreshing = false;
  final DataBaseService _dbService = DataBaseService();
  final ConnectionService _connectionService = ConnectionService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> filteredUsers = [];
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();

  // Stream subscriptions for real-time updates
  StreamSubscription? _connectionsSubscription;
  StreamSubscription? _requestsSubscription;
  StreamSubscription? _contactsSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
    _setupRealTimeListeners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _connectionsSubscription?.cancel();
    _requestsSubscription?.cancel();
    _contactsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealTimeListeners() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    // Listen for contacts changes - BOTH SIDES
    final contactsRef = FirebaseDatabase.instance.ref("contacts/${currentUser.uid}");
    _contactsSubscription = contactsRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final contacts = Map<String, dynamic>.from(event.snapshot.value as Map);
        _updateConnectionStatusFromContacts(contacts);
      } else {
        // If contacts node is empty, update all to none
        _resetConnectionStatus();
      }
    });

    // Listen for connection changes - BOTH SIDES
    final connectionsRef = FirebaseDatabase.instance.ref("connections/${currentUser.uid}");
    _connectionsSubscription = connectionsRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final connections = Map<String, dynamic>.from(event.snapshot.value as Map);
        _updateConnectionStatusFromRealTime(connections);
      } else {
        // If connections node is empty, update all to none
        _resetConnectionStatus();
      }
    });

    // Listen for incoming connections (when someone accepts our request)
    final incomingConnectionsRef = FirebaseDatabase.instance.ref("connections").orderByKey().equalTo(currentUser.uid);
    _connectionsSubscription = incomingConnectionsRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final connections = Map<String, dynamic>.from(event.snapshot.value as Map);
        _updateConnectionStatusFromRealTime(connections);
      }
    });

    // Listen for outgoing request changes
    final requestsRef = FirebaseDatabase.instance.ref("requests").orderByChild("senderId").equalTo(currentUser.uid);
    _requestsSubscription = requestsRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final requests = Map<String, dynamic>.from(event.snapshot.value as Map);
        _updateRequestStatusFromRealTime(requests);
      } else {
        // If no requests, reset all
        _resetRequestStatus();
      }
    });

    // Also listen for incoming requests (when someone sends us request)
    final incomingRequestsRef = FirebaseDatabase.instance.ref("requests").orderByChild("receiverId").equalTo(currentUser.uid);
    incomingRequestsRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        // Just trigger a reload to update UI
        _loadData();
      }
    });
  }
  void _updateConnectionStatusFromContacts(Map<String, dynamic> contacts) {
    setState(() {
      // First reset all to none
      for (var userId in connectionStatusMap.keys) {
        connectionStatusMap[userId] = ConnectionStatus.none;
        requestStatusMap[userId] = false;
      }

      // Then check each contact
      contacts.forEach((autoKey, contactData) {
        if (contactData != null) {
          try {
            final data = Map<String, dynamic>.from(contactData);

            // Extract contact ID
            final contactId = data['contactId']?.toString() ??
                data['userId']?.toString() ??
                data['uid']?.toString() ??
                data['id']?.toString();

            if (contactId != null && connectionStatusMap.containsKey(contactId)) {
              connectionStatusMap[contactId] = ConnectionStatus.connected;
              requestStatusMap[contactId] = false; // Clear request status
              print("✅ Contact connected: $contactId");
            }
          } catch (e) {
            print("Error parsing contact: $e");
          }
        }
      });
    });
  }
  void _resetConnectionStatus() {
    setState(() {
      for (var userId in connectionStatusMap.keys) {
        connectionStatusMap[userId] = ConnectionStatus.none;
      }
    });
  }

  void _resetRequestStatus() {
    setState(() {
      for (var userId in requestStatusMap.keys) {
        requestStatusMap[userId] = false;
      }
    });
  }

  void _updateConnectionStatusFromRealTime(Map<String, dynamic> connections) {
    setState(() {
      // First reset all to none
      for (var userId in connectionStatusMap.keys) {
        connectionStatusMap[userId] = ConnectionStatus.none;
      }

      // Then set connected users
      for (var userId in connections.keys) {
        if (connectionStatusMap.containsKey(userId)) {
          connectionStatusMap[userId] = ConnectionStatus.connected;
          requestStatusMap[userId] = false; // Clear request status if connected
        }
      }
    });
  }

  void _updateRequestStatusFromRealTime(Map<String, dynamic> requests) {
    setState(() {
      // Reset all request status first
      for (var userId in requestStatusMap.keys) {
        requestStatusMap[userId] = false;
      }

      // Update pending requests
      for (var requestId in requests.keys) {
        final request = requests[requestId] as Map<String, dynamic>;
        final receiverId = request['receiverId']?.toString();
        if (receiverId != null && connectionStatusMap.containsKey(receiverId)) {
          // Only set as pending if not already connected
          if (connectionStatusMap[receiverId] != ConnectionStatus.connected) {
            connectionStatusMap[receiverId] = ConnectionStatus.pending;
            requestStatusMap[receiverId] = true;
          }
        }
      }
    });
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _filterUsers();
    });
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => filteredUsers = users);
    } else {
      setState(() {
        filteredUsers = users.where((user) {
          return user.name.toLowerCase().contains(query) ||
              (user.email?.toLowerCase().contains(query) ?? false) ||
              (user.mobileNo?.toLowerCase().contains(query) ?? false);
        }).toList();
      });
    }
  }

  Future<void> _checkAndUpdateConnectionStatus(String currentUserId) async {
    try {
      final database = FirebaseDatabase.instance;

      // Check connections
      final connectionsRef = database.ref("connections/$currentUserId");
      final connectionsSnapshot = await connectionsRef.once();

      if (connectionsSnapshot.snapshot.value != null) {
        final connections = Map<String, dynamic>.from(
            connectionsSnapshot.snapshot.value as Map
        );

        setState(() {
          for (var user in users) {
            if (connections.containsKey(user.uid)) {
              connectionStatusMap[user.uid] = ConnectionStatus.connected;
              requestStatusMap[user.uid] = false;
            }
          }
        });
      }

      // Check contacts
      final contacts = await _getUserContacts(currentUserId);
      setState(() {
        for (var user in users) {
          if (contacts.contains(user.uid)) {
            connectionStatusMap[user.uid] = ConnectionStatus.connected;
            requestStatusMap[user.uid] = false;
          }
        }
      });

      // Check pending requests
      final requests = await _dbService.getSentFriendRequests(currentUserId);
      setState(() {
        for (var request in requests) {
          final receiverId = request['receiverId'];
          if (receiverId != null && connectionStatusMap.containsKey(receiverId)) {
            // Only set as pending if not already connected
            if (connectionStatusMap[receiverId] != ConnectionStatus.connected) {
              connectionStatusMap[receiverId] = ConnectionStatus.pending;
              requestStatusMap[receiverId] = true;
            }
          }
        }
      });

    } catch (e) {
      print("Error checking connection status: $e");
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        if (!isInitialLoading) {
          isRefreshing = true;
        }
      });

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        setState(() {
          isInitialLoading = false;
          isRefreshing = false;
        });
        return;
      }

      final allUsers = await _dbService.getAllUsers();
      final filteredList = allUsers.where((user) => user.uid != currentUser.uid).toList();

      setState(() {
        users = filteredList;
        filteredUsers = filteredList;

        // Initialize status maps
        for (var user in users) {
          isLoadingMap.putIfAbsent(user.uid, () => false);
          connectionStatusMap.putIfAbsent(user.uid, () => ConnectionStatus.none);
          requestStatusMap.putIfAbsent(user.uid, () => false);
        }
      });

      // Use single method to check all statuses
      await _checkAndUpdateConnectionStatus(currentUser.uid);

    } catch (e) {
      print("Error loading users: $e");
      _showSnackBar(
        "Error loading users: ${e.toString()}",
        Icons.error,
        Colors.red,
      );
    }

    setState(() {
      isInitialLoading = false;
      isRefreshing = false;
    });
  }
  void _forceStatusUpdate() {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      // Small delay to ensure Firebase updates are processed
      Future.delayed(Duration(milliseconds: 500), () {
        _checkAndUpdateConnectionStatus(currentUser.uid);
      });
    }
  }
  Future<void> _loadContacts(String currentUserId) async {
    try {
      final contacts = await _getUserContacts(currentUserId);

      setState(() {
        for (var user in users) {
          if (contacts.contains(user.uid)) {
            connectionStatusMap[user.uid] = ConnectionStatus.connected;
            requestStatusMap[user.uid] = false;
          } else {
            // Ensure not connected users are not marked as connected
            if (connectionStatusMap[user.uid] == ConnectionStatus.connected) {
              connectionStatusMap[user.uid] = ConnectionStatus.none;
            }
          }
        }
      });
    } catch (e) {
      print("Error loading contacts: $e");
    }
  }

  Future<List<String>> _getUserContacts(String userId) async {
    try {
      final contactsRef = FirebaseDatabase.instance.ref("contacts/$userId");
      final snapshot = await contactsRef.once();

      if (snapshot.snapshot.value != null) {
        final contacts = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        List<String> contactIds = [];

        contacts.forEach((autoKey, contactData) {
          if (contactData != null) {
            try {
              final data = Map<String, dynamic>.from(contactData);

              // Extract contact ID from different possible field names
              final contactId = data['contactId']?.toString() ??
                  data['userId']?.toString() ??
                  data['uid']?.toString() ??
                  data['id']?.toString();

              if (contactId != null && contactId.isNotEmpty) {
                contactIds.add(contactId);
              }
            } catch (e) {
              print("Error parsing contact: $e");
            }
          }
        });

        print("📞 Found ${contactIds.length} contacts for user $userId");
        return contactIds;
      }
      return [];
    } catch (e) {
      print("Error getting contacts: $e");
      return [];
    }
  }
  Future<void> _loadConnections(String currentUserId) async {
    try {
      final connections = await _connectionService.getUserConnections(currentUserId);

      setState(() {
        for (var user in users) {
          if (connections.contains(user.uid)) {
            connectionStatusMap[user.uid] = ConnectionStatus.connected;
            requestStatusMap[user.uid] = false;
          } else {
            // Ensure not connected users are not marked as connected
            if (connectionStatusMap[user.uid] == ConnectionStatus.connected) {
              connectionStatusMap[user.uid] = ConnectionStatus.none;
            }
          }
        }
      });
    } catch (e) {
      print("Error loading connections: $e");
    }
  }

  Future<void> _loadFriendRequests(String currentUserId) async {
    try {
      final requests = await _dbService.getSentFriendRequests(currentUserId);

      setState(() {
        for (var request in requests) {
          final receiverId = request['receiverId'];
          if (receiverId != null && connectionStatusMap.containsKey(receiverId)) {
            if (connectionStatusMap[receiverId] != ConnectionStatus.connected) {
              connectionStatusMap[receiverId] = ConnectionStatus.pending;
              requestStatusMap[receiverId] = true;
            }
          }
        }
      });
    } catch (e) {
      print("Error loading friend requests: $e");
    }
  }

  Future<void> _sendConnectionRequest(UserModel user) async {
    if (requestStatusMap[user.uid] == true ||
        connectionStatusMap[user.uid] == ConnectionStatus.pending ||
        connectionStatusMap[user.uid] == ConnectionStatus.connected) {
      return;
    }

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Show loading for this specific user
      setState(() {
        isLoadingMap[user.uid] = true;
      });

      // Send friend request
      await _dbService.sendFriendRequest(user);

      // Update state
      setState(() {
        connectionStatusMap[user.uid] = ConnectionStatus.pending;
        requestStatusMap[user.uid] = true;
        isLoadingMap[user.uid] = false;
      });

      _showSnackBar(
        "✅ Friend request sent to ${user.name}!",
        Icons.check_circle,
        Colors.green,
      );

    } catch (e) {
      print("❌ Error in _sendConnectionRequest: $e");
      setState(() {
        isLoadingMap[user.uid] = false;
      });

      if (e.toString().contains("already sent")) {
        _showSnackBar(
          "Request already sent to ${user.name}!",
          Icons.info,
          Colors.orange,
        );
      } else if (e.toString().contains("already connected")) {
        setState(() {
          connectionStatusMap[user.uid] = ConnectionStatus.connected;
          requestStatusMap[user.uid] = false;
        });
        _showSnackBar(
          "Already connected with ${user.name}!",
          Icons.check_circle,
          Colors.green,
        );
      } else {
        _showSnackBar(
          "Failed to send request",
          Icons.error,
          Colors.red,
        );
      }
    }
  }

  Future<void> _cancelFriendRequest(UserModel user) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Show loading for this specific user
      setState(() {
        isLoadingMap[user.uid] = true;
      });

      await _dbService.cancelFriendRequest(currentUser.uid, user.uid);

      // Update state
      setState(() {
        connectionStatusMap[user.uid] = ConnectionStatus.none;
        requestStatusMap[user.uid] = false;
        isLoadingMap[user.uid] = false;
      });

      _showSnackBar(
        "Friend request cancelled for ${user.name}",
        Icons.cancel,
        Colors.orange,
      );
    } catch (e) {
      print("❌ Error cancelling request: $e");
      setState(() {
        isLoadingMap[user.uid] = false;
      });

      _showSnackBar(
        "Error cancelling request",
        Icons.error,
        Colors.red,
      );
    }
  }

  Future<void> _removeConnection(UserModel user) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Show loading for this specific user
      setState(() {
        isLoadingMap[user.uid] = true;
      });

      // COMPREHENSIVE CLEANUP - ALL NODES INCLUDING CONTACTS AND REQUESTS
      await _deleteAllNodesBetweenUsers(currentUser.uid, user.uid);

      // Update state
      setState(() {
        connectionStatusMap[user.uid] = ConnectionStatus.none;
        requestStatusMap[user.uid] = false;
        isLoadingMap[user.uid] = false;
      });

      _showSnackBar(
        "✅ Complete connection removed with ${user.name}",
        Icons.person_remove,
        Colors.orange,
      );
    } catch (e) {
      print("❌ Error removing connection: $e");
      setState(() {
        isLoadingMap[user.uid] = false;
      });

      _showSnackBar(
        "Error removing connection",
        Icons.error,
        Colors.red,
      );
    }
  }

  Future<void> _deleteAllNodesBetweenUsers(String userId1, String userId2) async {
    try {
      final database = FirebaseDatabase.instance;

      print("🧹 STARTING COMPLETE CLEANUP between $userId1 and $userId2");

      // 1. Delete contacts with auto-generated keys
      await _deleteContactsWithAutoKeys(userId1, userId2);

      // 2. Delete connections nodes (BOTH WAYS)
      await Future.wait([
        database.ref("connections/$userId1/$userId2").remove(),
        database.ref("connections/$userId2/$userId1").remove(),
      ]);
      print("✅ Connections nodes deleted");

      // 3. Delete chat messages (BOTH WAYS)
      await Future.wait([
        database.ref("Chats/$userId1/$userId2").remove(),
        database.ref("Chats/$userId2/$userId1").remove(),
      ]);
      print("✅ Chat messages deleted");

      // 4. Delete chat summaries (BOTH WAYS)
      await Future.wait([
        database.ref("ChatSummaries/$userId1/$userId2").remove(),
        database.ref("ChatSummaries/$userId2/$userId1").remove(),
      ]);
      print("✅ Chat summaries deleted");

      // 5. Delete ALL friend requests between users
      await _deleteAllFriendRequests(userId1, userId2);

      // 6. Delete any other related nodes
      await Future.wait([
        // Block lists
        database.ref("users/$userId1/blocked/$userId2").remove(),
        database.ref("users/$userId2/blocked/$userId1").remove(),
        // Friends lists
        database.ref("users/$userId1/friends/$userId2").remove(),
        database.ref("users/$userId2/friends/$userId1").remove(),
      ]);

      print("✅ COMPLETE: All nodes deleted between $userId1 and $userId2");

    } catch (e) {
      print("❌ Error in deleteAllNodesBetweenUsers: $e");
      throw e;
    }
  }
  Future<void> _deleteContactsWithAutoKeys(String userId1, String userId2) async {
    try {
      final database = FirebaseDatabase.instance;

      print("🔍 Searching for contacts between $userId1 and $userId2");

      // Delete contacts from user1's list where contact is user2
      await _deleteContactFromUserList(userId1, userId2);

      // Delete contacts from user2's list where contact is user1
      await _deleteContactFromUserList(userId2, userId1);

    } catch (e) {
      print("❌ Error deleting contacts: $e");
      throw e;
    }
  }
  Future<void> _deleteContactFromUserList(String userId, String contactId) async {
    try {
      final database = FirebaseDatabase.instance;
      final userContactsRef = database.ref("contacts/$userId");

      // Get all contacts of this user
      final snapshot = await userContactsRef.once();

      if (snapshot.snapshot.value != null) {
        final contacts = Map<String, dynamic>.from(snapshot.snapshot.value as Map);

        List<Future> deleteOperations = [];

        contacts.forEach((autoKey, contactData) {
          if (contactData != null) {
            try {
              final data = Map<String, dynamic>.from(contactData);

              // Check different possible field names for contact ID
              final contactUserId = data['contactId']?.toString() ??
                  data['userId']?.toString() ??
                  data['uid']?.toString() ??
                  data['id']?.toString();

              if (contactUserId == contactId) {
                print("🗑️ Found contact with auto-key: $autoKey ($contactUserId)");
                deleteOperations.add(userContactsRef.child(autoKey).remove());
              }
            } catch (e) {
              print("⚠️ Error parsing contact data: $e");
            }
          }
        });

        if (deleteOperations.isNotEmpty) {
          await Future.wait(deleteOperations);
          print("✅ Deleted ${deleteOperations.length} contacts from $userId's list");
        } else {
          print("ℹ️ No matching contacts found in $userId's list");
        }
      } else {
        print("ℹ️ No contacts found for user: $userId");
      }

    } catch (e) {
      print("❌ Error in _deleteContactFromUserList: $e");
      throw e;
    }
  }
  Future<void> _deleteAllFriendRequests(String userId1, String userId2) async {
    try {
      final database = FirebaseDatabase.instance;
      final requestsRef = database.ref("requests");

      print("🔍 Searching for requests between $userId1 and $userId2");

      // Query all requests
      DatabaseEvent event = await requestsRef.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        final allRequests = Map<String, dynamic>.from(snapshot.value as Map);

        List<Future> deleteOperations = [];
        int requestCount = 0;

        allRequests.forEach((requestId, requestData) {
          if (requestData != null) {
            try {
              final data = Map<String, dynamic>.from(requestData);
              final senderId = data['senderId']?.toString();
              final receiverId = data['receiverId']?.toString();

              print("   Checking request $requestId: $senderId -> $receiverId");

              // Check if this request is between our two users (in either direction)
              if ((senderId == userId1 && receiverId == userId2) ||
                  (senderId == userId2 && receiverId == userId1)) {
                deleteOperations.add(requestsRef.child(requestId).remove());
                requestCount++;
                print("     ✅ Marked for deletion");
              }
            } catch (e) {
              print("     ⚠️ Error parsing request $requestId: $e");
            }
          }
        });

        if (deleteOperations.isNotEmpty) {
          print("🗑️ Deleting $requestCount friend requests...");
          await Future.wait(deleteOperations);
          print("✅ $requestCount friend requests deleted successfully");
        } else {
          print("ℹ️ No matching friend requests found to delete");
        }
      } else {
        print("ℹ️ 'requests' node is empty or doesn't exist");
      }

    } catch (e) {
      print("❌ Error in _deleteAllFriendRequests: $e");
      throw e;
    }
  }
  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildUserCard(UserModel user, Size screenSize) {
    final status = connectionStatusMap[user.uid] ?? ConnectionStatus.none;
    final isLoading = isLoadingMap[user.uid] ?? false;
    final bool isSmallScreen = screenSize.width < 360;
    final bool isTablet = screenSize.width > 600;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 8 : 12,
        ),
        leading: _buildUserAvatar(user, screenSize),
        title: Text(
          user.name,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email ?? 'No email',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (user.mobileNo != null && user.mobileNo!.isNotEmpty)
              Text(
                user.mobileNo!,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  color: Colors.grey.shade500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: isLoading
            ? SizedBox(
          width: isSmallScreen ? 24 : 32,
          height: isSmallScreen ? 24 : 32,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).primaryColor,
          ),
        )
            : _buildActionButton(user, status, screenSize),
        onTap: () {
          if (status == ConnectionStatus.connected) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  user: UserModel(
                    uid: user.uid,
                    name: user.name,
                    email: user.email,
                    isOnline: false,
                    avatarUrl: user.avatarUrl,
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildUserAvatar(UserModel user, Size screenSize) {
    final bool isSmallScreen = screenSize.width < 360;
    final bool isTablet = screenSize.width > 600;
    final avatarSize = isSmallScreen ? 40 : (isTablet ? 60 : 48);

    final hasValidAvatar = user.avatarUrl != null &&
        user.avatarUrl!.isNotEmpty &&
        user.avatarUrl! != "no";

    if (!hasValidAvatar) {
      return Container(
        width: avatarSize.toDouble(),
        height: avatarSize.toDouble(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        ),
        child: Center(
          child: Text(
            user.initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 16 : (isTablet ? 24 : 20),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      width: avatarSize.toDouble(),
      height: avatarSize.toDouble(),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        child: _buildAvatarImage(user.avatarUrl!),
      ),
    );
  }

  Widget _buildAvatarImage(String avatarUrl) {
    try {
      // Check if it's a network URL
      if (avatarUrl.startsWith('http')) {
        return Image.network(
          avatarUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: Center(
                child: Icon(
                  Icons.person,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ),
            );
          },
        );
      }

      // Check if it's base64
      try {
        String cleanBase64 = avatarUrl;
        if (avatarUrl.contains(',')) {
          cleanBase64 = avatarUrl.split(',').last;
        }

        Uint8List bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: Center(
                child: Icon(
                  Icons.person,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Colors.grey.shade200,
          child: Center(
            child: Icon(
              Icons.person,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ),
        );
      }
    } catch (e) {
      return Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.person,
            color: Colors.grey.shade400,
            size: 24,
          ),
        ),
      );
    }
  }

  Widget _buildActionButton(UserModel user, ConnectionStatus status, Size screenSize) {
    final bool isSmallScreen = screenSize.width < 360;
    final iconSize = isSmallScreen ? 16 : 20;
    final fontSize = isSmallScreen ? 10 : 12;

    final bool isRequestSent = requestStatusMap[user.uid] == true;

    // Connect Button
    if (status == ConnectionStatus.none && !isRequestSent) {
      return ElevatedButton.icon(
        onPressed: isLoadingMap[user.uid] == true
            ? null
            : () => _sendConnectionRequest(user),
        icon: Icon(Icons.person_add_alt_1, size: iconSize.toDouble()),
        label: Text("Connect", style: TextStyle(fontSize: fontSize.toDouble())),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }

    // Pending State
    if (status == ConnectionStatus.pending || isRequestSent) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: const [
                Icon(Icons.schedule, size: 16, color: Colors.orange),
                SizedBox(width: 4),
                Text("Pending", style: TextStyle(color: Colors.orange)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _showCancelRequestDialog(user),
            child: const Icon(Icons.close, color: Colors.grey),
          )
        ],
      );
    }

    // Connected
    if (status == ConnectionStatus.connected) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text("Connected", style: TextStyle(color: Colors.green)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _showRemoveConnectionDialog(user),
            child: const Icon(Icons.close, color: Colors.red),
          )
        ],
      );
    }

    return const SizedBox();
  }

  void _showCancelRequestDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Friend Request"),
        content: Text("Are you sure you want to cancel the friend request sent to ${user.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelFriendRequest(user);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRemoveConnectionDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ Complete Connection Removal"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Remove ALL connection data with ${user.name}?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Text(
              "This will delete EVERYTHING:",
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint("📱 Contacts node (both users)"),
            _buildBulletPoint("🔗 Connections node (both users)"),
            _buildBulletPoint("📨 All friend requests (sent/received)"),
            _buildBulletPoint("💬 All chat history"),
            _buildBulletPoint("📋 Chat summaries"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                "This action is PERMANENT and cannot be undone!",
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeConnection(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_forever, size: 18),
                SizedBox(width: 8),
                Text("Delete Everything"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("• ", style: TextStyle(color: Colors.red)),
            Expanded(child: Text(text, style: TextStyle(color: Colors.red.shade700))),
          ],
        )
        );
    }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    final bool isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Contacts",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : (isTablet ? 26 : 22),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: isSmallScreen ? 20 : (isTablet ? 28 : 24),
            ),
            onPressed: _loadData,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[50],
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search contacts...",
                    hintStyle: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: isSmallScreen ? 18 : 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _filterUsers();
                      },
                    )
                        : null,
                  ),
                ),
              ),
            ),

            // Status Indicators
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 4 : 8,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusIndicator(
                      "Connect",
                      Theme.of(context).primaryColor,
                      Icons.person_add,
                      screenSize,
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    _buildStatusIndicator(
                      "Pending",
                      Colors.orange,
                      Icons.schedule,
                      screenSize,
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    _buildStatusIndicator(
                      "Connected",
                      Colors.green,
                      Icons.check_circle,
                      screenSize,
                    ),
                  ],
                ),
              ),
            ),

            // User Count
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 4 : 8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: isSmallScreen ? 16 : 18,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: isSmallScreen ? 6 : 8),
                  Expanded(
                    child: Text(
                      "${filteredUsers.length} users found",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isRefreshing)
                    SizedBox(
                      width: isSmallScreen ? 16 : 20,
                      height: isSmallScreen ? 16 : 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                ],
              ),
            ),

            // Users List
            Expanded(
              child: isInitialLoading
                  ? _buildLoadingState(screenSize)
                  : filteredUsers.isEmpty
                  ? _buildEmptyState(screenSize)
                  : RefreshIndicator(
                onRefresh: _loadData,
                color: Theme.of(context).primaryColor,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    return _buildUserCard(filteredUsers[index], screenSize);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RequestUserList(),
            ),
          );
        },
        icon: Icon(
          Icons.notifications,
          size: isSmallScreen ? 18 : 20,
        ),
        label: Text(
          "Requests",
          style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        heroTag: "friend_requests",
      ),
    );
  }

  Widget _buildStatusIndicator(String label, Color color, IconData icon, Size screenSize) {
    final bool isSmallScreen = screenSize.width < 360;

    return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 10,
          vertical: isSmallScreen ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isSmallScreen ? 12 : 14, color: color),
            SizedBox(width: isSmallScreen ? 2 : 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
    );
  }

  Widget _buildLoadingState(Size screenSize) {
    final bool isSmallScreen = screenSize.width < 360;
    final bool isTablet = screenSize.width > 600;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            "Loading contacts...",
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Size screenSize) {
    final bool isSmallScreen = screenSize.width < 360;
    final bool isTablet = screenSize.width > 600;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: isSmallScreen ? 60 : (isTablet ? 100 : 80),
                color: Colors.grey.shade300,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                _searchController.text.isEmpty
                    ? "No contacts found"
                    : "No contacts match '${_searchController.text}'",
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : (isTablet ? 22 : 18),
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                _searchController.text.isEmpty
                    ? "All registered users will appear here"
                    : "Try a different search term",
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : (isTablet ? 16 : 14),
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              if (_searchController.text.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _filterUsers();
                  },
                  icon: Icon(
                    Icons.clear_all,
                    size: isSmallScreen ? 16 : 18,
                  ),
                  label: Text(
                    "Clear Search",
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    foregroundColor: Theme.of(context).primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 15 : 20),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Connection Status enum
enum ConnectionStatus {
  none,
  pending,
  connected,
}