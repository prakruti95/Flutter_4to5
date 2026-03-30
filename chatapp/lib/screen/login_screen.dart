import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../shared_pref/sharedpref.dart';
import 'forgot_pass_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'verifyemail_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;

  // Theme colors based on system
  Color get _primaryColor => Theme.of(context).colorScheme.primary;
  Color get _surfaceColor => Theme.of(context).colorScheme.surface;
  Color get _onSurfaceColor => Theme.of(context).colorScheme.onSurface;
  Color get _surfaceVariantColor => Theme.of(context).colorScheme.surfaceVariant;
  Color get _onSurfaceVariantColor => Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
  Color get _outlineColor => Theme.of(context).colorScheme.outline;
  Color get _primaryContainerColor => Theme.of(context).colorScheme.primaryContainer;
  Color get _onPrimaryContainerColor => Theme.of(context).colorScheme.onPrimaryContainer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
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
                      _buildWelcomeSection(constraints, isTablet, isDesktop),

                      SizedBox(height: isDesktop ? 60 : isTablet ? 50 : 40),

                      // Email Field
                      _buildEmailField(isTablet, isDesktop),

                      SizedBox(height: isTablet ? 30 : 20),

                      // Password Field
                      _buildPasswordField(isTablet, isDesktop),

                      SizedBox(height: isTablet ? 40 : 30),

                      // Login Button
                      _buildLoginButton(isTablet, isDesktop),

                      SizedBox(height: isTablet ? 30 : 20),

                      // Additional Options
                      _buildAdditionalOptions(isTablet, isDesktop, theme),

                      if (isDesktop) SizedBox(height: 40),
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

  Widget _buildWelcomeSection(BoxConstraints constraints, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo/Icon
        if (!isDesktop)
          Container(
            margin: EdgeInsets.only(bottom: isTablet ? 24 : 16),
            child: Icon(
              Icons.chat_bubble_outline,
              size: isTablet ? 48 : 40,
              color: _primaryColor,
            ),
          ),

        // Welcome Text
        Text(
          "Welcome Back!",
          style: TextStyle(
            fontSize: isDesktop ? 40 :
            isTablet ? 32 :
            constraints.maxWidth * 0.08,
            fontWeight: FontWeight.bold,
            color: _onSurfaceColor,
            height: 1.2,
          ),
        ),

        SizedBox(height: isDesktop ? 12 : isTablet ? 8 : 6),

        // Subtitle
        Text(
          "Sign in to continue your conversation",
          style: TextStyle(
            fontSize: isDesktop ? 18 :
            isTablet ? 16 :
            constraints.maxWidth * 0.04,
            color: _onSurfaceVariantColor,
            height: 1.4,
          ),
        ),

        // For desktop, add illustration/icon
        if (isDesktop)
          Container(
            margin: EdgeInsets.only(top: 40),
            height: 200,
            child: Center(
              child: Icon(
                Icons.chat_bubble_outline,
                size: 120,
                color: _primaryColor.withOpacity(0.3),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmailField(bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Email Address",
          style: TextStyle(
            fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
            fontWeight: FontWeight.w500,
            color: _onSurfaceColor,
          ),
        ),

        SizedBox(height: isTablet ? 12 : 8),

        Container(
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            border: Border.all(color: _outlineColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
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
              color: _onSurfaceColor,
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
                color: _onSurfaceVariantColor,
                fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: isDesktop ? 20 : isTablet ? 16 : 12,
                  right: isDesktop ? 16 : isTablet ? 12 : 8,
                ),
                child: Icon(
                  Icons.email_outlined,
                  color: _primaryColor,
                  size: isDesktop ? 24 : isTablet ? 22 : 20,
                ),
              ),
              errorStyle: TextStyle(
                fontSize: isTablet ? 13 : 12,
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Password",
              style: TextStyle(
                fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                fontWeight: FontWeight.w500,
                color: _onSurfaceColor,
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => VerifyEmailScreen(),));
              },
              child: Text(
                "Forgot Password?",
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: isTablet ? 12 : 8),

        Container(
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            border: Border.all(color: _outlineColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
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
              color: _onSurfaceColor,
              fontSize: isDesktop ? 18 : isTablet ? 16 : 14,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : isTablet ? 20 : 16,
                vertical: isDesktop ? 20 : isTablet ? 18 : 16,
              ),
              hintText: "Enter your password",
              hintStyle: TextStyle(
                color: _onSurfaceVariantColor,
                fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: isDesktop ? 20 : isTablet ? 16 : 12,
                  right: isDesktop ? 16 : isTablet ? 12 : 8,
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: _primaryColor,
                  size: isDesktop ? 24 : isTablet ? 22 : 20,
                ),
              ),
              suffixIcon: Padding(
                padding: EdgeInsets.only(right: isDesktop ? 20 : isTablet ? 16 : 12),
                child: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _onSurfaceVariantColor,
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
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isTablet, bool isDesktop) {
    return SizedBox(
      width: double.infinity,
      height: isDesktop ? 64 : isTablet ? 56 : 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _loginUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
          ),
          padding: EdgeInsets.symmetric(vertical: isDesktop ? 20 : 16),
          shadowColor: _primaryColor.withOpacity(0.3),
        ),
        child: _isLoading
            ? SizedBox(
          height: isDesktop ? 28 : isTablet ? 24 : 20,
          width: isDesktop ? 28 : isTablet ? 24 : 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Sign In",
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

  Widget _buildAdditionalOptions(bool isTablet, bool isDesktop, ThemeData theme) {
    return Column(
      children: [
        // Divider with "or" text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: _outlineColor.withOpacity(0.3),
                thickness: 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : isTablet ? 16 : 12),
              child: Text(
                "or",
                style: TextStyle(
                  color: _onSurfaceVariantColor,
                  fontSize: isDesktop ? 15 : isTablet ? 14 : 13,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: _outlineColor.withOpacity(0.3),
                thickness: 1,
              ),
            ),
          ],
        ),

        SizedBox(height: isDesktop ? 30 : isTablet ? 24 : 20),

        // Sign up prompt
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: TextStyle(
                color: _onSurfaceVariantColor,
                fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
              child: Text(
                "Create Account",
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        // Social login options for larger screens
        if (isTablet || isDesktop) ...[
          SizedBox(height: isDesktop ? 40 : 30),

          Text(
            "Sign in with",
            style: TextStyle(
              color: _onSurfaceVariantColor,
              fontSize: isDesktop ? 16 : 15,
            ),
          ),

          SizedBox(height: isDesktop ? 20 : 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                icon: Icons.g_mobiledata,
                label: "Google",
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(width: isDesktop ? 20 : 16),
              _buildSocialButton(
                icon: Icons.facebook,
                label: "Facebook",
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return OutlinedButton(
      onPressed: () {
        // Add social login functionality
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: _onSurfaceColor,
        side: BorderSide(color: _outlineColor.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : isTablet ? 20 : 16,
          vertical: isDesktop ? 16 : isTablet ? 14 : 12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isDesktop ? 24 : isTablet ? 22 : 20,
          ),
          SizedBox(width: isDesktop ? 12 : isTablet ? 10 : 8),
          Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 15 : isTablet ? 14 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _loginUser() async {
    if (_formKey.currentState!.validate()) {
      // Close keyboard
      FocusScope.of(context).unfocus();

      setState(() {
        _isLoading = true;
      });

      try {
        final user = await _authService.signInWithEmail(
          emailController.text.trim(),
          passController.text.trim(),
        );

        if (user != null) {
          // ✅ IMPORTANT: Save login state to SharedPreferences
          final sharedPref = await SharedPrefService.getInstance();
          await sharedPref.setUserLoggedIn(true);
          await sharedPref.saveUserData(
            userId: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? user.email!.split('@')[0],
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Login successful!"),
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

          // Navigate to home screen
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: Duration(milliseconds: 300),
            ),
          );
        } else {
          _showErrorSnackBar('Login failed! Please check your credentials.');
        }
      } catch (e) {
        print('Login error: $e');
        _showErrorSnackBar('Login failed: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }
}