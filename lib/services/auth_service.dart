import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:spendee/services/app_pref.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  // Sign up user
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String username,
    required String phone,
  }) async {
    try {
      // Create user
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      debugPrint("User created: ${userCredential.user!.uid}");

      // Save user info to Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "uid": userCredential.user!.uid,
        "email": email,
        "username": username,
        "phone": phone,
        "createdAt": Timestamp.now(),
      });

      // Save email to local preferences
      await AppPref().setEmail(email);

      // Sign out immediately so user is not auto-logged in
      await _auth.signOut();

      return userCredential;
    } on FirebaseAuthException catch (_) {
      rethrow;
    } catch (e) {
      if (e.toString().contains('network error') ||
          e.toString().contains('unreachable host')) {
        throw Exception('Network error. Please check your connection.');
      }
      throw Exception(e.toString());
    } finally {
      debugPrint("Finished sign up process");
    }
  }

  // Sign in user with email & passwPord
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("User signed in: ${userCredential.user!.uid}");

      // Save email to local preferences
      await AppPref().setEmail(email);

      return userCredential;
    } on FirebaseAuthException catch (_) {
      rethrow;
    } catch (e) {
      if (e.toString().contains('network error') ||
          e.toString().contains('unreachable host')) {
        throw Exception('Network error. Please check your connection.');
      }
      throw Exception(e.toString());
    }
  }

  /// Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Optional: Save new Google user info to Firestore
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        try {
          await _firestore
              .collection("users")
              .doc(userCredential.user!.uid)
              .set({
                "uid": userCredential.user!.uid,
                "email": userCredential.user!.email,
                "username": userCredential.user!.displayName ?? "",
                "phone": userCredential.user!.phoneNumber ?? "",
                "createdAt": Timestamp.now(),
              });
        } catch (e) {
          debugPrint("Error saving user to Firestore: $e");
        }
      }

      // Save email to local preferences
      if (userCredential.user?.email != null) {
        await AppPref().setEmail(userCredential.user!.email!);
      }

      return userCredential;
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google
      await _googleSignIn.signOut();

      // Clear local preferences
      await AppPref().clear();

      debugPrint("User signed out from Firebase and Google");
    } catch (e) {
      debugPrint("Error signing out: $e");
      rethrow;
    }
  }

  Future<void> saveMonthlyBudget(String userId, int budget) async {
    final currentMonthYear = DateFormat('MMMM yyyy').format(DateTime.now());

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('monthly_budgets')
        .doc(currentMonthYear);

    await docRef.set({
      'budget': budget,
      'monthYear': currentMonthYear,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'lastBudgetMonth': currentMonthYear,
      'lastBudgetAmount': budget,
    });
  }

  Future<void> saveExpense({
    required String userId,
    required int amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .add({
            'amount': amount,
            'category': category,
            'date': Timestamp.fromDate(date),
            'note': note,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Error saving expense: $e");
      rethrow;
    }
  }

  Future<void> updateExpense({
    required String userId,
    required String expenseId,
    required int amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .doc(expenseId)
          .update({
            'amount': amount,
            'category': category,
            'date': Timestamp.fromDate(date),
            'note': note,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Error updating expense: $e");
      rethrow;
    }
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .doc(expenseId)
          .delete();
    } catch (e) {
      debugPrint("Error deleting expense: $e");
      rethrow;
    }
  }

  Future<void> changePassword({required String newPassword}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("No user found");
      if (user.email == null) throw Exception("User email not found");

      // Update password
      await user.updatePassword(newPassword);

      debugPrint("Password updated successfully");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw Exception('No internet connection. Please check your settings.');
      }
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'For security, please log out and log back in to change your password.',
        );
      }
      throw Exception(e.message);
    } catch (e) {
      debugPrint("Error updating password: $e");
      rethrow;
    }
  }

  /// Premium Subscription Logic
  Future<bool> isUserPremium() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final data = doc.data();
      bool isPremium = data?['isPremium'] ?? false;

      // If premium, double check expiry
      if (isPremium) {
        final expiry = data?['premiumExpiry'] as Timestamp?;
        if (expiry != null && DateTime.now().isAfter(expiry.toDate())) {
          // Premium expired, update Firestore
          await _firestore.collection('users').doc(user.uid).update({
            'isPremium': false,
          });
          return false;
        }
      }

      return isPremium;
    } catch (e) {
      debugPrint("Error checking premium status: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPremiumDetails() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data();
      return {
        'isPremium': data?['isPremium'] ?? false,
        'plan': data?['plan'] ?? '',
        'premiumExpiry': data?['premiumExpiry'],
      };
    } catch (e) {
      debugPrint("Error fetching premium details: $e");
      return null;
    }
  }

  Future<void> updatePremiumStatus({
    required bool isPremium,
    required String plan,
    required int durationDays,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isPremium': isPremium,
        'plan': plan,
        'premiumExpiry': Timestamp.fromDate(
          DateTime.now().add(Duration(days: durationDays)),
        ),
      });
    } catch (e) {
      debugPrint("Error updating premium status: $e");
      rethrow;
    }
  }

  Future<void> checkPremiumExpiry() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return;

      final expiry = doc.data()?['premiumExpiry'] as Timestamp?;
      if (expiry != null && DateTime.now().isAfter(expiry.toDate())) {
        await _firestore.collection('users').doc(user.uid).update({
          'isPremium': false,
        });
      }
    } catch (e) {
      debugPrint("Error checking premium expiry: $e");
    }
  }
}
