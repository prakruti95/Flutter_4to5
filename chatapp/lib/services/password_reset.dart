import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PasswordResetService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> updateUserPassword(String email, String newPassword) async {
    try {
      final usersRef = _database.child('users');
      final snapshot = await usersRef.orderByChild('email').equalTo(email).once();

      if (snapshot.snapshot.value == null) {
        throw Exception('User not found with email: $email');
      }

      // Get the user data
      final Map<dynamic, dynamic> users = snapshot.snapshot.value as Map<dynamic, dynamic>;

      // Find the user key
      String? userKey;
      for (var key in users.keys) {
        if (users[key]['email'] == email) {
          userKey = key.toString();
          break;
        }
      }

      if (userKey == null) {
        throw Exception('User key not found');
      }

      // Update password in Realtime Database
      await usersRef.child(userKey).update({
        'password': newPassword, // Note: Hash this in production
        'lastPasswordUpdate': DateTime.now().toIso8601String(),
      });

      print('✅ Password updated for $email in Realtime Database');
    } catch (e) {
      print('❌ Error updating password: $e');
      rethrow;
    }
  }

  // ✅ Method: Check if user exists in Realtime Database
  Future<bool> checkUserExists(String email) async {
    try {
      final usersRef = _database.child('users');
      final snapshot = await usersRef.orderByChild('email').equalTo(email).once();

      return snapshot.snapshot.value != null;
    } catch (e) {
      print('❌ Error checking user: $e');
      rethrow;
    }
  }

  // ✅ Method: Store password reset request
  Future<void> requestPasswordReset(String email, String newPassword) async {
    try {
      final resetRef = _database.child('passwordResetRequests').push();

      await resetRef.set({
        'email': email,
        'newPassword': newPassword, // Hash in production
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      print('✅ Password reset request stored for $email');
    } catch (e) {
      print('❌ Error storing reset request: $e');
      rethrow;
    }
  }

  // ✅ Method: Get user data by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final usersRef = _database.child('users');
      final snapshot = await usersRef.orderByChild('email').equalTo(email).once();

      if (snapshot.snapshot.value == null) {
        return null;
      }

      final Map<dynamic, dynamic> users = snapshot.snapshot.value as Map<dynamic, dynamic>;

      for (var userData in users.values) {
        if (userData['email'] == email) {
          return Map<String, dynamic>.from(userData as Map);
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting user: $e');
      rethrow;
    }
  }
}