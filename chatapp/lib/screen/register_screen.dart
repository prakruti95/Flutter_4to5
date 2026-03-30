import 'package:chat_application/services/auth_service.dart';
import 'package:chat_application/services/database_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController mobileNoController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _databaseService = DataBaseService();
  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  // ✅ YEH METHOD ADD KAREIN (VARIABLES KE BAAD, build METHOD SE PEHLE)
  Future<String?> _getFCMToken() async {
    try {
      // Notification permission lein
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional permission');
      } else {
        print('User declined or has not accepted permission');
      }

      // Token lein
      String? token = await FirebaseMessaging.instance.getToken();
      print("FCM Token generated: $token");
      return token;
    } catch (e) {
      print("Error getting FCM token: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            final isDesktop = constraints.maxWidth >= 1024;

            return SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? constraints.maxWidth * 0.2 :
                  isTablet ? constraints.maxWidth * 0.1 : 20.0,
                  vertical: isDesktop ? 40 : 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      _buildWelcomeSection(constraints, isTablet, isDesktop, theme),

                      SizedBox(height: isDesktop ? 50 : isTablet ? 40 : 30),

                      // Name Field
                      _buildNameField(isTablet, isDesktop, theme),

                      SizedBox(height: isTablet ? 25 : 20),

                      // Email Field
                      _buildEmailField(isTablet, isDesktop, theme),

                      SizedBox(height: isTablet ? 25 : 20),

                      // Mobile Number Field
                      _buildMobileField(isTablet, isDesktop, theme),

                      SizedBox(height: isTablet ? 25 : 20),

                      // Password Field
                      _buildPasswordField(isTablet, isDesktop, theme),

                      SizedBox(height: isTablet ? 25 : 20),

                      // Confirm Password Field
                      _buildConfirmPasswordField(isTablet, isDesktop, theme),

                      SizedBox(height: isTablet ? 40 : 30),

                      // Register Button
                      _buildRegisterButton(isTablet, isDesktop, theme),

                      SizedBox(height: isTablet ? 30 : 20),

                      // Login Redirect
                      _buildLoginRedirect(isTablet, isDesktop, theme),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BoxConstraints constraints, bool isTablet, bool isDesktop, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo/Icon
        if (!isDesktop)
          Container(
            margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
            child: Icon(
              Icons.person_add_alt_1_outlined,
              size: isTablet ? 48 : 40,
              color: colorScheme.primary,
            ),
          ),

        // Welcome Text
        Text(
          "Create Account",
          style: TextStyle(
            fontSize: isDesktop ? 40 :
            isTablet ? 32 :
            constraints.maxWidth * 0.08,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            height: 1.2,
          ),
        ),

        SizedBox(height: isDesktop ? 12 : isTablet ? 8 : 6),

        // Subtitle
        Text(
          "Join us and start chatting with friends",
          style: TextStyle(
            fontSize: isDesktop ? 18 :
            isTablet ? 16 :
            constraints.maxWidth * 0.04,
            color: colorScheme.onSurface.withOpacity(0.7),
            height: 1.4,
          ),
        ),

        // For desktop, add illustration/icon
        if (isDesktop)
          Container(
            margin: EdgeInsets.only(top: 40),
            height: 150,
            child: Center(
              child: Icon(
                Icons.person_add_alt_1_outlined,
                size: 100,
                color: colorScheme.primary.withOpacity(0.3),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNameField(bool isTablet, bool isDesktop, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Full Name",
          style: TextStyle(
            fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),

        SizedBox(height: isTablet ? 12 : 8),

        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            validator: (val) {
              if (val!.isEmpty) {
                return "Please enter your full name";
              }
              if (val.length < 2) {
                return "Name must be at least 2 characters";
              }
              return null;
            },
            controller: nameController,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: isDesktop ? 18 : isTablet ? 16 : 14,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : isTablet ? 20 : 16,
                vertical: isDesktop ? 20 : isTablet ? 18 : 16,
              ),
              hintText: "Enter your full name",
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: isDesktop ? 20 : isTablet ? 16 : 12,
                  right: isDesktop ? 16 : isTablet ? 12 : 8,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: colorScheme.primary,
                  size: isDesktop ? 24 : isTablet ? 22 : 20,
                ),
              ),
              errorStyle: TextStyle(
                fontSize: isTablet ? 13 : 12,
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(bool isTablet, bool isDesktop, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Email Address",
          style: TextStyle(
            fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),

        SizedBox(height: isTablet ? 12 : 8),

        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            validator: (val) {
              if (val!.isEmpty) {
                return "Please enter your email";
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                return "Please enter a valid email";
              }
              return null;
            },
            controller: emailController,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: isDesktop ? 18 : isTablet ? 16 : 14,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : isTablet ? 20 : 16,
                vertical: isDesktop ? 20 : isTablet ? 18 : 16,
              ),
              hintText: "you@example.com",
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: isDesktop ? 20 : isTablet ? 16 : 12,
                  right: isDesktop ? 16 : isTablet ? 12 : 8,
                ),
                child: Icon(
                  Icons.email_outlined,
                  color: colorScheme.primary,
                  size: isDesktop ? 24 : isTablet ? 22 : 20,
                ),
              ),
              errorStyle: TextStyle(
                fontSize: isTablet ? 13 : 12,
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileField(bool isTablet, bool isDesktop, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mobile Number",
          style: TextStyle(
            fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),

        SizedBox(height: isTablet ? 12 : 8),

        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter mobile number';

              // Remove any spaces or special characters
              String cleanNumber = value!.replaceAll(RegExp(r'[^0-9]'), '');

              if (cleanNumber.length != 10) {
                return 'Mobile number must be 10 digits';
              }

              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanNumber)) {
                return 'Please enter a valid Indian mobile number';
              }

              return null;
            },
            controller: mobileNoController,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: isDesktop ? 18 : isTablet ? 16 : 14,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : isTablet ? 20 : 16,
                vertical: isDesktop ? 20 : isTablet ? 18 : 16,
              ),
              hintText: "Enter your mobile number",
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: isDesktop ? 20 : isTablet ? 16 : 12,
                  right: isDesktop ? 16 : isTablet ? 12 : 8,
                ),
                child: Icon(
                  Icons.phone_outlined,
                  color: colorScheme.primary,
                  size: isDesktop ? 24 : isTablet ? 22 : 20,
                ),
              ),
              prefixText: "+91 ",
              prefixStyle: TextStyle(
                color: colorScheme.onSurface,
                fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
              ),
              counterText: "",
              errorStyle: TextStyle(
                fontSize: isTablet ? 13 : 12,
              ),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            maxLength: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(bool isTablet, bool isDesktop, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Password",
          style: TextStyle(
            fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),

        SizedBox(height: isTablet ? 12 : 8),

        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            validator: (val) {
              if (val!.isEmpty) {
                return "Please enter your password";
              }
              if (val.length < 6) {
                return "Password must be at least 6 characters";
              }
              return null;
            },
            controller: passController,
            obscureText: _obscureText,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: isDesktop ? 18 : isTablet ? 16 : 14,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : isTablet ? 20 : 16,
                vertical: isDesktop ? 20 : isTablet ? 18 : 16,
              ),
              hintText: "Create a password",
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: isDesktop ? 20 : isTablet ? 16 : 12,
                  right: isDesktop ? 16 : isTablet ? 12 : 8,
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: colorScheme.primary,
                  size: isDesktop ? 24 : isTablet ? 22 : 20,
                ),
              ),
              suffixIcon: Padding(
                padding: EdgeInsets.only(right: isDesktop ? 20 : isTablet ? 16 : 12),
                child: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    size: isDesktop ? 24 : isTablet ? 22 : 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
              errorStyle: TextStyle(
                fontSize: isTablet ? 13 : 12,
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField(bool isTablet, bool isDesktop, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Confirm Password",
          style: TextStyle(
            fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),

        SizedBox(height: isTablet ? 12 : 8),

        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            validator: (val) {
              if (val!.isEmpty) {
                return "Please confirm your password";
              }
              if (val != passController.text) {
                return "Passwords do not match";
              }
              return null;
            },
            controller: confirmPassController,
            obscureText: _obscureConfirmText,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: isDesktop ? 18 : isTablet ? 16 : 14,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : isTablet ? 20 : 16,
                vertical: isDesktop ? 20 : isTablet ? 18 : 16,
              ),
              hintText: "Confirm your password",
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: isDesktop ? 20 : isTablet ? 16 : 12,
                  right: isDesktop ? 16 : isTablet ? 12 : 8,
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: colorScheme.primary,
                  size: isDesktop ? 24 : isTablet ? 22 : 20,
                ),
              ),
              suffixIcon: Padding(
                padding: EdgeInsets.only(right: isDesktop ? 20 : isTablet ? 16 : 12),
                child: IconButton(
                  icon: Icon(
                    _obscureConfirmText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    size: isDesktop ? 24 : isTablet ? 22 : 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmText = !_obscureConfirmText;
                    });
                  },
                ),
              ),
              errorStyle: TextStyle(
                fontSize: isTablet ? 13 : 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(bool isTablet, bool isDesktop, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      height: isDesktop ? 64 : isTablet ? 56 : 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
          ),
          padding: EdgeInsets.symmetric(vertical: isDesktop ? 20 : 16),
        ),
        child: _isLoading
            ? SizedBox(
          height: isDesktop ? 28 : isTablet ? 24 : 20,
          width: isDesktop ? 28 : isTablet ? 24 : 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              colorScheme.onPrimary,
            ),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Create Account",
              style: TextStyle(
                fontSize: isDesktop ? 18 : isTablet ? 16 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: isDesktop ? 12 : isTablet ? 10 : 8),
            Icon(
              Icons.arrow_forward,
              size: isDesktop ? 22 : isTablet ? 20 : 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRedirect(bool isTablet, bool isDesktop, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          child: Text(
            "Sign In",
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _registerUser() async {
    if (_formKey.currentState!.validate()) {
      // Close keyboard
      FocusScope.of(context).unfocus();

      setState(() {
        _isLoading = true;
      });

      try {
        String cleanMobileNumber = mobileNoController.text
            .replaceAll(RegExp(r'[^0-9]'), '');

        String? fcmToken = await _getFCMToken();

        // Create user with email and password
        final user = await _authService.signUpWithEmail(
          emailController.text.trim(),
          passController.text.trim(),
          nameController.text.trim(),
        );

        if (user != null) {
          final userModel = UserModel(
            uid: user.uid,
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            mobileNo: cleanMobileNumber,
            avatarUrl: "no",
            isOnline: true,
            createdAt: DateTime.now(),
            lastSeen: DateTime.now(),
            bio: "Hey There! I am using this amazing chat app",
            status: "Available",
            fcmToken: fcmToken,
          );

          await _databaseService.saveUser(userModel);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Account created successfully!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.1,
                left: 20,
                right: 20,
              ),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.1,
              left: 20,
              right: 20,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passController.dispose();
    mobileNoController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }
}