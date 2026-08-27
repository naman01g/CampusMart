import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusmart_mobile/shared/models/models.dart';
import 'package:campusmart_mobile/core/config/app_config.dart';
import 'package:campusmart_mobile/core/firebase/fcm_service.dart';

final authProvider = Provider<AuthService>((ref) => AuthService());
final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authProvider).authStateChanges;
});

/// The authenticated user has NO `users/{uid}` document (e.g. registration
/// created the Auth account but the profile write failed). Distinct from
/// being logged out so the UI can offer explicit recovery.
class UserProfileMissingException implements Exception {
  final String message;
  UserProfileMissingException([
    this.message = 'Your account profile is missing on the server.',
  ]);
  @override
  String toString() => message;
}

/// Firebase Auth worked but Firestore could not be reached within the time
/// limit. Retryable - the session is NOT established until the profile loads.
class AuthProfileUnavailableException implements Exception {
  final String message;
  AuthProfileUnavailableException([
    this.message =
        'Could not reach CampusMart servers. Check your connection and try again.',
  ]);
  @override
  String toString() => message;
}

class AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;

      // Best-effort freshness refresh of emailVerified. A failure here must
      // not block sign-in: the router gates verification directly off
      // FirebaseAuth's own claim, which stays available.
      try {
        await fbUser.reload().timeout(const Duration(seconds: 10));
      } on TimeoutException {
        // Keep the last-known claim.
      } catch (_) {
        // Same - never let a refresh error poison the auth stream.
      }

      final freshUser = _auth.currentUser ?? fbUser;

      // The profile document is REQUIRED to treat the session as valid.
      // Bounded wait so an unreachable Firestore surfaces a retryable error
      // instead of leaving the app in limbo.
      try {
        final doc = await _firestore
            .collection('users')
            .doc(freshUser.uid)
            .get()
            .timeout(const Duration(seconds: 15));

        if (!doc.exists) {
          throw UserProfileMissingException();
        }
        final userModel = UserModel.fromFirestore(doc);
        // Firebase Auth is the authoritative source for email verification.
        // Reflect it in the session model without writing to Firestore.

        // Persist the FCM token against this authenticated user. Called on
        // every session establishment (login + cold start with a saved
        // session) so the token is always associated with the right UID even
        // if it was obtained before the user signed in.
        final fcmService = FcmService();
        unawaited(fcmService.storeTokenForCurrentUser());

        return userModel.copyWith(isVerified: freshUser.emailVerified);
      } on UserProfileMissingException {
        rethrow;
      } on TimeoutException {
        throw AuthProfileUnavailableException();
      } on FirebaseException {
        throw AuthProfileUnavailableException();
      }
    });
  }

  fb_auth.User? get currentUser => _auth.currentUser;

  static bool isValidAKGECEmail(String email) {
    return email.toLowerCase().endsWith('@${AppConfig.collegeEmailDomain}');
  }

  Future<void> signInWithEmail(String email, String password) async {
    if (!AuthService.isValidAKGECEmail(email)) {
      throw AuthException('Use your AKGEC student email to continue.');
    }
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    if (!AuthService.isValidAKGECEmail(email)) {
      throw AuthException('Use your AKGEC student email to continue.');
    }
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _auth.currentUser?.updateDisplayName(name);

    // Send email verification
    await _auth.currentUser?.sendEmailVerification();

    final userModel = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      collegeId: AppConfig.collegeId,
      course: '',
      branch: '',
      year: 1,
      isVerified: false, // Initially false until email verified
      role: UserRole.student,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(userModel.toMap());
  }

  Future<void> signOut() async {
    // Clear FCM tokens before signing out
    try {
      final fcmService = FcmService();
      await fcmService.clearAllTokens();
    } catch (_) {
      // Non-blocking
    }
    await _auth.signOut();
  }

  /// Explicit recovery for a user whose Auth account exists but whose
  /// `users/{uid}` profile document is missing (e.g. the write failed during
  /// a network drop at registration).
  ///
  /// Rebuilds the profile ONLY from verified Firebase Auth claims. Firestore
  /// rules still enforce every constraint server-side (AKGEC email, college
  /// id, student role, isVerified:false) - nothing is bypassed.
  Future<void> restoreMissingProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('Not authenticated');

    final email = user.email ?? '';
    if (!AuthService.isValidAKGECEmail(email)) {
      throw AuthException('Use your AKGEC student email to continue.');
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 15));
      if (doc.exists) return; // already restored (or raced) - nothing to do
    } on TimeoutException {
      throw AuthProfileUnavailableException();
    } on FirebaseException {
      throw AuthProfileUnavailableException();
    }

    final model = UserModel(
      uid: user.uid,
      name: user.displayName ?? '',
      email: email,
      collegeId: AppConfig.collegeId,
      course: '',
      branch: '',
      year: 1,
      // Rules require new profiles to start unverified; real verification
      // status keeps coming from the Firebase Auth claim, never from here.
      isVerified: false,
      role: UserRole.student,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(model.toMap())
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw AuthProfileUnavailableException();
    } on FirebaseException catch (e) {
      throw AuthProfileUnavailableException(
        'Could not restore your profile (${e.code}). Please try again.',
      );
    }
  }

  Future<void> resetPassword(String email) async {
    if (!AuthService.isValidAKGECEmail(email)) {
      throw AuthException('Use your AKGEC student email to continue.');
    }
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    await user.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return user.emailVerified;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    // Prevent modification of protected fields
    final protectedFields = {'uid', 'isVerified', 'role', 'collegeId', 'email'};
    final filteredData = Map<String, dynamic>.from(data);
    for (final field in protectedFields) {
      filteredData.remove(field);
    }

    await _firestore.collection('users').doc(uid).update({
      ...filteredData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
