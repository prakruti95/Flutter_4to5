import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'Provider/themeprovider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'shared_pref/sharedpref.dart';
import 'screen/login_screen.dart';
import 'screen/home_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize SharedPreferences
  await SharedPrefService.init();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late Future<bool> _checkLoginStatus;
  final DataBaseService _db = DataBaseService();
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check login status
    _checkLoginStatus = _checkUserLoginStatus();
  }

  Future<bool> _checkUserLoginStatus() async {
    try {
      final sharedPref = await SharedPrefService.getInstance();
      bool isLoggedIn = await sharedPref.isUserLoggedIn();
      print('Login status: $isLoggedIn');

      // If user is logged in, set online status
      if (isLoggedIn) {
        await _db.updateUserStatus(true);
      }

      return isLoggedIn;
    } catch (e) {
      print('Error checking login: $e');
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final sharedPref = SharedPrefService.getInstance();

    // When app is resumed, set user online
    if (state == AppLifecycleState.resumed) {
      sharedPref.then((pref) async {
        bool isLoggedIn = await pref.isUserLoggedIn();
        if (isLoggedIn) {
          await _db.updateUserStatus(true);
        }
      });
    }
    // When app is paused/inactive/detached, set user offline
    else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      sharedPref.then((pref) async {
        bool isLoggedIn = await pref.isUserLoggedIn();
        if (isLoggedIn) {
          await _db.updateUserStatus(false);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginStatus,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading screen while checking login status
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4299E1),
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          // If error, show login screen
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: LoginScreen(),
          );
        } else {
          // Decide which screen to show
          bool isLoggedIn = snapshot.data ?? false;
          print('Navigating to: ${isLoggedIn ? 'Home' : 'Login'}');

          // Wrap with ChangeNotifierProvider for Theme
          return ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                // Load saved theme preference if user is logged in
                if (isLoggedIn) {
                  _loadThemePreference(context);
                }

                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Chat App',
                  theme: _buildLightTheme(),
                  darkTheme: _buildDarkTheme(),
                  themeMode: themeProvider.themeMode,
                  home: isLoggedIn ? HomeScreen() : LoginScreen(),
                );
              },
            ),
          );
        }
      },
    );
  }

  // Light theme configuration
  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: Color(0xFF4299E1),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2D3748)),
        titleTextStyle: TextStyle(
          color: Color(0xFF2D3748),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF4299E1),
        unselectedItemColor: Color(0xFF718096),
      ),
      cardColor: Colors.white,
      dialogBackgroundColor: Colors.white,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF2D3748)),
        bodyMedium: TextStyle(color: Color(0xFF718096)),
        titleLarge: TextStyle(color: Color(0xFF2D3748)),
      ),
      iconTheme: IconThemeData(color: Color(0xFF2D3748)),
      dividerColor: Color(0xFFE2E8F0),
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: Color(0xFF4299E1),
        secondary: Color(0xFF48BB78),
        background: Colors.white,
        surface: Colors.white,
      ),
    );
  }

  // Dark theme configuration
  ThemeData _buildDarkTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: Color(0xFF4299E1),
      scaffoldBackgroundColor: Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: Color(0xFF4299E1),
        unselectedItemColor: Colors.grey.shade400,
      ),
      cardColor: Color(0xFF1E1E1E),
      dialogBackgroundColor: Color(0xFF1E1E1E),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.grey.shade400),
        titleLarge: TextStyle(color: Colors.white),
      ),
      iconTheme: IconThemeData(color: Colors.white),
      dividerColor: Color(0xFF333333),
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF4299E1),
        secondary: Color(0xFF48BB78),
        background: Color(0xFF121212),
        surface: Color(0xFF1E1E1E),
      ),
    );
  }

  // Load theme preference from Firebase
  Future<void> _loadThemePreference(BuildContext context) async {
    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final authService = AuthService();
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        // Check if theme preference is already loaded
        if (themeProvider.themePreference == "System Default") {
          // Get theme preference from Firebase
          final db = DataBaseService();
          final themePref = await db.getUserThemePreference(currentUser.uid);

          if (themePref != null) {
            themeProvider.setTheme(themePref);
            print('Loaded theme preference: $themePref');
          }
        }
      }
    } catch (e) {
      print('Error loading theme preference: $e');
    }
  }
}