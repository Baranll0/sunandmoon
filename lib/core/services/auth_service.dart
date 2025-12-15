import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../domain/user_model.dart';
import 'firebase_service.dart';

/// Authentication service for Google Sign-In
class AuthService {
  FirebaseAuth? get _auth {
    try {
      if (kIsWeb && !FirebaseService.isInitialized) return null;
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('[AUTH] FirebaseAuth not available: $e');
      return null;
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Get current user
  User? get currentUser {
    final auth = _auth;
    if (auth == null) return null;
    return auth.currentUser;
  }

  /// Get current user ID
  String? get currentUserId => currentUser?.uid;

  /// Auth state changes stream
  Stream<User?> get authStateChanges {
    final auth = _auth;
    if (auth == null) {
      return Stream.value(null);
    }
    return auth.authStateChanges();
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase Auth not available (web without config)');
    }

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        throw Exception('Sign-in canceled by user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await auth.signInWithCredential(credential);

      debugPrint('Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final auth = _auth;
      final futures = <Future>[_googleSignIn.signOut()];
      if (auth != null) {
        futures.add(auth.signOut());
      }
      await Future.wait(futures);
      debugPrint('Sign out successful');
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Get user model from Firebase User
  UserModel? getUserModel() {
    final user = currentUser;
    if (user == null) return null;

    return UserModel(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoURL: user.photoURL,
      createdAt: user.metadata.creationTime,
      lastSeenAt: user.metadata.lastSignInTime,
    );
  }

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;
}

