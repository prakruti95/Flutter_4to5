import 'package:firebase_auth/firebase_auth.dart';
import '../shared_pref/sharedpref.dart';
import 'database_service.dart'; // Add this import

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DataBaseService _db = DataBaseService(); // Add this

  User? get currentUser => _auth.currentUser;

  // ✅ Sign Up with SharedPreferences
  Future<User?> signUpWithEmail(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Update display name
        await result.user!.updateDisplayName(name);

        // Save user data to SharedPreferences
        final sharedPref = await SharedPrefService.getInstance();
        await sharedPref.saveUserData(
          userId: result.user!.uid,
          email: email,
          name: name,
        );
        await sharedPref.setUserLoggedIn(true);

        // ✅ IMPORTANT: Set user online in Firebase
        await _db.updateUserStatus(true);
      }

      return result.user;
    } catch (e) {
      print("Sign up error: $e");
      return null;
    }
  }

  // ✅ Sign In with SharedPreferences
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Save user data to SharedPreferences
        final sharedPref = await SharedPrefService.getInstance();
        await sharedPref.saveUserData(
          userId: result.user!.uid,
          email: email,
          name: result.user!.displayName ?? email.split('@')[0],
        );
        await sharedPref.setUserLoggedIn(true);

        // ✅ IMPORTANT: Set user online in Firebase
        await _db.updateUserStatus(true);
      }

      return result.user;
    } catch (e) {
      print("Sign in error: $e");
      return null;
    }
  }

  // ✅ Comprehensive Logout
  Future<void> signOut() async {
    try {
      // First set user offline
      await _db.updateUserStatus(false);

      // Clear SharedPreferences
      final sharedPref = await SharedPrefService.getInstance();
      await sharedPref.clearAllData();

      // Then Firebase logout
      await _auth.signOut();
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
  }

  // ✅ Check if user is logged in (from SharedPreferences)
  Future<bool> isUserLoggedIn() async {
    try {
      final sharedPref = await SharedPrefService.getInstance();
      return await sharedPref.isUserLoggedIn();
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // ✅ Get user ID from SharedPreferences
  Future<String?> getUserId() async {
    try {
      final sharedPref = await SharedPrefService.getInstance();
      return await sharedPref.getUserId();
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // ✅ Alternative methods (for compatibility)
  Future<User?> loginWithEmailPassword(String email, String password) async {
    return await signInWithEmail(email, password);
  }

  Future<User?> registerWithEmailPassword(String email, String password, String name) async {
    return await signUpWithEmail(email, password, name);
  }

  Future<void> logout() async {
    await signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
}