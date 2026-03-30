import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:chat_application/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import '../autoscroll.dart';
import '../models/message_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/locationservice.dart';
import '../services/maplocationservice.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:jose/jose.dart';

class ChatScreen extends StatefulWidget {
  final UserModel user;

  ChatScreen({required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static final Map<String, Uint8List> _imageCache = {};
  TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final DataBaseService db = DataBaseService();
  late Stream<List<MessageModel>> _messagesStream;
  bool showEmojiPicker = false;
  bool _isOnline = false;
  DateTime? _lastSeen;

  // Cache avatar bytes to prevent reloading
  Uint8List? _cachedAvatarBytes;
  bool _hasAvatar = false;
  bool _isAvatarBase64 = false;

  // Simple location service
  SimpleLocationService _simpleLocationService = SimpleLocationService();
  StreamSubscription<DatabaseEvent>? _onlineStatusSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAvatarCache();
    _listenToUserOnlineStatus();
    _isOnline = widget.user.isOnline ?? false;
    _lastSeen = widget.user.lastSeen;
    _messagesStream = getCombinedMessages();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(Duration(milliseconds: 200), () {
          _scrollDown();
        });
      }
    });
    // Mark messages as read when opening chat
    _markMessagesAsRead();
  }

  //Clear Chat
  Future<void> _showClearChatDialog() async {
    final theme = Theme.of(context);

    final bool shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text(
          'Clear Chat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        content: Text(
          'Are you sure you want to clear this chat? This will delete all your messages from this chat.',
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.primaryColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear Chat'),
          ),
        ],
      ),
    ) ?? false;

    if (shouldDelete) {
      await _clearCurrentUserChat();
    }
  }
  Future<void> _clearCurrentUserChat() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );

      final String currentUserId = db.currentUserUid;
      final String otherUserId = widget.user.uid!;

      // Reference to current user's chat with the other user
      final DatabaseReference myChatsRef = FirebaseDatabase.instance.ref(
        "Chats/$currentUserId/$otherUserId",
      );

      // Get all messages
      final DataSnapshot snapshot = (await myChatsRef.once()).snapshot;

      if (snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final List<Future> deleteFutures = [];

        for (var key in data.keys) {
          final messageRef = myChatsRef.child(key.toString());
          // Mark as deleted for me only
          deleteFutures.add(
              messageRef.update({
                'isDeletedForMe': true,
                'deletedAt': ServerValue.timestamp,
                'originalMessage': data[key]?['message']?.toString() ?? '',
              })
          );
        }

        await Future.wait(deleteFutures);

        // Update home screen summary
        await _updateHomeScreenSummaryAfterClearChat(currentUserId, otherUserId);

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat cleared successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Refresh messages
        setState(() {
          _messagesStream = getCombinedMessages();
        });
      } else {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No messages to delete'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      print('❌ Error clearing chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void> _updateHomeScreenSummaryAfterClearChat(
      String currentUserId,
      String otherUserId
      ) async {
    try {
      final DatabaseReference summaryRef = FirebaseDatabase.instance.ref(
        "ChatSummaries/$currentUserId/$otherUserId",
      );

      // Update summary to show no messages
      await summaryRef.update({
        'lastMessage': 'No messages',
        'lastMessageTime': ServerValue.timestamp,
        'formattedTime': _formatTime(DateTime.now().millisecondsSinceEpoch),
        'unreadCount': 0,
        'updatedAt': ServerValue.timestamp,
      });

      print('✅ Home screen summary updated after clearing chat');
    } catch (e) {
      print('❌ Error updating home screen summary: $e');
    }
  }

  // ✅ Initialize avatar cache once
  void _initializeAvatarCache() {
    _hasAvatar =
        widget.user.avatarUrl != null &&
            widget.user.avatarUrl!.isNotEmpty &&
            widget.user.avatarUrl != "no";

    _isAvatarBase64 = _hasAvatar &&
        (widget.user.avatarUrl!.startsWith('data:image') ||
            (widget.user.avatarUrl!.length > 100 &&
                !widget.user.avatarUrl!.startsWith('http')));

    if (_hasAvatar && _isAvatarBase64) {
      try {
        _cachedAvatarBytes = _decodeBase64(widget.user.avatarUrl!);
      } catch (e) {
        print("Error caching avatar: $e");
        _cachedAvatarBytes = null;
      }
    }
  }

  Widget _buildDayHeader(List<MessageModel> messages) {
    if (messages.isEmpty) return SizedBox();

    final theme = Theme.of(context);

    // पहले मैसेज का timestamp लें
    final firstMsg = messages.first;
    final lastMsg = messages.last;

    // चेक करें कि आज का कोई मैसेज है या नहीं
    bool hasTodayMessage = _isToday(lastMsg.timestamp);

    if (hasTodayMessage) {
      return Container(
        padding: EdgeInsets.symmetric(
          vertical: _getResponsivePadding(6, 8),
          horizontal: _getResponsivePadding(12, 16),
        ),
        margin: EdgeInsets.symmetric(
          vertical: _getResponsivePadding(6, 8),
        ),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "TODAY",
          style: TextStyle(
            color: theme.brightness == Brightness.dark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            fontSize: _getResponsiveFontSize(10, 12),
          ),
        ),
      );
    } else {
      // पहले मैसेज का दिन निकालें
      String dayText = _getMessageDayText(firstMsg.timestamp);

      return Container(
        padding: EdgeInsets.symmetric(
          vertical: _getResponsivePadding(6, 8),
          horizontal: _getResponsivePadding(12, 16),
        ),
        margin: EdgeInsets.symmetric(
          vertical: _getResponsivePadding(6, 8),
        ),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          dayText,
          style: TextStyle(
            color: theme.brightness == Brightness.dark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            fontSize: _getResponsiveFontSize(10, 12),
          ),
        ),
      );
    }
  }

  bool _isToday(dynamic timestamp) {
    try {
      int time = _getTimestampAsInt(timestamp);
      if (time == 0) return false;

      DateTime date = DateTime.fromMillisecondsSinceEpoch(time);
      DateTime now = DateTime.now();

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } catch (e) {
      return false;
    }
  }

  String _getMessageDayText(dynamic timestamp) {
    try {
      int time = _getTimestampAsInt(timestamp);
      if (time == 0) return "";

      DateTime date = DateTime.fromMillisecondsSinceEpoch(time);
      DateTime now = DateTime.now();
      DateTime yesterday = now.subtract(Duration(days: 1));

      // Check if it's today
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return "TODAY";
      }
      // Check if it's yesterday
      else if (date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day) {
        return "YESTERDAY";
      }
      // For other days
      else {
        // Format: DD/MM/YYYY
        return "${date.day.toString().padLeft(2, '0')}/${date.month
            .toString()
            .padLeft(2, '0')}/${date.year}";
      }
    } catch (e) {
      return "";
    }
  }

  bool _isMessageVisible(MessageModel msg) {
    return true;
  }

  Uint8List _decodeBase64(String base64String) {
    try {
      // Remove data:image/...;base64, prefix if present
      if (base64String.contains(',')) {
        base64String = base64String
            .split(',')
            .last;
      }
      return base64Decode(base64String);
    } catch (e) {
      print("Error decoding Base64: $e");
      return Uint8List(0);
    }
  }

  void _listenToUserOnlineStatus() {
    final userRef = FirebaseDatabase.instance
        .ref("users")
        .child(widget.user.uid);

    _onlineStatusSubscription = userRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );

        setState(() {
          _isOnline = data['isOnline'] == true;
          _lastSeen = data['lastSeen'] != null
              ? DateTime.tryParse(data['lastSeen'].toString())
              : null;
        });
      }
    });
  }

  Widget _buildOnlineStatusText() {
    final statusText = _getStatusText();

    return AutoScrollStatusText(text: statusText, isOnline: _isOnline);
  }

  String _getStatusText() {
    if (_isOnline) {
      return "Online";
    } else if (_lastSeen != null) {
      return "Last seen ${_formatLastSeenWhatsAppStyle(_lastSeen!)}";
    } else {
      return "Offline";
    }
  }

  String _formatLastSeenWhatsAppStyle(DateTime lastSeen) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final lastSeenDate = DateTime(lastSeen.year, lastSeen.month, lastSeen.day);

    // Format time (e.g., 10:30 AM, 2:45 PM)
    final timeString = _formatTime1(lastSeen);

    // Check if same day (today)
    if (lastSeenDate == today) {
      return "today at $timeString";
    }
    // Check if yesterday
    else if (lastSeenDate == yesterday) {
      return "yesterday at $timeString";
    }
    // Check if within last 7 days
    else if (now
        .difference(lastSeenDate)
        .inDays < 7) {
      final weekday = _getWeekday(lastSeen.weekday);
      return "$weekday at $timeString";
    }
    // Older than 7 days
    else {
      final dateString = "${lastSeen.day}/${lastSeen.month}/${lastSeen.year}";
      return "$dateString at $timeString";
    }
  }

  String _formatTime1(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:$minute $period';
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  // ✅ Fix: Updated calculate unread count method
  Future<int> _calculateUnreadCount(String userId, String otherUserId) async {
    try {
      DatabaseReference chatsRef = FirebaseDatabase.instance.ref(
        "Chats/$userId/$otherUserId",
      );

      DataSnapshot snapshot = (await chatsRef.once()).snapshot;
      int count = 0;

      if (snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value != null) {
            Map<String, dynamic> messageData = Map<String, dynamic>.from(value);
            // ✅ Count messages from other user that are not seen
            // ✅ AND ensure message is not from current user
            if (messageData['senderId'] == otherUserId &&
                messageData['isSeen'] == false) {
              count++;
            }
          }
        });
      }

      print("✅ Unread count for $userId from $otherUserId: $count");
      return count;
    } catch (e) {
      print("Error calculating unread count: $e");
      return 0;
    }
  }

  // ✅ CORRECT: Mark messages as read only in current user's chat
  void _markMessagesAsRead() async {
    try {
      String currentUserId = db.currentUserUid;
      String otherUserId = widget.user.uid!;

      DatabaseReference myChatsRef = FirebaseDatabase.instance.ref(
        "Chats/$currentUserId/$otherUserId",
      );

      DatabaseReference otherChatsRef = FirebaseDatabase.instance.ref(
        "Chats/$otherUserId/$currentUserId",
      );

      // Get all messages in my chat
      DataSnapshot snapshot = (await myChatsRef.once()).snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        List<Future> updateFutures = [];

        data.forEach((key, value) {
          if (value != null) {
            Map<String, dynamic> messageData = Map<String, dynamic>.from(value);

            // Only mark messages sent by other user as read
            if (messageData['senderId'] == otherUserId &&
                (messageData['isSeen'] == false ||
                    messageData['isSeen'] == null)) {
              print("📖 Marking message as read: ${messageData['message']}");

              // 1. Update in my chat
              updateFutures.add(myChatsRef.child(key).update({'isSeen': true}));

              // 2. Find and update in sender's chat
              String messageContent = messageData['message']?.toString() ?? "";
              String senderId = messageData['senderId']?.toString() ?? "";

              updateFutures.add(
                _updateSameMessageInSenderChat(
                  otherChatsRef,
                  messageContent,
                  senderId,
                ),
              );
              if (messageData['message'] != null) {
                updateFutures.add(
                  _updateHomeScreenSummary(
                    messageData['message'],
                    currentUserId,
                  ),
                );
              }
            }
          }
        });

        if (updateFutures.isNotEmpty) {
          await Future.wait(updateFutures);
          print("✅ ${updateFutures.length ~/ 2} messages marked as read");

          setState(() {
            _messagesStream = getCombinedMessages();
          });
        }
      }
    } catch (e) {
      print("❌ Error marking messages as read: $e");
    }
  }

  Future<void> _updateSameMessageInSenderChat(DatabaseReference senderRef,
      String messageContent,
      String senderId,) async {
    try {
      DataSnapshot snapshot = (await senderRef.once()).snapshot;

      if (snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        for (var key in data.keys) {
          var value = data[key];
          if (value != null) {
            Map<String, dynamic> messageData = Map<String, dynamic>.from(value);

            if (messageData['message'] == messageContent &&
                messageData['senderId'] == senderId) {
              await senderRef.child(key.toString()).update({
                'isSeen': true, // Blue tick दिखेगा
              });

              return;
            }
          }
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // ✅ Fix: Update home screen summary method to ensure unread is 0
  Future<void> _updateHomeScreenSummary(String message,
      String currentUserId,) async {
    try {
      String otherUserId = widget.user.uid!;
      String timestamp = DateTime
          .now()
          .millisecondsSinceEpoch
          .toString();
      String formattedTime =
          "${DateTime
          .now()
          .hour
          .toString()
          .padLeft(2, '0')}:${DateTime
          .now()
          .minute
          .toString()
          .padLeft(2, '0')}";

      DatabaseReference summaryRef = FirebaseDatabase.instance.ref(
        "ChatSummaries/$currentUserId/$otherUserId",
      );

      // ✅ First get current summary
      DataSnapshot snapshot = (await summaryRef.once()).snapshot;

      if (snapshot.exists) {
        // Update only unread count and timestamp
        await summaryRef.update({
          'lastMessage': _getMessagePreview(message, "text"),
          'lastMessageTime': timestamp,
          'formattedTime': formattedTime,
          'unreadCount': 0, // ✅ Force set to 0 when opening chat
          'updatedAt': ServerValue.timestamp,
        });
      } else {
        // Create new summary with 0 unread
        await summaryRef.set({
          'chatId': otherUserId,
          'lastMessage': _getMessagePreview(message, "text"),
          'lastMessageTime': timestamp,
          'formattedTime': formattedTime,
          'unreadCount': 0,
          'updatedAt': ServerValue.timestamp,
        });
      }

      print("✅ Home screen summary updated with 0 unread");
    } catch (e) {
      print("Error updating home screen summary: $e");
    }
  }

  // ✅ Fix: Also update the sender's side unread count calculation in _updateHomeScreenSummaries
  Future<void> _updateHomeScreenSummaries(String message,
      String senderId,
      String receiverId,
      String senderName,
      String receiverName,
      String messageType,) async {
    String timestamp = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();
    String formattedTime =
        "${DateTime
        .now()
        .hour
        .toString()
        .padLeft(2, '0')}:${DateTime
        .now()
        .minute
        .toString()
        .padLeft(2, '0')}";

    // Get current user's online status
    DatabaseEvent userEvent = await FirebaseDatabase.instance
        .ref("users/$senderId")
        .once();

    bool isOnline = false;
    DateTime? lastSeen;

    if (userEvent.snapshot.value != null) {
      Map<dynamic, dynamic> userData =
      userEvent.snapshot.value as Map<dynamic, dynamic>;
      isOnline = userData['isOnline'] ?? false;
      if (userData['lastSeen'] != null) {
        lastSeen = DateTime.tryParse(userData['lastSeen'].toString());
      }
    }

    // ✅ Calculate unread count for receiver - FIXED
    int unreadCount = await _calculateUnreadCount(receiverId, senderId);

    print("📊 Unread count for receiver ($receiverId): $unreadCount");

    // Get receiver's avatar from users node
    String receiverAvatarUrl = "no";
    final receiverAvatarEvent = await FirebaseDatabase.instance
        .ref("users/$receiverId")
        .once();

    if (receiverAvatarEvent.snapshot.value != null) {
      final receiverData = Map<String, dynamic>.from(
        receiverAvatarEvent.snapshot.value as Map<dynamic, dynamic>,
      );
      receiverAvatarUrl = receiverData['avatarUrl']?.toString() ?? "no";
    }

    // ✅ For Sender's home screen (chat with receiver) - Show RECEIVER'S avatar
    DatabaseReference senderSummaryRef = FirebaseDatabase.instance.ref(
      "ChatSummaries/$senderId/$receiverId",
    );

    await senderSummaryRef.set({
      'chatId': receiverId,
      'lastMessage': _getMessagePreview(message, messageType),
      'lastMessageTime': timestamp,
      'formattedTime': formattedTime,
      'unreadCount': 0,
      // ✅ Sender's side always shows 0 (since they sent the message)
      'isOnline': widget.user.isOnline ?? false,
      'avatarUrl': receiverAvatarUrl,
      'lastSeen': widget.user.lastSeen?.toIso8601String(),
      'chatPartnerName': receiverName,
      'name': receiverName,
      'isTyping': false,
      'messageType': messageType,
      'updatedAt': ServerValue.timestamp,
    });

    // Get sender's avatar from users node
    String senderAvatarUrl = "no";
    final senderAvatarEvent = await FirebaseDatabase.instance
        .ref("users/$senderId")
        .once();

    if (senderAvatarEvent.snapshot.value != null) {
      final senderData = Map<String, dynamic>.from(
        senderAvatarEvent.snapshot.value as Map<dynamic, dynamic>,
      );
      senderAvatarUrl = senderData['avatarUrl']?.toString() ?? "no";
    }

    // ✅ For Receiver's home screen (chat with sender) - Show SENDER'S avatar
    // ✅ IMPORTANT: Check if receiver is looking at the chat
    bool isReceiverViewingChat = false;

    // You might want to track if receiver is currently in the chat screen
    // For now, we'll assume if unreadCount is 0, they're viewing it
    if (unreadCount == 0) {
      isReceiverViewingChat = true;
    }

    // Calculate final unread count
    int finalUnreadCount = isReceiverViewingChat ? 0 : unreadCount + 1;

    DatabaseReference receiverSummaryRef = FirebaseDatabase.instance.ref(
      "ChatSummaries/$receiverId/$senderId",
    );

    await receiverSummaryRef.set({
      'chatId': senderId,
      'lastMessage': _getMessagePreview(message, messageType),
      'lastMessageTime': timestamp,
      'formattedTime': formattedTime,
      'unreadCount': finalUnreadCount, // ✅ Correct unread count
      'isOnline': isOnline,
      'avatarUrl': senderAvatarUrl,
      'lastSeen': lastSeen?.toIso8601String(),
      'chatPartnerName': senderName,
      'name': senderName,
      'isTyping': false,
      'messageType': messageType,
      'updatedAt': ServerValue.timestamp,
    });

    print("✅ ChatSummaries updated:");
    print("📤 Sender ($senderId) sees: 0 unread");
    print("📥 Receiver ($receiverId) sees: $finalUnreadCount unread");
    print("👀 Receiver viewing chat: $isReceiverViewingChat");
  }

  String _getMessagePreview(String message, String messageType) {
    switch (messageType) {
      case "image":
        return "📷 Photo";
      case "document":
        return "📄 Document";
      case "location":
        return "📍 Location";
      case "live_location":
        return "📍 Live Location";
      default:
        return message.length > 30 ? message.substring(0, 30) + "..." : message;
    }
  }

  String getDayText(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Today";
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return "Yesterday";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  Stream<List<MessageModel>> getCombinedMessages() {
    String currentUserId = db.currentUserUid;
    String otherUserId = widget.user.uid!;

    DatabaseReference chatsRef = FirebaseDatabase.instance.ref(
      "Chats/$currentUserId/$otherUserId",
    );

    return chatsRef.onValue.map((event) {
      List<MessageModel> msgs = [];

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data =
        event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          try {
            if (value != null) {
              Map<String, dynamic> messageData = Map<String, dynamic>.from(
                value,
              );
              msgs.add(MessageModel.fromJson(messageData));
            }
          } catch (e) {
            print("Error parsing message: $e");
          }
        });
      }

      // Filter out messages deleted for current user
      msgs = msgs.where((msg) {
        return !(msg.isDeletedForMe ?? false);
      }).toList();

      // Remove duplicates
      Map<String, MessageModel> uniqueMessages = {};
      for (var msg in msgs) {
        // Use helper function to get timestamp as int
        int timestampInt = _getTimestampAsInt(msg.timestamp);
        String uniqueKey =
            "${timestampInt}_${msg.message.substring(
            0, min(msg.message.length, 20))}";
        uniqueMessages[uniqueKey] = msg;
      }

      List<MessageModel> sortedMsgs = uniqueMessages.values.toList();

      // FIXED: Use helper function to compare timestamps
      sortedMsgs.sort((a, b) {
        int timestampA = _getTimestampAsInt(a.timestamp);
        int timestampB = _getTimestampAsInt(b.timestamp);
        return timestampA.compareTo(timestampB);
      });

      return sortedMsgs;
    });
  }

  // Add this helper function
  int _getTimestampAsInt(dynamic timestamp) {
    if (timestamp is int) {
      return timestamp;
    } else if (timestamp is String) {
      return int.tryParse(timestamp) ?? 0;
    } else if (timestamp is double) {
      return timestamp.toInt();
    }
    return 0;
  }

  int min(int a, int b) => a < b ? a : b;

  void _sendMessage() {
    if (_messageController.text
        .trim()
        .isNotEmpty) {
      String msg = _messageController.text.trim();
      sendMessageToFirebase(msg, messageType: "text");
      _messageController.clear();
      _scrollDown();
      // REMOVED: FocusScope.of(context).unfocus();
      // Keep keyboard open after sending
    }
  }
  
  void _scrollDown() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Location Options दिखाएं
  void _showLocationOptions() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "Share Location",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),

                Divider(height: 1, color: theme.dividerColor),

                // Live Location Option
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.location_on, color: Colors.red),
                  ),
                  title: Text(
                    "Share Live Location",
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    "Share your real-time location",
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDurationOptions();
                  },
                ),

                // Current Location Option
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.location_pin, color: Colors.blue),
                  ),
                  title: Text(
                    "Send Current Location",
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    "Share your current location once",
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _shareCurrentLocation();
                  },
                ),

                SizedBox(height: 20),
                Divider(height: 1, color: theme.dividerColor),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
    );
  }

  // Duration Options
  void _showDurationOptions() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "Share Live Location For",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),

                Divider(height: 1, color: theme.dividerColor),

                _durationOption("15 minutes", 15),
                _durationOption("1 hour", 60),
                _durationOption("8 hours", 480),

                SizedBox(height: 20),
                Divider(height: 1, color: theme.dividerColor),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
    );
  }

  Widget _durationOption(String title, int minutes) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(Icons.timer, color: Colors.green),
      title: Text(
        title,
        style: TextStyle(
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: Text(
        "$minutes min",
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        _startLiveLocationSharing(minutes);
      },
    );
  }

  // Live Location शुरू करें
  Future<void> _startLiveLocationSharing(int durationInMinutes) async {
    String senderId = db.currentUserUid;
    String receiverId = widget.user.uid!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            backgroundColor: Theme
                .of(context)
                .dialogBackgroundColor,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme
                      .of(context)
                      .primaryColor,
                ),
                SizedBox(height: 15),
                Text(
                  "Starting live location...",
                  style: TextStyle(
                    color: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium
                        ?.color,
                  ),
                ),
              ],
            ),
          ),
    );

    try {
      Map<String, dynamic> locationData = await _simpleLocationService
          .startSimpleLiveLocation(
        senderId: senderId,
        receiverId: receiverId,
        durationInMinutes: durationInMinutes,
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Live location sharing started"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Open map screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SimpleLiveMapScreen(
                sessionId: locationData['sessionId']!,
                senderId: senderId,
                receiverId: receiverId,
                durationInMinutes: durationInMinutes,
                onStopSharing: () {
                  _simpleLocationService.stopLiveLocation(
                    senderId: senderId,
                    receiverId: receiverId,
                  );
                },
              ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to start live location: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Current Location Share करें
  Future<void> _shareCurrentLocation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            backgroundColor: Theme
                .of(context)
                .dialogBackgroundColor,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme
                      .of(context)
                      .primaryColor,
                ),
                SizedBox(height: 15),
                Text(
                  "Getting your location...",
                  style: TextStyle(
                    color: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium
                        ?.color,
                  ),
                ),
              ],
            ),
          ),
    );

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String address = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Navigator.pop(context);

      await _sendStaticLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to get location"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street ?? ''}, ${place.locality ?? ''}'.trim();
      }
      return 'Location';
    } catch (e) {
      return 'Location';
    }
  }

  Future<void> _sendStaticLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    String senderId = db.currentUserUid;
    String receiverId = widget.user.uid!;

    String messageId = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();

    DatabaseReference myRef = FirebaseDatabase.instance.ref(
      "Chats/$senderId/$receiverId/$messageId",
    );

    DatabaseReference otherRef = FirebaseDatabase.instance.ref(
      "Chats/$receiverId/$senderId/$messageId",
    );

    // Get user names
    DatabaseEvent senderEvent = await FirebaseDatabase.instance
        .ref("users/$senderId")
        .once();

    DatabaseEvent receiverEvent = await FirebaseDatabase.instance
        .ref("users/$receiverId")
        .once();

    String senderName = "";
    String receiverName = "";

    if (senderEvent.snapshot.value != null) {
      Map<dynamic, dynamic> senderData =
      senderEvent.snapshot.value as Map<dynamic, dynamic>;
      senderName = senderData['name']?.toString() ?? await db.currentUserName;
    } else {
      senderName = await db.currentUserName;
    }

    if (receiverEvent.snapshot.value != null) {
      Map<dynamic, dynamic> receiverData =
      receiverEvent.snapshot.value as Map<dynamic, dynamic>;
      receiverName =
          receiverData['name']?.toString() ?? widget.user.name ?? "User";
    } else {
      receiverName = widget.user.name ?? "User";
    }

    DateTime now = DateTime.now();
    String dayText = getDayText(now);
    String formattedTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(
        2, '0')}";

    // ✅ CORRECT: Sender's chat में isSeen: true
    Map<String, dynamic> messageDataForSender = {
      "senderId": senderId,
      "receverId": receiverId,
      "senderName": senderName,
      "receiverName": receiverName,
      "name": receiverName,
      "message": "📍 Location",
      "latitude": latitude,
      "longitude": longitude,
      "address": address,
      "timestamp": ServerValue.timestamp,
      "time": formattedTime,
      "day": dayText,
      "isSeen": true, // ✅ SENDER के लिए true
      "messageType": "location",
      "isLive": false,
    };

    // ✅ CORRECT: Receiver's chat में isSeen: false
    Map<String, dynamic> messageDataForReceiver = {
      "senderId": senderId,
      "receverId": receiverId,
      "senderName": senderName,
      "receiverName": receiverName,
      "name": senderName,
      "message": "📍 Location",
      "latitude": latitude,
      "longitude": longitude,
      "address": address,
      "timestamp": ServerValue.timestamp,
      "time": formattedTime,
      "day": dayText,
      "isSeen": false, // ✅ RECEIVER के लिए false
      "messageType": "location",
      "isLive": false,
    };

    await Future.wait([
      myRef.set(messageDataForSender),
      otherRef.set(messageDataForReceiver),
    ]);

    // ✅ Update home screen summaries
    await _updateHomeScreenSummaries(
      "📍 Location",
      senderId,
      receiverId,
      senderName,
      receiverName,
      "location",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Location shared"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery
        .of(context)
        .size;
    final isTablet = screenSize.width > 600;
    final isSmallScreen = screenSize.width <= 360;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 1,
        // ✅ Use cached avatar to prevent reloading
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // ✅ Avatar - Use cached version
            Container(
              width: _getResponsiveSize(36, 40),
              height: _getResponsiveSize(36, 40),
              margin: EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_getResponsiveSize(18, 20)),
                border: Border.all(
                  color: theme.dividerColor ?? Colors.grey.shade300,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_getResponsiveSize(18, 20)),
                child: _buildAvatarWidget(),
              ),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.user.name!,
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(16, 18),
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  _buildOnlineStatusText(),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed:_showClearChatDialog,
            icon: Icon(
              Icons.delete,
              color: theme.iconTheme.color,
            ),
          ),
        ],
        iconTheme: theme.appBarTheme.iconTheme ??
            IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [


            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "No messages yet",
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    );
                  }

                  List<MessageModel> msgs = snapshot.data!;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollDown();
                  });

                  return Column(
                    children: [
                      _buildDayHeader(msgs),
                       Expanded(
                         child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: _getResponsivePadding(8, 12),
                          ),
                          itemCount: msgs.length,
                          itemBuilder: (context, index) {
                            final msg = msgs[index];

                            if (msg.messageType == "live_location") {
                              return _buildLiveLocationBubble(msg);
                            } else if (msg.messageType == "image" ||
                                msg.messageType == "document") {
                              return _buildFileMessageBubble(msg);
                            } else if (msg.messageType == "location") {
                              return _buildStaticLocationBubble(msg);
                            } else {
                              return _buildMessageBubbleDynamic(msg);
                            }
                          },
                                               ),
                       ),
                    ],
                  );
                },
              ),
            ),

            _buildChatMessageBox(),
          ],
        ),
      ),
    );
  }

  // ✅ Improved avatar widget with caching
  Widget _buildAvatarWidget() {
    final theme = Theme.of(context);

    if (_hasAvatar && _isAvatarBase64 && _cachedAvatarBytes != null) {
      return Image.memory(
        _cachedAvatarBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackAvatar(widget.user.name!);
        },
      );
    } else if (_hasAvatar && widget.user.avatarUrl!.startsWith('http')) {
      return CachedNetworkAvatar(
        url: widget.user.avatarUrl!,
        userName: widget.user.name!,
      );
    } else {
      return _buildFallbackAvatar(widget.user.name!);
    }
  }

  // ✅ Helper method for fallback avatar
  Widget _buildFallbackAvatar(String userName) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
          color: Theme
              .of(context)
              .primaryColor,
          shape: BoxShape.circle
      ),
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: _getResponsiveFontSize(12, 14),
          ),
        ),
      ),
    );
  }

  // WhatsApp जैसे Live Location Bubble
  Widget _buildLiveLocationBubble(MessageModel msg) {
    bool isMe = msg.senderId == db.currentUserUid;
    String time = _formatTime(msg.timestamp);
    final theme = Theme.of(context);

    double latitude = msg.latitude ?? 0.0;
    double longitude = msg.longitude ?? 0.0;
    String address = msg.address ?? "Current Location";
    bool isLive = msg.isLive ?? false;
    bool isActive = msg.isActive ?? false;
    int expiryTime = msg.expiryTime ?? 0;
    String? previewImage = msg.previewImage;

    // Check if still active
    bool isStillActive =
        isLive &&
            isActive &&
            expiryTime > DateTime
                .now()
                .millisecondsSinceEpoch;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              backgroundColor: theme.primaryColor,
              radius: _getResponsiveSize(14, 16),
              child: Text(
                widget.user.name![0].toUpperCase(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(10, 12)
                ),
              ),
            ),
          SizedBox(width: isMe ? 0 : _getResponsivePadding(6, 8)),

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery
                    .of(context)
                    .size
                    .width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Location Card
                  GestureDetector(
                    onTap: () {
                      if (isStillActive) {
                        // Open live map
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SimpleLiveMapScreen(
                                  sessionId: msg.sessionId ?? "",
                                  senderId: msg.senderId,
                                  receiverId: msg.receverId,
                                  durationInMinutes: msg.duration ?? 15,
                                  onStopSharing: () {
                                    if (isMe) {
                                      _simpleLocationService.stopLiveLocation(
                                        senderId: msg.senderId,
                                        receiverId: msg.receverId,
                                      );
                                    }
                                  },
                                ),
                          ),
                        );
                      } else {
                        // Open in maps
                        _openInMaps(latitude, longitude);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isStillActive
                            ? Colors.red.shade50.withOpacity(theme.brightness ==
                            Brightness.dark ? 0.2 : 1)
                            : theme.brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isStillActive
                              ? Colors.red.shade200
                              : theme.dividerColor ?? Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Padding(
                            padding: EdgeInsets.all(
                                _getResponsivePadding(10, 12)),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: isStillActive
                                      ? Colors.red
                                      : theme.textTheme.bodyMedium?.color,
                                  size: _getResponsiveSize(20, 24),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Live Location",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: _getResponsiveFontSize(
                                              14, 16),
                                          color: isStillActive
                                              ? Colors.red
                                              : theme.textTheme.bodyLarge
                                              ?.color,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        address,
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                              10, 12),
                                          color: theme.textTheme.bodyMedium
                                              ?.color?.withOpacity(0.7),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Map Preview (छोटा map)
                          Container(
                            height: _getResponsiveSize(100, 120),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: theme.dividerColor ??
                                    Colors.grey.shade300),
                                bottom: BorderSide(color: theme.dividerColor ??
                                    Colors.grey.shade300),
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Custom map preview
                                if (previewImage != null &&
                                    previewImage.isNotEmpty)
                                  Container(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey.shade900
                                        : Colors.grey[200],
                                    child: Center(
                                      child: Image.memory(
                                        base64Decode(previewImage),
                                        width: 200,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                else
                                // Fallback map preview
                                  Container(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey.shade900
                                        : Colors.grey[200],
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.map,
                                            size: _getResponsiveSize(30, 40),
                                            color: theme.textTheme.bodyMedium
                                                ?.color?.withOpacity(0.5),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            "Live Location",
                                            style: TextStyle(
                                              color: theme.textTheme.bodyMedium
                                                  ?.color?.withOpacity(0.7),
                                              fontSize: _getResponsiveFontSize(
                                                  10, 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Live badge
                                if (isStillActive)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            "LIVE",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: _getResponsiveFontSize(
                                                  8, 10),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Tap to view text
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "Tap to view",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: _getResponsiveFontSize(8, 10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer and time
                  Padding(
                    padding: EdgeInsets.only(
                        top: 4,
                        left: 8,
                        right: 8
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isStillActive
                              ? "Live for ${_getRemainingTime(expiryTime)}"
                              : "Location ended",
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(9, 11),
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(9, 11),
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                            if (isMe) SizedBox(width: 4),
                            if (isMe && msg.isSeen == true)
                              Icon(
                                  Icons.done_all,
                                  size: _getResponsiveSize(10, 12),
                                  color: Colors.blue
                              ),
                            if (isMe && msg.isSeen == false)
                              Icon(
                                Icons.done,
                                size: _getResponsiveSize(10, 12),
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: isMe ? _getResponsivePadding(6, 8) : 0),
          if (isMe)
            CircleAvatar(
              backgroundColor: Theme
                  .of(context)
                  .primaryColor,
              radius: _getResponsiveSize(14, 16),
              child: Text(
                db.currentUserUid.isNotEmpty
                    ? db.currentUserUid[0].toUpperCase()
                    : "Y",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(10, 12)
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Static Location Bubble
  Widget _buildStaticLocationBubble(MessageModel msg) {
    bool isMe = msg.senderId == db.currentUserUid;
    String time = _formatTime(msg.timestamp);
    final theme = Theme.of(context);

    double latitude = msg.latitude ?? 0.0;
    double longitude = msg.longitude ?? 0.0;
    String address = msg.address ?? "Location";

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              backgroundColor: theme.primaryColor,
              radius: _getResponsiveSize(14, 16),
              child: Text(
                widget.user.name![0].toUpperCase(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(10, 12)
                ),
              ),
            ),
          SizedBox(width: isMe ? 0 : _getResponsivePadding(6, 8)),

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery
                    .of(context)
                    .size
                    .width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      _openInMaps(latitude, longitude);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.dividerColor ?? Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(
                                _getResponsivePadding(10, 12)),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_pin,
                                  color: theme.primaryColor,
                                  size: _getResponsiveSize(20, 24),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Location",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: _getResponsiveFontSize(
                                              14, 16),
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        address,
                                        style: TextStyle(
                                          fontSize: _getResponsiveFontSize(
                                              10, 12),
                                          color: theme.textTheme.bodyMedium
                                              ?.color?.withOpacity(0.7),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            height: _getResponsiveSize(70, 80),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: theme.dividerColor ??
                                    Colors.grey.shade300),
                                bottom: BorderSide(color: theme.dividerColor ??
                                    Colors.grey.shade300),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map,
                                    size: _getResponsiveSize(24, 30),
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.5),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Tap to open in maps",
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(8, 10),
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer and time
                  Padding(
                    padding: EdgeInsets.only(
                        top: 4,
                        left: 8,
                        right: 8
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${latitude.toStringAsFixed(4)}, ${longitude
                              .toStringAsFixed(4)}",
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(8, 10),
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(9, 11),
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                            if (isMe) SizedBox(width: 4),
                            if (isMe && msg.isSeen == true)
                              Icon(
                                  Icons.done_all,
                                  size: _getResponsiveSize(10, 12),
                                  color: Colors.blue
                              ),
                            if (isMe && msg.isSeen == false)
                              Icon(
                                Icons.done,
                                size: _getResponsiveSize(10, 12),
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: isMe ? _getResponsivePadding(6, 8) : 0),
          if (isMe)
            CircleAvatar(
              backgroundColor: Theme
                  .of(context)
                  .primaryColor,
              radius: _getResponsiveSize(14, 16),
              child: Text(
                db.currentUserUid.isNotEmpty
                    ? db.currentUserUid[0].toUpperCase()
                    : "Y",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(10, 12)
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Update _formatTime function
  String _formatTime(dynamic timestamp) {
    try {
      int time = _getTimestampAsInt(timestamp);

      if (time == 0) return "";

      DateTime date = DateTime.fromMillisecondsSinceEpoch(time);
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute
          .toString()
          .padLeft(2, '0')}";
    } catch (e) {
      print("Error formatting time: $e");
      return "";
    }
  }

  String _getRemainingTime(int expiryTime) {
    DateTime expiry = DateTime.fromMillisecondsSinceEpoch(expiryTime);
    Duration remaining = expiry.difference(DateTime.now());

    if (remaining.inHours > 0) {
      return "${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m";
    } else if (remaining.inMinutes > 0) {
      return "${remaining.inMinutes}m";
    } else {
      return "ended";
    }
  }

  Future<void> _openInMaps(double lat, double lng) async {
    String url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Cannot open maps")));
    }
  }

  Widget _buildChatMessageBox() {
    final theme = Theme.of(context);
    final screenSize = MediaQuery
        .of(context)
        .size;
    final isSmallScreen = screenSize.width <= 360;

    return Container(
      padding: EdgeInsets.all(_getResponsivePadding(6, 8)),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
            top: BorderSide(color: theme.dividerColor ?? Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade100,
            radius: _getResponsiveSize(18, 20),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                _focusNode.unfocus();
                setState(() {
                  showEmojiPicker = !showEmojiPicker;
                });
              },
              icon: Icon(
                Icons.emoji_emotions_outlined,
                color: theme.textTheme.bodyMedium?.color,
                size: _getResponsiveSize(18, 22),
              ),
            ),
          ),
          SizedBox(width: _getResponsivePadding(6, 8)),

          Expanded(
            child: Container(
              constraints: BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: _getResponsiveFontSize(14, 16),
                        ),
                        decoration: InputDecoration(
                          hintText: "Message",
                          hintStyle: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                            fontSize: _getResponsiveFontSize(14, 16),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: _getResponsivePadding(12, 16),
                            vertical: _getResponsivePadding(10, 12),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            showEmojiPicker = false;
                          });
                        },
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (value) => _sendMessage(),
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      _openAttachmentSheet(context);
                    },
                    icon: Icon(
                      Icons.attach_file,
                      color: theme.textTheme.bodyMedium?.color,
                      size: _getResponsiveSize(18, 22),
                    ),
                  ),
                  SizedBox(width: 4),
                ],
              ),
            ),
          ),
          SizedBox(width: _getResponsivePadding(6, 8)),

          CircleAvatar(
            backgroundColor: theme.primaryColor,
            radius: _getResponsiveSize(18, 20),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: _sendMessage,
              icon: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: _getResponsiveSize(16, 18)
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAttachmentSheet(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery
        .of(context)
        .size;
    final isTablet = screenSize.width > 600;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(isTablet ? 20 : 15),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Wrap(
            children: [
              Row(
                mainAxisAlignment: isTablet
                    ? MainAxisAlignment.spaceEvenly
                    : MainAxisAlignment.spaceBetween,
                children: [
                  _attachmentIcon(
                    icon: Icons.insert_drive_file,
                    color: Colors.purple,
                    label: "Document",
                    onTap: () {
                      Navigator.pop(context);
                      pickDocument();
                    },
                  ),
                  _attachmentIcon(
                    icon: Icons.camera_alt,
                    color: Colors.red,
                    label: "Camera",
                    onTap: () {
                      Navigator.pop(context);
                      openCamera();
                    },
                  ),
                  _attachmentIcon(
                    icon: Icons.photo,
                    color: Colors.green,
                    label: "Gallery",
                    onTap: () {
                      Navigator.pop(context);
                      openGallery();
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: isTablet
                    ? MainAxisAlignment.spaceEvenly
                    : MainAxisAlignment.spaceBetween,
                children: [
                  _attachmentIcon(
                    icon: Icons.location_on,
                    color: Colors.orange,
                    label: "Location",
                    onTap: () {
                      Navigator.pop(context);
                      _showLocationOptions();
                    },
                  ),
                  _attachmentIcon(
                    icon: Icons.person,
                    color: Colors.blue,
                    label: "Contact",
                    onTap: () {
                      Navigator.pop(context);
                      // Add contact functionality
                    },
                  ),
                ],
              ),
              SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  Widget _attachmentIcon({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    final screenSize = MediaQuery
        .of(context)
        .size;
    final isTablet = screenSize.width > 600;
    final isSmallScreen = screenSize.width <= 360;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: isTablet ? 70 : isSmallScreen ? 50 : 56,
            height: isTablet ? 70 : isSmallScreen ? 50 : 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                  isTablet ? 35 : isSmallScreen ? 25 : 28),
            ),
            child: Icon(
                icon,
                color: color,
                size: isTablet ? 32 : isSmallScreen ? 24 : 28
            ),
          ),
          SizedBox(height: 5),
          Text(
              label,
              style: TextStyle(
                  fontSize: isTablet ? 14 : isSmallScreen ? 10 : 12,
                  color: Theme
                      .of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
              )
          ),
        ],
      ),
    );
  }

  // Responsive helper methods
  double _getResponsiveSize(double small, double large) {
    final screenSize = MediaQuery
        .of(context)
        .size;
    if (screenSize.width > 600) {
      return large * 1.2; // Tablet
    } else if (screenSize.width <= 360) {
      return small * 0.9; // Small phone
    }
    return large; // Normal phone
  }

  double _getResponsiveFontSize(double small, double large) {
    final screenSize = MediaQuery
        .of(context)
        .size;
    if (screenSize.width > 600) {
      return large * 1.1; // Tablet
    } else if (screenSize.width <= 360) {
      return small; // Small phone
    }
    return large; // Normal phone
  }

  double _getResponsivePadding(double small, double large) {
    final screenSize = MediaQuery
        .of(context)
        .size;
    if (screenSize.width > 600) {
      return large * 1.2; // Tablet
    } else if (screenSize.width <= 360) {
      return small * 0.8; // Small phone
    }
    return large; // Normal phone
  }

  @override
  void dispose() {
    _simpleLocationService.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _onlineStatusSubscription?.cancel();
    super.dispose();
  }

  // Rest of your existing methods...
  Future<void> openGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 30,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image != null) {
        List<int> imageBytes = await File(image.path).readAsBytes();
        if (imageBytes.length > 1000000) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Image too large, please select a smaller image"),
            ),
          );
          return;
        }
        String base64Image = base64Encode(imageBytes);
        await sendImageAsBase64(base64Image, path.basename(image.path));
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to pick image")));
    }
  }

  Future<void> openCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 30,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image != null) {
        List<int> imageBytes = await File(image.path).readAsBytes();
        if (imageBytes.length > 1000000) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Image too large")));
          return;
        }
        String base64Image = base64Encode(imageBytes);
        await sendImageAsBase64(
          base64Image,
          "camera_${DateTime
              .now()
              .millisecondsSinceEpoch}.jpg",
        );
      }
    } catch (e) {
      print("Error capturing image: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to capture image")));
    }
  }

  Future<void> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
        allowMultiple: false,
      );
      if (result != null) {
        String? filePath = result.files.single.path;
        if (filePath != null) {
          File file = File(filePath);
          int fileSize = await file.length();
          if (fileSize > 1000000) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("File too large (max 1MB)")));
            return;
          }
          List<int> fileBytes = await file.readAsBytes();
          String base64Doc = base64Encode(fileBytes);
          await sendDocumentAsBase64(base64Doc, result.files.single.name);
        }
      }
    } catch (e) {
      print("Error picking document: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to pick document")));
    }
  }

  void _showImageFullScreen(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(0),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                height: MediaQuery
                    .of(context)
                    .size
                    .height,
                color: Colors.black87,
                child: Center(
                    child: Image.memory(imageBytes, fit: BoxFit.contain)),
              ),
            ),
          ),
    );
  }

  void _saveFile(String base64Data, String fileName) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Saving file..."), duration: Duration(seconds: 2)),
    );
    await Future.delayed(Duration(seconds: 1));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("File saved: $fileName"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ✅ Function to send message to Firebase (CORRECT isSeen logic)
  Future<void> sendMessageToFirebase(String content, {
    String messageType = "text",
    String? fileName,
    String? fileExtension,
  }) async {
    String senderId = db.currentUserUid;
    String receiverId = widget.user.uid!;

    String messageId = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();

    DateTime now = DateTime.now();
    String dayText = getDayText(now);
    String formattedTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(
        2, '0')}";

    DatabaseReference myRef = FirebaseDatabase.instance.ref(
      "Chats/$senderId/$receiverId/$messageId",
    );

    DatabaseReference otherRef = FirebaseDatabase.instance.ref(
      "Chats/$receiverId/$senderId/$messageId",
    );

    // Get user names
    DatabaseEvent senderEvent = await FirebaseDatabase.instance
        .ref("users/$senderId")
        .once();

    DatabaseEvent receiverEvent = await FirebaseDatabase.instance
        .ref("users/$receiverId")
        .once();

    String senderName = "";
    String receiverName = "";

    if (senderEvent.snapshot.value != null) {
      Map<dynamic, dynamic> senderData =
      senderEvent.snapshot.value as Map<dynamic, dynamic>;
      senderName = senderData['name']?.toString() ?? await db.currentUserName;
    } else {
      senderName = await db.currentUserName;
    }

    if (receiverEvent.snapshot.value != null) {
      Map<dynamic, dynamic> receiverData =
      receiverEvent.snapshot.value as Map<dynamic, dynamic>;
      receiverName =
          receiverData['name']?.toString() ?? widget.user.name ?? "User";
    } else {
      receiverName = widget.user.name ?? "User";
    }

    Map<String, dynamic> messageDataForSender = {
      "senderId": senderId,
      "receverId": receiverId,
      "senderName": senderName,
      "receiverName": receiverName,
      "name": receiverName,
      "message": content,
      "timestamp": ServerValue.timestamp,
      "time": formattedTime,
      "day": dayText,
      "isSeen": true, // ✅ Sender अपना message देख रहा है
      "messageId": messageId, // ✅ ADD THIS
      "status": "sent", // ✅ ADD THIS
      "messageType": messageType,
    };

    // ✅ CORRECT: Receiver के chat में शुरू में isSeen: false
    Map<String, dynamic> messageDataForReceiver = {
      "senderId": senderId,
      "receverId": receiverId,
      "senderName": senderName,
      "receiverName": receiverName,
      "name": senderName,
      "message": content,
      "timestamp": ServerValue.timestamp,
      "time": formattedTime,
      "day": dayText,
      "isSeen": false, // ✅ Receiver ने अभी नहीं देखा
      "messageId": messageId, // ✅ ADD THIS
      "status": "sent", // ✅ ADD THIS
      "messageType": messageType,
    };

    if (messageType == "image" || messageType == "document") {
      messageDataForSender["fileName"] = fileName;
      messageDataForSender["fileExtension"] = fileExtension;
      messageDataForReceiver["fileName"] = fileName;
      messageDataForReceiver["fileExtension"] = fileExtension;
    }

    await Future.wait([
      myRef.set(messageDataForSender),
      otherRef.set(messageDataForReceiver),
    ]);

    print("✅ Message sent - Sender: isSeen=true, Receiver: isSeen=false");

    await _updateHomeScreenSummaries(
      content,
      senderId,
      receiverId,
      senderName,
      receiverName,
      messageType,
    );
  }

  // Function to send image as Base64
  Future<void> sendImageAsBase64(String base64Image, String fileName) async {
    String fileExtension = path.extension(fileName).toLowerCase();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 10),
            Text("Sending image..."),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    if (base64Image.length > 1000000) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Image too large (max 1MB)")));
      return;
    }

    await sendMessageToFirebase(
      base64Image,
      messageType: "image",
      fileName: fileName,
      fileExtension: fileExtension,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  // Function to send document as Base64
  Future<void> sendDocumentAsBase64(String base64Doc, String fileName) async {
    String fileExtension = path.extension(fileName).toLowerCase();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 10),
            Text("Sending document..."),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    if (base64Doc.length > 1000000) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Document too large (max 1MB)")));
      return;
    }

    await sendMessageToFirebase(
      base64Doc,
      messageType: "document",
      fileName: fileName,
      fileExtension: fileExtension,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  Widget _buildStatusIcon(MessageModel msg) {
    final theme = Theme.of(context);

    // If message is not from me, don't show status icon
    if (msg.senderId != db.currentUserUid) {
      return SizedBox();
    }

    if (msg.isSeen == true) {
      return Icon(
          Icons.done_all,
          size: _getResponsiveSize(10, 12),
          color: Colors.blue
      );
    } else {
      return Icon(
          Icons.done,
          size: _getResponsiveSize(10, 12),
          color: theme.textTheme.bodyMedium?.color
      );
    }
  }

  Widget _buildMessageBubbleDynamic(MessageModel msg) {
    bool isMe = msg.senderId == db.currentUserUid;
    String time = _formatTime(msg.timestamp);
    final theme = Theme.of(context);

    bool isDeletedForMe = msg.isDeletedForMe ?? false;
    bool isDeletedForEveryone = msg.isDeletedForEveryone ?? false;

    String displayText = msg.message;
    Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    FontStyle textStyle = FontStyle.normal;

    if (isDeletedForMe) {
      displayText = "This message was deleted";
      textColor =
          theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey;
      textStyle = FontStyle.italic;
    } else if (isDeletedForEveryone) {
      displayText = "This message was deleted";
      textColor =
          theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey;
      textStyle = FontStyle.italic;
    }
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              backgroundColor: theme.primaryColor,
              radius: _getResponsiveSize(14, 16),
              child: Text(
                widget.user.name![0].toUpperCase(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(10, 12)
                ),
              ),
            ),
          SizedBox(width: isMe ? 0 : _getResponsivePadding(6, 8)),
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                if (!isDeletedForMe && !isDeletedForEveryone) {
                  _showMessageOptions(msg, isMe);
                }
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery
                      .of(context)
                      .size
                      .width * 0.7,
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: _getResponsivePadding(12, 16),
                    vertical: _getResponsivePadding(8, 10)
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? theme.primaryColor.withOpacity(0.2)
                      : theme.brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: isMe ? Radius.circular(20) : Radius.circular(4),
                    bottomRight: isMe
                        ? Radius.circular(4)
                        : Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      style: TextStyle(
                        color: textColor,
                        fontSize: _getResponsiveFontSize(14, 16),
                        fontStyle: textStyle,
                      ),
                    ),
                    SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDeletedForEveryone || isDeletedForMe)
                            Icon(
                              Icons.delete_outline,
                              size: _getResponsiveSize(10, 12),
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                              fontSize: _getResponsiveFontSize(8, 10),
                            ),
                          ),
                          // ✅ YAHAN PE STATUS ICON AAYEGA
                          if (isMe) SizedBox(width: 4),
                          if (isMe && msg.isSeen == true)
                            Icon(
                                Icons.done_all,
                                size: _getResponsiveSize(10, 12),
                                color: Colors.blue
                            ),
                          if (isMe && msg.isSeen == false)
                            Icon(
                              Icons.done,
                              size: _getResponsiveSize(10, 12),
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: isMe ? _getResponsivePadding(6, 8) : 0),
          if (isMe)
            CircleAvatar(
              backgroundColor: theme.primaryColor,
              radius: _getResponsiveSize(14, 16),
              child: Text(
                db.currentUserUid.isNotEmpty
                    ? db.currentUserUid[0].toUpperCase()
                    : "Y",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(10, 12)
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileMessageBubble(MessageModel msg) {
    bool isMe = msg.senderId == db.currentUserUid;
    String time = _formatTime(msg.timestamp);
    final theme = Theme.of(context);

    String fileName = msg.fileName ?? "file";
    String fileExtension = msg.fileExtension ?? "";
    bool isImage = msg.messageType == "image";

    List<String> imageExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
    ];
    bool isImageFile =
        isImage && imageExtensions.contains(fileExtension.toLowerCase());

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              backgroundColor: theme.primaryColor,
              radius: _getResponsiveSize(14, 16),
              child: Text(
                widget.user.name![0].toUpperCase(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(10, 12)
                ),
              ),
            ),
          SizedBox(width: isMe ? 0 : _getResponsivePadding(6, 8)),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery
                    .of(context)
                    .size
                    .width * 0.7,
              ),
              padding: EdgeInsets.symmetric(
                  horizontal: _getResponsivePadding(6, 8),
                  vertical: _getResponsivePadding(6, 8)
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.primaryColor.withOpacity(0.2)
                    : theme.brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: isMe ? Radius.circular(20) : Radius.circular(4),
                  bottomRight: isMe ? Radius.circular(4) : Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isImageFile)
                    ImageLoader(
                      base64String: msg.message,
                      cacheKey: "${msg.timestamp}_${msg.message.hashCode}",
                      onTap: (bytes) => _showImageFullScreen(bytes),
                    )
                  else
                    Container(
                      width: 200,
                      padding: EdgeInsets.all(_getResponsivePadding(10, 12)),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey.shade900
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: theme.dividerColor ?? Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: theme.primaryColor,
                            size: _getResponsiveSize(30, 40),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName.length > 20
                                      ? fileName.substring(0, 20) + "..."
                                      : fileName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: _getResponsiveFontSize(12, 14),
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  fileExtension.isNotEmpty
                                      ? fileExtension.toUpperCase().replaceAll(
                                    '.',
                                    '',
                                  ) +
                                      " File"
                                      : "File",
                                  style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color,
                                    fontSize: _getResponsiveFontSize(10, 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _saveFile(msg.message, fileName);
                            },
                            icon: Icon(
                              Icons.download,
                              color: theme.primaryColor,
                              size: _getResponsiveSize(20, 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                            fontSize: _getResponsiveFontSize(8, 10),
                          ),
                        ),
                        // ✅ YAHAN PE STATUS ICON AAYEGA
                        if (isMe) SizedBox(width: 4),
                        if (isMe && msg.isSeen == true)
                          Icon(
                              Icons.done_all,
                              size: _getResponsiveSize(10, 12),
                              color: Colors.blue
                          ),
                        if (isMe && msg.isSeen == false)
                          Icon(
                            Icons.done,
                            size: _getResponsiveSize(10, 12),
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: isMe ? _getResponsivePadding(6, 8) : 0),
          if (isMe)
            CircleAvatar(
              backgroundColor: theme.primaryColor,
              radius: _getResponsiveSize(14, 16),
              child: Text(
                db.currentUserUid.isNotEmpty
                    ? db.currentUserUid[0].toUpperCase()
                    : "Y",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(10, 12)
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMessageOptions(MessageModel msg, bool isMyMessage) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  "Delete for me",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessageForMe(msg);
                },
              ),

              if (isMyMessage) // Only show "Delete for everyone" for sender's messages
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(
                    "Delete for everyone",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessageForEveryone(msg);
                  },
                ),

              Divider(color: theme.dividerColor),
              ListTile(
                leading: Icon(
                  Icons.copy,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                title: Text(
                  "Copy",
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.message));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Copied to clipboard")),
                  );
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.cancel,
                  color: theme.textTheme.bodyLarge?.color,
                ),
                title: Text(
                  "Cancel",
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // Delete message only for current user - SIMPLIFIED VERSION
  Future<void> _deleteMessageForMe(MessageModel msg) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            Center(
              child: CircularProgressIndicator(
                color: Theme
                    .of(context)
                    .primaryColor,
              ),
            ),
      );

      String currentUserId = db.currentUserUid;
      String otherUserId = msg.senderId == currentUserId
          ? msg.receverId
          : msg.senderId;

      DatabaseReference chatsRef = FirebaseDatabase.instance.ref(
        "Chats/$currentUserId/$otherUserId",
      );

      DataSnapshot snapshot = (await chatsRef.once()).snapshot;

      if (snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        for (var key in data.keys) {
          var value = data[key];
          if (value != null) {
            Map<String, dynamic> messageData = Map<String, dynamic>.from(value);

            // Match by message content and senderId
            if (messageData['message'] == msg.message &&
                messageData['senderId'] == msg.senderId) {
              DatabaseReference messageRef = chatsRef.child(key.toString());

              await messageRef.update({
                'isDeletedForMe': true,
                'deletedAt': ServerValue.timestamp,
                'originalMessage': msg.message,
              });

              Navigator.pop(context); // Close loading dialog

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Message deleted for you"),
                  backgroundColor: Colors.green,
                ),
              );

              await _updateHomeScreenSummaryAfterDelete(
                currentUserId,
                otherUserId,
              );

              // Refresh messages
              setState(() {
                _messagesStream = getCombinedMessages();
              });

              return;
            }
          }
        }
      }

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not find message to delete")),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print("Error deleting message for me: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete message")));
    }
  }

  // Delete message for everyone - SIMPLIFIED VERSION
  Future<void> _deleteMessageForEveryone(MessageModel msg) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            Center(
              child: CircularProgressIndicator(
                color: Theme
                    .of(context)
                    .primaryColor,
              ),
            ),
      );

      String currentUserId = db.currentUserUid;
      String otherUserId = msg.receverId;

      DatabaseReference myChatsRef = FirebaseDatabase.instance.ref(
        "Chats/$currentUserId/$otherUserId",
      );

      DatabaseReference otherChatsRef = FirebaseDatabase.instance.ref(
        "Chats/$otherUserId/$currentUserId",
      );

      DataSnapshot mySnapshot = (await myChatsRef.once()).snapshot;

      if (mySnapshot.value != null) {
        Map<dynamic, dynamic> data = mySnapshot.value as Map<dynamic, dynamic>;

        for (var key in data.keys) {
          var value = data[key];
          if (value != null) {
            Map<String, dynamic> messageData = Map<String, dynamic>.from(value);

            // Match by message content and senderId
            if (messageData['message'] == msg.message &&
                messageData['senderId'] == msg.senderId) {
              String messageId = key.toString();

              // Update in current user's chat
              DatabaseReference myMessageRef = myChatsRef.child(messageId);
              DatabaseReference otherMessageRef = otherChatsRef.child(
                messageId,
              );

              await Future.wait([
                myMessageRef.update({
                  'isDeletedForEveryone': true,
                  'message': 'This message was deleted',
                  'deletedAt': ServerValue.timestamp,
                  'originalMessage': msg.message,
                }),

                otherMessageRef.update({
                  'isDeletedForEveryone': true,
                  'message': 'This message was deleted',
                  'deletedAt': ServerValue.timestamp,
                  'originalMessage': msg.message,
                }),
              ]);

              Navigator.pop(context); // Close loading dialog

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Message deleted for everyone"),
                  backgroundColor: Colors.green,
                ),
              );

              await _updateHomeScreenSummaryAfterDeleteForEveryone(
                currentUserId,
                otherUserId,
                msg,
              );

              // Refresh messages
              setState(() {
                _messagesStream = getCombinedMessages();
              });

              return;
            }
          }
        }
      }

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not find message to delete")),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print("Error deleting message for everyone: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete message")));
    }
  }

  // ✅ Update HomeScreen summary after deleting message for me
  Future<void> _updateHomeScreenSummaryAfterDelete(String currentUserId,
      String otherUserId,) async {
    try {
      DatabaseReference chatsRef = FirebaseDatabase.instance.ref(
        "Chats/$currentUserId/$otherUserId",
      );

      DatabaseReference summaryRef = FirebaseDatabase.instance.ref(
        "ChatSummaries/$currentUserId/$otherUserId",
      );

      DataSnapshot snapshot = (await chatsRef.once()).snapshot;

      String lastMessage = "";
      dynamic lastTimestamp = 0;
      String messageType = "text";

      if (snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        // Find the latest non-deleted message
        for (var value in data.values) {
          if (value != null) {
            Map<String, dynamic> messageData = Map<String, dynamic>.from(value);

            bool isDeletedForMe = messageData['isDeletedForMe'] ?? false;
            bool isDeletedForEveryone =
                messageData['isDeletedForEveryone'] ?? false;

            // Skip deleted messages
            if (isDeletedForMe || isDeletedForEveryone) {
              continue;
            }

            dynamic timestamp = messageData['timestamp'];
            int timestampInt = _getTimestampAsInt(timestamp);

            if (timestampInt > _getTimestampAsInt(lastTimestamp)) {
              lastTimestamp = timestamp;
              lastMessage = messageData['message']?.toString() ?? "";
              messageType = messageData['messageType']?.toString() ?? "text";
            }
          }
        }
      }

      // Update the summary
      if (lastMessage.isNotEmpty) {
        await summaryRef.update({
          'lastMessage': _getMessagePreview(lastMessage, messageType),
          'lastMessageTime': lastTimestamp,
          'formattedTime': _formatTime(lastTimestamp),
          'updatedAt': ServerValue.timestamp,
        });
      } else {
        // If all messages are deleted, update with a placeholder
        await summaryRef.update({
          'lastMessage': "No messages",
          'lastMessageTime': ServerValue.timestamp,
          'formattedTime': _formatTime(DateTime
              .now()
              .millisecondsSinceEpoch),
          'updatedAt': ServerValue.timestamp,
        });
      }

      print("✅ HomeScreen summary updated after delete");
    } catch (e) {
      print("Error updating home screen summary after delete: $e");
    }
  }

  // ✅ Update HomeScreen summaries for both users after delete for everyone
  Future<void> _updateHomeScreenSummaryAfterDeleteForEveryone(
      String currentUserId,
      String otherUserId,
      MessageModel deletedMsg,) async {
    try {
      // Get user info for both users
      DatabaseEvent currentUserEvent = await FirebaseDatabase.instance
          .ref("users/$currentUserId")
          .once();

      DatabaseEvent otherUserEvent = await FirebaseDatabase.instance
          .ref("users/$otherUserId")
          .once();

      String currentUserName = "";
      String otherUserName = "";

      if (currentUserEvent.snapshot.value != null) {
        Map<dynamic, dynamic> userData =
        currentUserEvent.snapshot.value as Map<dynamic, dynamic>;
        currentUserName = userData['name']?.toString() ?? "User";
      }

      if (otherUserEvent.snapshot.value != null) {
        Map<dynamic, dynamic> userData =
        otherUserEvent.snapshot.value as Map<dynamic, dynamic>;
        otherUserName = userData['name']?.toString() ?? "User";
      }

      // Update summaries for both users
      await Future.wait([
        _updateHomeScreenSummaryForUser(
          currentUserId,
          otherUserId,
          otherUserName,
        ),
        _updateHomeScreenSummaryForUser(
          otherUserId,
          currentUserId,
          currentUserName,
        ),
      ]);

      print(
        "✅ HomeScreen summaries updated for both users after delete for everyone",
      );
    } catch (e) {
      print("Error updating home screen summaries for both users: $e");
    }
  }

  // ✅ Helper function to update summary for a specific user
  Future<void> _updateHomeScreenSummaryForUser(String userId,
      String otherUserId,
      String otherUserName,) async {
    try {
      DatabaseReference chatsRef = FirebaseDatabase.instance.ref(
        "Chats/$userId/$otherUserId",
      );

      DatabaseReference summaryRef = FirebaseDatabase.instance.ref(
        "ChatSummaries/$userId/$otherUserId",
      );

      DataSnapshot snapshot = (await chatsRef.once()).snapshot;

      String lastMessage = "";
      dynamic lastTimestamp = 0;
      String messageType = "text";
      bool foundMessage = false;

      if (snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        // Find the latest non-deleted message
        for (var value in data.values) {
          if (value != null) {
            Map<String, dynamic> messageData = Map<String, dynamic>.from(value);

            bool isDeletedForMe = messageData['isDeletedForMe'] ?? false;
            bool isDeletedForEveryone =
                messageData['isDeletedForEveryone'] ?? false;

            // Skip deleted messages
            if (isDeletedForMe || isDeletedForEveryone) {
              continue;
            }

            foundMessage = true;
            dynamic timestamp = messageData['timestamp'];
            int timestampInt = _getTimestampAsInt(timestamp);

            if (timestampInt > _getTimestampAsInt(lastTimestamp)) {
              lastTimestamp = timestamp;
              lastMessage = messageData['message']?.toString() ?? "";
              messageType = messageData['messageType']?.toString() ?? "text";
            }
          }
        }
      }

      // Calculate unread count
      int unreadCount = await _calculateUnreadCount(userId, otherUserId);

      // Get user's online status
      DatabaseEvent userEvent = await FirebaseDatabase.instance
          .ref("users/$otherUserId")
          .once();

      bool isOnline = false;
      DateTime? lastSeen;

      if (userEvent.snapshot.value != null) {
        Map<dynamic, dynamic> userData =
        userEvent.snapshot.value as Map<dynamic, dynamic>;
        isOnline = userData['isOnline'] ?? false;
        if (userData['lastSeen'] != null) {
          lastSeen = DateTime.tryParse(userData['lastSeen'].toString());
        }
      }

      // Get avatar URL
      String avatarUrl = "no";
      final avatarEvent = await FirebaseDatabase.instance
          .ref("users/$otherUserId")
          .once();

      if (avatarEvent.snapshot.value != null) {
        final userData = Map<String, dynamic>.from(
          avatarEvent.snapshot.value as Map<dynamic, dynamic>,
        );
        avatarUrl = userData['avatarUrl']?.toString() ?? "no";
      }

      // Update the summary
      if (foundMessage && lastMessage.isNotEmpty) {
        await summaryRef.set({
          'chatId': otherUserId,
          'lastMessage': _getMessagePreview(lastMessage, messageType),
          'lastMessageTime': lastTimestamp,
          'formattedTime': _formatTime(lastTimestamp),
          'unreadCount': unreadCount,
          'isOnline': isOnline,
          'avatarUrl': avatarUrl,
          'lastSeen': lastSeen?.toIso8601String(),
          'chatPartnerName': otherUserName,
          'name': otherUserName,
          'isTyping': false,
          'messageType': messageType,
          'updatedAt': ServerValue.timestamp,
        });
      } else {
        // If all messages are deleted or no messages exist
        await summaryRef.set({
          'chatId': otherUserId,
          'lastMessage': "No messages",
          'lastMessageTime': ServerValue.timestamp,
          'formattedTime': _formatTime(DateTime
              .now()
              .millisecondsSinceEpoch),
          'unreadCount': 0,
          'isOnline': isOnline,
          'avatarUrl': avatarUrl,
          'lastSeen': lastSeen?.toIso8601String(),
          'chatPartnerName': otherUserName,
          'name': otherUserName,
          'isTyping': false,
          'messageType': "text",
          'updatedAt': ServerValue.timestamp,
        });
      }
    } catch (e) {
      print("Error updating home screen summary for user $userId: $e");
    }
  }
}

// ✅ New widget for cached network avatar
class CachedNetworkAvatar extends StatefulWidget {
  final String url;
  final String userName;

  const CachedNetworkAvatar({
    required this.url,
    required this.userName,
  });

  @override
  _CachedNetworkAvatarState createState() => _CachedNetworkAvatarState();
}

class _CachedNetworkAvatarState extends State<CachedNetworkAvatar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Image.network(
      widget.url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle
          ),
          child: Center(
            child: Text(
              widget.userName.isNotEmpty
                  ? widget.userName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: _getResponsiveFontSize(context, 12, 14),
              ),
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
            color: theme.primaryColor,
          ),
        );
      },
    );
  }

  double _getResponsiveFontSize(BuildContext context, double small,
      double large) {
    final screenSize = MediaQuery
        .of(context)
        .size;
    if (screenSize.width > 600) {
      return large * 1.1; // Tablet
    } else if (screenSize.width <= 360) {
      return small; // Small phone
    }
    return large; // Normal phone
  }
}

class ImageLoader extends StatefulWidget {
  final String base64String;
  final String cacheKey;
  final Function(Uint8List) onTap;

  ImageLoader({
    required this.base64String,
    required this.cacheKey,
    required this.onTap,
  });

  @override
  _ImageLoaderState createState() => _ImageLoaderState();
}

class _ImageLoaderState extends State<ImageLoader> {
  late Future<Uint8List?> _imageFuture;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _imageFuture = _decodeImage();
  }

  Future<Uint8List?> _decodeImage() async {
    try {
      if (_ChatScreenState._imageCache.containsKey(widget.cacheKey)) {
        return _ChatScreenState._imageCache[widget.cacheKey];
      }

      String cleanedBase64 = widget.base64String.replaceAll(RegExp(r'\s+'), '');

      if (!RegExp(r'^[a-zA-Z0-9+/]*={0,2}$').hasMatch(cleanedBase64)) {
        _hasError = true;
        return null;
      }

      int padding = 4 - (cleanedBase64.length % 4);
      if (padding < 4) {
        cleanedBase64 += '=' * padding;
      }

      Uint8List bytes = base64Decode(cleanedBase64);

      _ChatScreenState._imageCache[widget.cacheKey] = bytes;

      return bytes;
    } catch (e) {
      print("Error decoding image: $e");
      _hasError = true;
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Uint8List?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 200,
            height: 150,
            color: theme.brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey[300],
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey.shade700
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        }

        if (_hasError || snapshot.hasError || !snapshot.hasData) {
          return Container(
            width: 200,
            height: 150,
            color: theme.brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey[300],
            child: Center(
              child: Icon(
                  Icons.broken_image,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                  size: 30
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () => widget.onTap(snapshot.data!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              snapshot.data!,
              width: 200,
              height: 150,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
            ),
          ),
        );
      },
    );
  }
}