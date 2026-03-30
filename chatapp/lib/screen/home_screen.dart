import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart'; // यह import add करें
import '../models/chat_user.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'chat_screen.dart';
import 'accept_request_user.dart';
import 'add_contact_screen.dart';
import 'profile_screen.dart';
import 'request_user.dart';
import 'login_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Lists and Data
  List<MessageModel> _chatList = [];
  List<ChatUser> _filteredUsers = [];
  List<ChatUser> _searchResults = [];

  // State flags
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasConversations = false;
  String _currentUserId = '';

  // Firebase References
  late DatabaseReference _chatSummariesRef;
  final DataBaseService _db = DataBaseService();
  final AuthService _auth = AuthService();

  // User Profile
  String? _userAvatarUrl;
  bool _isAvatarLoading = true;

  // Search
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  FocusNode _searchFocusNode = FocusNode();

  // Stream Subscriptions
  StreamSubscription? _avatarSubscription;
  StreamSubscription? _chatSummariesSubscription;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Online Status Management
  Map<String, bool> _userOnlineStatus = {};
  Map<String, StreamSubscription> _onlineStatusSubscriptions = {};

  // Timers
  Timer? _searchDebounce;
  Timer? _initDelayTimer;

  // Performance
  final _debounceDuration = const Duration(milliseconds: 300);
  final _initDelay = const Duration(seconds: 1);

  // Image Cache
  final Map<String, ImageProvider> _imageCache = {};
  final Map<String, String> _avatarCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _setUserOnline();
        break;
      case AppLifecycleState.paused:
        _setUserOffline();
        break;
      default:
        break;
    }
  }

  void _initializeApp() async {
    // Delay initialization for better UX
    await Future.delayed(const Duration(milliseconds: 100));
    await _getCurrentUser();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  @override
  void dispose() {
    _cleanupResources();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _cleanupResources() {
    // Cancel all timers
    _searchDebounce?.cancel();
    _initDelayTimer?.cancel();

    // Cancel all subscriptions
    _avatarSubscription?.cancel();
    _chatSummariesSubscription?.cancel();

    // Cancel online status subscriptions
    _onlineStatusSubscriptions.forEach((userId, subscription) {
      subscription.cancel();
    });
    _onlineStatusSubscriptions.clear();

    // Dispose controllers
    _searchController.dispose();
    _searchFocusNode.dispose();

    // Clear image cache
    _imageCache.clear();
    _avatarCache.clear();
  }

  // ========== SEARCH METHODS ==========
  void _onSearchFocusChange() {
    if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults.clear();
        });
      }
    }
  }

  void _onSearchTextChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_debounceDuration, () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (!mounted) return;

    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    final results = _filteredUsers.where((user) {
      return user.name.toLowerCase().contains(lowerQuery) ||
          (user.email?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    if (mounted) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
    }
    _searchFocusNode.unfocus();
  }

  // ========== USER STATUS METHODS ==========
  Future<void> _setUserOnline() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await _db.updateUserStatus(true);
        debugPrint('✅ User set online');
      }
    } catch (e) {
      debugPrint('❌ Error setting user online: $e');
    }
  }

  Future<void> _setUserOffline() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await _db.updateUserStatus(false);
        debugPrint('✅ User set offline');
      }
    } catch (e) {
      debugPrint('❌ Error setting user offline: $e');
    }
  }


  // ========== USER DATA METHODS ==========
  Future<void> _getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        _currentUserId = currentUser.uid;
        _chatSummariesRef = FirebaseDatabase.instance
            .ref("ChatSummaries/$_currentUserId");

        await _loadInitialData();
        _loadUserAvatar();
        await _setUserOnline();
      } else {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting current user: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadInitialData() async {
    try {
      _chatSummariesSubscription?.cancel();

      _chatSummariesSubscription = _chatSummariesRef.onValue.listen(
            (DatabaseEvent event) {
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            _processChatSummaries(data).then((_) {
              _startOnlineStatusListeners();
            });
          } else {
            if (mounted) {
              setState(() {
                _chatList.clear();
                _hasConversations = false;
                _filteredUsers.clear();
                _isLoading = false;
              });
            }
          }
        },
        onError: (error) {
          debugPrint('❌ Chat summaries error: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );

    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Clear cache before refresh
      _avatarCache.clear();
      _imageCache.clear();
      await _loadInitialData();
      await _loadUserAvatar();
    } catch (e) {
      debugPrint('❌ Error refreshing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // ========== CHAT PROCESSING METHODS ==========
  Future<void> _processChatSummaries(Map<dynamic, dynamic> data) async {
    try {
      List<Future<MessageModel>> chatFutures = [];

      data.forEach((chatId, chatData) {
        if (chatData != null) {
          chatFutures.add(_processSingleChatSummary(chatId, chatData));
        }
      });

      final chats = await Future.wait(chatFutures);

      // Sort by timestamp (newest first)
      chats.sort((a, b) {
        final timeA = (a.timestamp is int) ? a.timestamp as int : 0;
        final timeB = (b.timestamp is int) ? b.timestamp as int : 0;
        return timeB.compareTo(timeA);
      });

      if (mounted) {
        setState(() {
          _chatList = chats;
          _hasConversations = chats.isNotEmpty;
          _filteredUsers = _convertToChatUsers(chats);
          _isLoading = false;
        });
      }

    } catch (e) {
      debugPrint('❌ Error processing chat summaries: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<MessageModel> _processSingleChatSummary(String chatId, dynamic chatData) async {
    try {
      final chatMap = Map<String, dynamic>.from(chatData);
      final chatPartnerId = chatMap['chatId']?.toString() ?? '';

      String avatarUrl = "no";
      bool isOnline = false;
      DateTime? lastSeen;

      if (chatPartnerId.isNotEmpty) {
        // Check cache first
        if (_avatarCache.containsKey(chatPartnerId)) {
          avatarUrl = _avatarCache[chatPartnerId]!;
        } else {
          try {
            final partnerSnapshot = await FirebaseDatabase.instance
                .ref("users")
                .child(chatPartnerId)
                .once();

            if (partnerSnapshot.snapshot.value != null) {
              final partnerData = Map<String, dynamic>.from(
                  partnerSnapshot.snapshot.value as Map<dynamic, dynamic>);

              avatarUrl = partnerData['avatarUrl']?.toString() ?? "no";
              isOnline = partnerData['isOnline'] == true;

              if (partnerData['lastSeen'] != null) {
                lastSeen = DateTime.tryParse(partnerData['lastSeen'].toString());
              }

              // Cache the avatar URL
              _avatarCache[chatPartnerId] = avatarUrl;
            }
          } catch (e) {
            debugPrint('⚠️ Error fetching data for $chatPartnerId: $e');
          }
        }
      }

      return MessageModel(
        senderId: chatPartnerId,
        receverId: _currentUserId,
        message: chatMap['lastMessage']?.toString() ?? '',
        timestamp: chatMap['lastMessageTime'] is int
            ? chatMap['lastMessageTime']
            : int.tryParse(chatMap['lastMessageTime']?.toString() ?? '0') ?? 0,
        day: 'Today',
        isSeen: true,
        messageType: chatMap['messageType']?.toString() ?? 'text',
        name: chatMap['name']?.toString() ?? chatMap['chatPartnerName']?.toString() ?? 'Unknown',
        lastmessage: chatMap['lastMessage']?.toString() ?? '',
        time: chatMap['formattedTime']?.toString() ?? '',
        unreadCount: (chatMap['unreadCount'] is int)
            ? chatMap['unreadCount']
            : int.tryParse(chatMap['unreadCount']?.toString() ?? '0') ?? 0,
        isOnline: isOnline,
        avatarUrl: avatarUrl,
        lastSeen: lastSeen,
        chatPartnerName: chatMap['chatPartnerName']?.toString() ?? 'Unknown',
      );
    } catch (e) {
      debugPrint('❌ Error parsing chat summary: $e');
      return MessageModel(
        senderId: '',
        receverId: _currentUserId,
        message: '',
        timestamp: 0,
        day: 'Today',
        isSeen: true,
        messageType: 'text',
        name: 'Unknown',
        lastmessage: '',
        time: '',
        unreadCount: 0,
        isOnline: false,
        avatarUrl: "no",
      );
    }
  }

  void _startOnlineStatusListeners() {
    // Cleanup old subscriptions
    _onlineStatusSubscriptions.forEach((userId, subscription) {
      subscription.cancel();
    });
    _onlineStatusSubscriptions.clear();
    _userOnlineStatus.clear();

    // Start new listeners
    for (final chat in _chatList) {
      if (chat.senderId.isNotEmpty && !_onlineStatusSubscriptions.containsKey(chat.senderId)) {
        _listenToOnlineStatus(chat.senderId);
      }
    }
  }

  void _listenToOnlineStatus(String userId) {
    if (_onlineStatusSubscriptions.containsKey(userId)) return;

    final userRef = FirebaseDatabase.instance.ref("users").child(userId);

    final subscription = userRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<String, dynamic>.from(
            event.snapshot.value as Map<dynamic, dynamic>);

        final bool isOnline = data['isOnline'] == true;

        setState(() {
          _userOnlineStatus[userId] = isOnline;
          _updateChatOnlineStatus(userId, isOnline);
        });
      }
    }, onError: (error) {
      debugPrint('❌ Error listening to online status for $userId: $error');
    });

    _onlineStatusSubscriptions[userId] = subscription;
  }

  void _updateChatOnlineStatus(String userId, bool isOnline) {
    final index = _chatList.indexWhere((chat) => chat.senderId == userId);
    if (index != -1) {
      setState(() {
        _chatList[index] = _chatList[index].copyWith(isOnline: isOnline);
        _filteredUsers = _convertToChatUsers(_chatList);
      });
    }
  }

  List<ChatUser> _convertToChatUsers(List<MessageModel> chats) {
    return chats.map((chat) {
      final isOnline = _userOnlineStatus[chat.senderId] ?? chat.isOnline ?? false;

      return ChatUser(
        uid: chat.senderId,
        name: chat.name ?? 'Unknown',
        email: '',
        avatarUrl: chat.avatarUrl ?? "no",
        isOnline: isOnline,
        lastSeen: chat.lastSeen,
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  // ========== AVATAR METHODS ==========
  Future<void> _loadUserAvatar() async{
    try {
      final userRef = FirebaseDatabase.instance.ref("users").child(_currentUserId);

      _avatarSubscription?.cancel();
      _avatarSubscription = userRef.onValue.listen((DatabaseEvent event) {
        if (event.snapshot.value != null && mounted) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          final avatarUrl = data['avatarUrl']?.toString();

          setState(() {
            _userAvatarUrl = avatarUrl;
            _isAvatarLoading = false;
          });

          // Cache the avatar
          if (avatarUrl != null) {
            _avatarCache[_currentUserId] = avatarUrl;
          }
        } else if (mounted) {
          setState(() {
            _userAvatarUrl = null;
            _isAvatarLoading = false;
          });
        }
      }, onError: (error) {
        debugPrint('❌ Error loading user avatar: $error');
        if (mounted) {
          setState(() {
            _isAvatarLoading = false;
          });
        }
      });
    } catch (e) {
      debugPrint('❌ Error in _loadUserAvatar: $e');
      if (mounted) {
        setState(() {
          _isAvatarLoading = false;
        });
      }
    }
  }

  Widget _buildProfileAvatar(bool isTablet) {
    if (_isAvatarLoading) {
      return CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: SizedBox(
          width: isTablet ? 20 : 16,
          height: isTablet ? 20 : 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    final hasAvatar = _userAvatarUrl != null &&
        _userAvatarUrl!.isNotEmpty &&
        _userAvatarUrl! != "no";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
      },
      child: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        backgroundImage: hasAvatar ? _getCachedImageProvider(_userAvatarUrl!) : null,
        child: hasAvatar
            ? null
            : Icon(
          Icons.person,
          color: Theme.of(context).primaryColor,
          size: isTablet ? 28 : 24,
        ),
      ),
    );
  }

  ImageProvider? _getCachedImageProvider(String url) {
    try {
      // Check cache first
      if (_imageCache.containsKey(url)) {
        return _imageCache[url];
      }

      ImageProvider? provider;

      if (url.isNotEmpty &&
          url != "no" &&
          (url.startsWith('data:image') ||
              (url.length > 100 && !url.startsWith('http')))) {
        try {
          String cleanBase64 = url;
          if (url.contains(',')) {
            cleanBase64 = url.split(',').last;
          }
          Uint8List bytes = base64Decode(cleanBase64);
          provider = MemoryImage(bytes);
          _imageCache[url] = provider;
        } catch (e) {
          debugPrint('❌ Error decoding base64 avatar: $e');
          return null;
        }
      } else if (url.startsWith('http')) {
        provider = CachedNetworkImageProvider(url);
        _imageCache[url] = provider;
      }

      return provider;
    } catch (e) {
      debugPrint('❌ Error getting image provider: $e');
      return null;
    }
  }

  // ========== UI BUILDING METHODS ==========
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isSmallScreen = screenSize.width <= 360;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: _isSearching ? null : Padding(
          padding: EdgeInsets.all(isTablet ? 12.0 : 8.0),
          child: _buildProfileAvatar(isTablet),
        ),
        title: _isSearching
            ? _buildSearchField(screenSize, isSmallScreen, isTablet, theme)
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chats',
              style: TextStyle(
                fontSize: isTablet ? 28 : isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            Text(
              _isLoading ? 'Loading...' :
              _hasConversations ? '${_chatList.length} conversations' : 'Start your first conversation',
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        actions: _buildAppBarActions(isSmallScreen, isTablet, theme),
        toolbarHeight: isTablet ? 80 : 70,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: _isLoading
          ? _buildLoadingScreen(theme)
          : _hasConversations
          ? _buildChatList(screenSize, isSmallScreen, isTablet, theme)
          : _buildEmptyState(screenSize, isSmallScreen, isTablet, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatOptions,
        backgroundColor: theme.primaryColor,
        child: Icon(
          Icons.message,
          color: Colors.white,
          size: isTablet ? 28 : 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildSearchField(Size screenSize, bool isSmallScreen, bool isTablet, ThemeData theme) {
    return Container(
      width: screenSize.width * 0.8,
      height: isTablet ? 50 : 40,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(width: 12),
          Icon(
            Icons.search,
            color: theme.brightness == Brightness.dark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            size: isTablet ? 24 : 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchTextChanged,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: theme.textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: TextStyle(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade500,
                  fontSize: isTablet ? 14 : 12,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              cursorColor: theme.primaryColor,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
                size: isTablet ? 20 : 16,
              ),
              onPressed: _clearSearch,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions(bool isSmallScreen, bool isTablet, ThemeData theme) {
    if (_isSearching) {
      return [
        IconButton(
          icon: Icon(
            Icons.close,
            size: isTablet ? 28 : 24,
            color: theme.iconTheme.color,
          ),
          onPressed: _clearSearch,
        ),
      ];
    } else {
      return [
        IconButton(
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _searchFocusNode.requestFocus();
            });
          },
          icon: Icon(
            Icons.search,
            size: isTablet ? 28 : 24,
            color: theme.iconTheme.color,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'profile':
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
                break;
              case 'new_request':
                Navigator.push(context, MaterialPageRoute(builder: (context) => RequestUserList()));
                break;
              case 'refresh':
                await _refreshData();
                break;
              case 'logout':
                await _performLogout();
                break;
            }
          },
          color: theme.cardColor,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: theme.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Refresh",
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "My Profile",
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'new_request',
              child: Row(
                children: [
                  Icon(Icons.group_add, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "New Request",
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuDivider(
              color: theme.dividerColor,
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Logout",
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
          icon: Icon(
            Icons.more_vert,
            size: isTablet ? 28 : 24,
            color: theme.iconTheme.color,
          ),
          padding: EdgeInsets.only(right: isTablet ? 16 : 12),
        )
      ];
    }
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Loading your chats...',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 16,
              ),
            ),
          ],
        )
    );
  }

  Widget _buildEmptyState(Size screenSize, bool isSmallScreen, bool isTablet, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: theme.primaryColor,
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 32 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenSize.height * 0.15),
              Container(
                width: isSmallScreen ? 150 : 200,
                height: isSmallScreen ? 150 : 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Color(0xFFF7FAFC),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: isSmallScreen ? 80 : 100,
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey.shade600
                      : Color(0xFFCBD5E0),
                ),
              ),
              SizedBox(height: 32),

              Text(
                'No Conversations Yet',
                style: TextStyle(
                  fontSize: isTablet ? 28 : 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              Text(
                'Start chatting with your friends and family.\nYour messages will appear here.',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: theme.textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: isTablet ? 56 : 50,
                child: ElevatedButton(
                  onPressed: _showNewChatOptions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: isSmallScreen ? 18 : 20),
                      SizedBox(width: 8),
                      Text(
                        'Start New Chat',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildChatList(Size screenSize, bool isSmallScreen, bool isTablet, ThemeData theme) {
    final displayUsers = _isSearching ? _searchResults : _filteredUsers;
    final displayChats = _isSearching
        ? _chatList.where((chat) =>
        displayUsers.any((user) => user.uid == chat.senderId))
        : _chatList;

    return SafeArea(
      child: Column(
        children: [
          if (!_isSearching && _filteredUsers.any((user) => user.isOnline))
            _buildOnlineUsersSection(screenSize, isSmallScreen, theme),

          if (_isSearching && _searchController.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Text(
                    'Search Results: ${_searchResults.length} found',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  Spacer(),
                  if (_searchResults.isNotEmpty)
                    TextButton(
                      onPressed: _clearSearch,
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: theme.primaryColor,
              backgroundColor: theme.scaffoldBackgroundColor,
              child: Stack(
                children: [
                  if (_isRefreshing)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        color: theme.primaryColor,
                        backgroundColor: Colors.transparent,
                        minHeight: 2,
                      ),
                    ),

                  ListView.builder(
                    itemCount: displayChats.length,
                    padding: EdgeInsets.only(top: _isRefreshing ? 2 : 0, bottom: 80),
                    physics: AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final chat = displayChats.elementAt(index);
                      final user = displayUsers.firstWhere(
                              (u) => u.uid == chat.senderId,
                          orElse: () => ChatUser(
                            uid: chat.senderId,
                            name: chat.name ?? 'Unknown',
                            email: '',
                            avatarUrl: chat.avatarUrl ?? "no",
                            isOnline: chat.isOnline ?? false,
                            lastSeen: chat.lastSeen,
                            createdAt: DateTime.now(),
                          ));

                      return _buildChatItem(chat, user, screenSize, isSmallScreen, isTablet, theme);
                    },
                  ),

                  if (_isSearching && displayChats.isEmpty && _searchController.text.isNotEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 60,
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No conversations found',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try searching with a different name',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineUsersSection(Size screenSize, bool isSmallScreen, ThemeData theme) {
    final onlineUsers = _filteredUsers.where((user) => user.isOnline).toList();

    if (onlineUsers.isEmpty) return SizedBox();

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 10 : 12,
        horizontal: isSmallScreen ? 12 : 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor ?? Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Online Now',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Spacer(),
              Text(
                '${onlineUsers.length} online',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: isSmallScreen ? 60 : 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: onlineUsers.length,
              itemBuilder: (context, index) {
                final user = onlineUsers[index];
                return Padding(
                  padding: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _openChatWithUser(user),
                        child: Stack(
                          children: [
                            Container(
                              width: isSmallScreen ? 40 : 48,
                              height: isSmallScreen ? 40 : 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: user.avatarUrl.isNotEmpty && user.avatarUrl != "no"
                                    ? _buildOptimizedAvatarImage(user.avatarUrl, user.name, isSmallScreen: true, theme: theme)
                                    : CircleAvatar(
                                  backgroundColor: theme.primaryColor,
                                  child: Text(
                                    user.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: isSmallScreen ? 10 : 12,
                                height: isSmallScreen ? 10 : 12,
                                decoration: BoxDecoration(
                                  color: Color(0xFF48BB78),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.cardColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        width: isSmallScreen ? 40 : 48,
                        child: Text(
                          user.name.split(' ').first,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 11,
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(MessageModel chat, ChatUser user, Size screenSize, bool isSmallScreen, bool isTablet, ThemeData theme) {
    final avatarRadius = isTablet ? 32.0 : isSmallScreen ? 24.0 : 26.0;
    final onlineIndicatorSize = isTablet ? 14.0 : isSmallScreen ? 10.0 : 12.0;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        onTap: () => _openChatWithUser(user),
        leading: Stack(
          children: [
            Container(
              width: avatarRadius * 2,
              height: avatarRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: user.avatarUrl.isNotEmpty && user.avatarUrl != "no"
                    ? _buildOptimizedAvatarImage(user.avatarUrl, user.name, theme: theme)
                    : CircleAvatar(
                  backgroundColor: theme.primaryColor,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: avatarRadius * 0.7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: onlineIndicatorSize,
                height: onlineIndicatorSize,
                decoration: BoxDecoration(
                  color: user.isOnline ? Color(0xFF48BB78) : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.cardColor,
                    width: onlineIndicatorSize * 0.15,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chat.name ?? user.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
            ),
            Text(
              chat.time ?? _formatTime(chat.timestamp),
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            if (chat.messageType == "image")
              Icon(
                Icons.photo,
                size: 14,
                color: theme.textTheme.bodyMedium?.color,
              )
            else if (chat.messageType == "document")
              Icon(
                Icons.insert_drive_file,
                size: 14,
                color: theme.textTheme.bodyMedium?.color,
              )
            else if (chat.messageType == "location")
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: theme.textTheme.bodyMedium?.color,
                ),
            if (chat.messageType != "text") SizedBox(width: 4),

            Expanded(
              child: Text(
                _getMessagePreview(chat.message, chat.messageType ?? "text"),
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: isTablet ? 16 : 14,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),

            if ((chat.unreadCount ?? 0) > 0)
              Container(
                width: isTablet ? 24 : 20,
                height: isTablet ? 24 : 20,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${chat.unreadCount}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 12 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade600
              : Color(0xFFCBD5E0),
          size: isTablet ? 24 : 20,
        ),
      ),
    );
  }

  Widget _buildOptimizedAvatarImage(String avatarUrl, String userName, {bool isSmallScreen = false, required ThemeData theme}) {
    try {
      if (avatarUrl.isNotEmpty && avatarUrl != "no") {
        if (avatarUrl.startsWith('data:image') ||
            (avatarUrl.length > 100 && !avatarUrl.startsWith('http'))) {
          // Base64 image
          try {
            String cleanBase64 = avatarUrl.contains(',') ? avatarUrl.split(',').last : avatarUrl;
            Uint8List bytes = base64Decode(cleanBase64);
            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackAvatar(userName, isSmallScreen: isSmallScreen, theme: theme);
              },
            );
          } catch (e) {
            debugPrint('❌ Error decoding base64: $e');
            return _buildFallbackAvatar(userName, isSmallScreen: isSmallScreen, theme: theme);
          }
        } else if (avatarUrl.startsWith('http')) {
          // Network image with caching
          return CachedNetworkImage(
            imageUrl: avatarUrl,
            imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primaryColor,
              ),
            ),
            errorWidget: (context, url, error) {
              return _buildFallbackAvatar(userName, isSmallScreen: isSmallScreen, theme: theme);
            },
          );
        }
      }

      return _buildFallbackAvatar(userName, isSmallScreen: isSmallScreen, theme: theme);
    } catch (e) {
      debugPrint('❌ Error building avatar image: $e');
      return _buildFallbackAvatar(userName, isSmallScreen: isSmallScreen, theme: theme);
    }
  }

  Widget _buildFallbackAvatar(String userName, {bool isSmallScreen = false, required ThemeData theme}) {
    return Container(
      color: theme.primaryColor,
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 14 : 18,
          ),
        ),
      ),
    );
  }

  // ========== UTILITY METHODS ==========
  String _formatTime(dynamic timestamp) {
    try {
      int time = timestamp is int ? timestamp : int.tryParse(timestamp.toString()) ?? 0;
      if (time == 0) return "";

      DateTime date = DateTime.fromMillisecondsSinceEpoch(time);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime yesterday = today.subtract(Duration(days: 1));
      DateTime messageDate = DateTime(date.year, date.month, date.day);

      if (messageDate == today) {
        return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      } else if (messageDate == yesterday) {
        return "Yesterday";
      } else {
        return "${date.day}/${date.month}/${date.year.toString().substring(2)}";
      }
    } catch (e) {
      return "";
    }
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

  Future<void> _performLogout() async {
    try {
      final shouldLogout = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldLogout != true) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );

      await _setUserOffline();
      await _auth.signOut();

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Start New Chat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.person_add, color: theme.primaryColor),
                title: Text(
                  'New Contact',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final selectedUser = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddContactScreen()),
                  );

                  if (selectedUser != null && mounted) {
                    _openChatWithUser(selectedUser);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.chat, color: theme.primaryColor),
                title: Text(
                  'Start Chat With Friend',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final selectedUser = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AcceptRequestUser()),
                  );
                  if (selectedUser != null && mounted) {
                    _openChatWithUser(selectedUser);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openChatWithUser(ChatUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          user: UserModel(
            uid: user.uid,
            name: user.name,
            email: user.email,
            isOnline: user.isOnline,
            avatarUrl: user.avatarUrl,
            lastSeen: user.lastSeen,
          ),
        ),
      ),
    );
  }
}