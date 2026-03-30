import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../Provider/themeprovider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isEditing = false;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final AuthService _auth = AuthService();
  late ThemeProvider _themeProvider;

  final List<String> _statusOptions = [
    "Available",
    "Busy",
    "At work",
    "In a meeting",
    "Sleeping",
    "Urgent calls only"
  ];

  @override
  void initState() {
    super.initState();
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _loadUserData();
    _loadThemePreference();
  }

  void _showThemeOptions() {
    // Get current theme from provider
    String currentTheme = _themeProvider.themePreference;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: theme.bottomSheetTheme.backgroundColor,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Theme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 20),

              // Light Theme Option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.light_mode,
                      color: Colors.amber,
                    ),
                  ),
                ),
                title: Text(
                  'Light',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: currentTheme == "Light"
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: currentTheme == "Light"
                    ? Icon(Icons.check, color: theme.primaryColor)
                    : null,
                onTap: () {
                  _changeTheme("Light");
                  Navigator.pop(context);
                },
              ),

              // Dark Theme Option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.dark_mode,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
                title: Text(
                  'Dark',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: currentTheme == "Dark"
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: currentTheme == "Dark"
                    ? Icon(Icons.check, color: theme.primaryColor)
                    : null,
                onTap: () {
                  _changeTheme("Dark");
                  Navigator.pop(context);
                },
              ),

              // System Default Option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.settings,
                      color: Colors.blue,
                    ),
                  ),
                ),
                title: Text(
                  'System Default',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: currentTheme == "System Default"
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: currentTheme == "System Default"
                    ? Icon(Icons.check, color: theme.primaryColor)
                    : null,
                onTap: () {
                  _changeTheme("System Default");
                  Navigator.pop(context);
                },
              ),

              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeTheme(String themeMode) async {
    try {
      // Update theme provider
      _themeProvider.setTheme(themeMode);

      // Save theme preference to Firebase
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _dbRef.child('users').child(currentUser.uid).update({
          'themePreference': themeMode,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme changed to $themeMode'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('Error changing theme: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change theme: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadThemePreference() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final snapshot = await _dbRef.child('users').child(currentUser.uid).child('themePreference').once();
        if (snapshot.snapshot.value != null) {
          final theme = snapshot.snapshot.value as String;
          _themeProvider.setTheme(theme);
        }
      }
    } catch (e) {
      print('Error loading theme preference: $e');
    }
  }

  Future<String> _convertImageToBase64(File imageFile) async {
    try {
      // Read image file as bytes
      List<int> imageBytes = await imageFile.readAsBytes();

      // Convert bytes to base64 string
      String base64Image = base64Encode(imageBytes);

      print('✅ Base64 conversion successful');
      print('📊 Base64 length: ${base64Image.length}');

      return base64Image;
    } catch (e) {
      print('❌ Error converting image to base64: $e');
      throw Exception('Failed to convert image to base64: $e');
    }
  }

  Future<void> _uploadProfileImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70, // Reduce quality for smaller base64
        maxWidth: 800, // Limit width
        maxHeight: 800, // Limit height
      );

      if (pickedFile != null) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          ),
        );

        File imageFile = File(pickedFile.path);

        // Convert image to base64
        String base64Image = await _convertImageToBase64(imageFile);

        // Get file size info
        int fileSizeInBytes = await imageFile.length();
        double fileSizeInKB = fileSizeInBytes / 1024;
        double fileSizeInMB = fileSizeInKB / 1024;

        print('📱 Image selected: ${pickedFile.path}');
        print('📊 Original file size: ${fileSizeInMB.toStringAsFixed(2)} MB');
        print('📊 Base64 string length: ${base64Image.length} characters');

        // Check if base64 string is too large
        if (base64Image.length > 1000000) { // 1MB limit
          Navigator.pop(context); // Remove loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image is too large (${fileSizeInMB.toStringAsFixed(1)}MB). Please choose a smaller image.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Store base64 in Firebase Database
        await _saveBase64ImageToDatabase(base64Image);

        // Remove loading dialog
        Navigator.pop(context);

        // Update UI
        setState(() {
          _profileImage = imageFile;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Remove loading dialog
      print('❌ Error uploading profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveBase64ImageToDatabase(String base64Image) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      print('💾 Saving base64 image to database...');

      // Save base64 string to Firebase Realtime Database
      await _dbRef.child('users').child(currentUser.uid).update({
        'avatarUrl': base64Image,
        'avatarType': 'base64',
        'avatarUpdated': DateTime.now().millisecondsSinceEpoch,
        'avatarSize': base64Image.length, // Store size for reference
      });

      print('✅ Base64 image saved to database successfully');

      // Update local user model
      if (_currentUser != null) {
        setState(() {
          _currentUser = _currentUser!.copyWith(
            avatarUrl: base64Image,
          );
        });
      }
    } catch (e) {
      print('❌ Error saving base64 image to database: $e');

      // Check Firebase error
      if (e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('Permission denied. Check Firebase rules.');
      } else if (e.toString().contains('NETWORK_ERROR')) {
        throw Exception('Network error. Check your internet connection.');
      } else {
        throw Exception('Failed to save image: $e');
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Fetch user data from Firebase Realtime Database
        final userRef = _dbRef.child('users').child(currentUser.uid);

        // Listen for real-time updates
        userRef.onValue.listen((DatabaseEvent event) {
          if (event.snapshot.value != null) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            final userData = UserModel.fromMap(data);

            setState(() {
              _currentUser = userData;
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        }, onError: (error) {
          print('Error loading user data: $error');
          setState(() {
            _isLoading = false;
          });
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in loadUserData: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserData(Map<String, dynamic> updateData) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _dbRef.child('users').child(currentUser.uid).update(updateData);

        // Update local user model
        if (_currentUser != null) {
          setState(() {
            _currentUser = _currentUser!.copyWith(
              name: updateData['name'] ?? _currentUser!.name,
              email: updateData['email'] ?? _currentUser!.email,
              mobileNo: updateData['mobileNo'] ?? _currentUser!.mobileNo,
              bio: updateData['bio'] ?? _currentUser!.bio,
              status: updateData['status'] ?? _currentUser!.status,
            );
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: theme.iconTheme.color,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            'My Profile',
            style: TextStyle(
              color: theme.textTheme.titleLarge?.color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 60,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                'User not found',
                style: TextStyle(
                  fontSize: 18,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please login again',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.iconTheme.color,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'My Profile',
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: theme.primaryColor,
            ),
            onPressed: () {
              if (_isEditing) {
                // Save all changes
                _saveProfileChanges();
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture Section
              Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.primaryColor,
                        width: 3.0,
                      ),
                    ),
                    child: ClipOval(
                      child: _profileImage != null
                          ? Image.file(
                        _profileImage!,
                        fit: BoxFit.cover,
                        width: 140,
                        height: 140,
                      )
                          : _currentUser!.avatarUrl != null &&
                          _currentUser!.avatarUrl!.isNotEmpty &&
                          _currentUser!.avatarUrl! != "no"
                          ? _buildBase64Image(_currentUser!.avatarUrl!)
                          : Container(
                        color: _currentUser!.avatarColor,
                        child: Center(
                          child: Text(
                            _currentUser!.initials,
                            style: TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.cardColor,
                            width: 3.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // User Name
              Text(
                _currentUser!.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 8),

              // User Email
              Text(
                _currentUser!.email ?? 'No email provided',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: 30),

              // Profile Info Cards
              _buildInfoCard(),

              SizedBox(height: 30),

              // Additional Settings
              _buildSettingsSection(),

              SizedBox(height: 40),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await _auth.signOut();
                    // Navigate to login screen
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.brightness == Brightness.dark
                        ? Colors.red.shade900.withOpacity(0.3)
                        : Colors.red.shade50,
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
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

  Widget _buildInfoCard() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.5)
                : Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status
          _buildEditableField(
            label: "Status",
            value: _currentUser!.status ?? "Hey there! I'm using ChatApp",
            isEditable: true,
            onTap: _showStatusOptions,
            icon: Icons.circle,
            iconColor: Colors.green,
          ),
          Divider(height: 30, color: theme.dividerColor),

          // Bio
          _buildEditableField(
            label: "Bio",
            value: _currentUser!.bio ?? 'No bio yet',
            isEditable: _isEditing,
            onTap: () => _editField("Bio", _currentUser!.bio ?? '', (newValue) {
              _updateUserData({'bio': newValue});
            }),
            icon: Icons.info_outline,
            iconColor: Theme.of(context).primaryColor,
          ),
          Divider(height: 30, color: theme.dividerColor),

          // Phone
          _buildEditableField(
            label: "Phone",
            value: _currentUser!.mobileNo ?? 'Not provided',
            isEditable: _isEditing,
            onTap: () => _editField("Phone", _currentUser!.mobileNo ?? '', (newValue) {
              _updateUserData({'mobileNo': newValue});
            }),
            icon: Icons.phone,
            iconColor: Color(0xFF48BB78),
          ),
          Divider(height: 30, color: theme.dividerColor),

          // Email
          _buildEditableField(
            label: "Email",
            value: _currentUser!.email ?? 'Not provided',
            isEditable: _isEditing,
            onTap: () => _editField("Email", _currentUser!.email ?? '', (newValue) {
              _updateUserData({'email': newValue});
            }),
            icon: Icons.email,
            iconColor: Color(0xFFED8936),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required bool isEditable,
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isEditable ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: isEditable ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (isEditable)
              Icon(
                Icons.edit,
                color: theme.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.5)
                : Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          _buildSettingItem(
            icon: Icons.color_lens,
            title: "Theme",
            subtitle: "Change app theme and appearance",
            onTap: _showThemeOptions,
            iconColor: Color(0xFFED8936),
          )
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: _currentUser?.avatarColor ?? Theme.of(context).primaryColor,
      child: Center(
        child: Text(
          _currentUser?.initials ?? 'U',
          style: TextStyle(
            fontSize: 40,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;

  Widget _buildBase64Image(String base64String) {
    try {
      if (base64String.isEmpty || base64String == 'no') {
        return _buildDefaultAvatar();
      }

      // Check if it's a URL (starts with http)
      if (base64String.startsWith('http')) {
        return Image.network(
          base64String,
          fit: BoxFit.cover,
          width: 140,
          height: 140,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: Theme.of(context).primaryColor,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ Network image error: $error');
            return _buildDefaultAvatar();
          },
        );
      }

      // Try to decode base64
      try {
        // Remove data URI prefix if present
        String cleanBase64 = base64String;
        if (base64String.contains(',')) {
          cleanBase64 = base64String.split(',').last;
        }

        Uint8List bytes = base64Decode(cleanBase64);

        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 140,
          height: 140,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Memory image error: $error');
            return _buildDefaultAvatar();
          },
        );
      } catch (decodeError) {
        print('❌ Base64 decode error: $decodeError');
        print('📊 Base64 string preview: ${base64String.substring(0, min(100, base64String.length))}...');
        return _buildDefaultAvatar();
      }
    } catch (e) {
      print('❌ Error in _buildBase64Image: $e');
      return _buildDefaultAvatar();
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: theme.bottomSheetTheme.backgroundColor,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt, color: theme.primaryColor),
                title: Text(
                  'Take Photo',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _uploadProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: theme.primaryColor),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _uploadProfileImage(ImageSource.gallery);
                },
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        print("Profile image selected: ${pickedFile.path}");
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  void _showStatusOptions() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      backgroundColor: theme.bottomSheetTheme.backgroundColor,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ..._statusOptions.map((status) {
                      return ListTile(
                        leading: Icon(
                          Icons.circle,
                          color: Colors.green,
                          size: 12,
                        ),
                        title: Text(
                          status,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        trailing: _currentUser!.status == status
                            ? Icon(Icons.check, color: theme.primaryColor)
                            : null,
                        onTap: () {
                          _updateUserData({'status': status});
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editField(String fieldName, String currentValue, Function(String) onSave) {
    if (!_isEditing) return;

    TextEditingController controller = TextEditingController(text: currentValue);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Text(
            'Edit $fieldName',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: 'Enter new $fieldName',
              hintStyle: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.dividerColor ?? Colors.grey,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.dividerColor ?? Colors.grey,
                ),
              ),
            ),
            maxLines: fieldName == "Bio" ? 3 : 1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onSave(controller.text);
                }
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: TextStyle(
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveProfileChanges() {
    print('Profile changes saved');
  }
}