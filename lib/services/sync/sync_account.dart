import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The signed-in sync account, independent of the auth backend.
class SyncUser {
  const SyncUser({required this.uid, this.email, this.displayName});
  final String uid;
  final String? email;
  final String? displayName;
}

enum SyncAuthError {
  cancelled,
  invalidCredentials,
  invalidEmail,
  emailInUse,
  weakPassword,
  tooManyRequests,
  network,
  unknown,
}

/// A sign-in or sign-up failure the screen can explain.
class SyncAuthException implements Exception {
  const SyncAuthException(this.error, [this.code]);
  final SyncAuthError error;

  /// Backend error code, kept for logs.
  final String? code;

  @override
  String toString() => 'SyncAuthException(${error.name}, $code)';
}

/// Who owns the sync data: a Google or email/password account.
abstract class SyncAccount {
  /// False when this build has no backend configuration.
  bool get available;
  SyncUser? get currentUser;
  Stream<SyncUser?> get changes;
  Future<void> signInWithGoogle();
  Future<void> signInWithEmail(String email, String password);
  Future<void> createAccount(String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

/// Used when Firebase is not configured, e.g. a build without
/// `google-services.json`.
class UnavailableSyncAccount implements SyncAccount {
  const UnavailableSyncAccount();

  @override
  bool get available => false;
  @override
  SyncUser? get currentUser => null;
  @override
  Stream<SyncUser?> get changes => const Stream.empty();
  @override
  Future<void> signInWithGoogle() => _unavailable();
  @override
  Future<void> signInWithEmail(String email, String password) => _unavailable();
  @override
  Future<void> createAccount(String email, String password) => _unavailable();
  @override
  Future<void> sendPasswordReset(String email) => _unavailable();
  @override
  Future<void> signOut() async {}

  static Future<void> _unavailable() =>
      Future.error(const SyncAuthException(SyncAuthError.unknown));
}

class FirebaseSyncAccount implements SyncAccount {
  FirebaseSyncAccount({FirebaseAuth? auth, GoogleSignIn? google})
      : _auth = auth ?? FirebaseAuth.instance,
        _google = google ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  @override
  bool get available => true;

  @override
  SyncUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Stream<SyncUser?> get changes => _auth.authStateChanges().map(_toUser);

  @override
  Future<void> signInWithGoogle() => _guard(() async {
        final account = await _google.signIn();
        if (account == null) {
          throw const SyncAuthException(SyncAuthError.cancelled);
        }
        final tokens = await account.authentication;
        await _auth.signInWithCredential(GoogleAuthProvider.credential(
          idToken: tokens.idToken,
          accessToken: tokens.accessToken,
        ));
      });

  @override
  Future<void> signInWithEmail(String email, String password) =>
      _guard(() => _auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          ));

  @override
  Future<void> createAccount(String email, String password) =>
      _guard(() => _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          ));

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() async {
    // Also forget the Google choice so another account can be picked.
    await _google.signOut().catchError((_) => null);
    await _auth.signOut();
  }

  static SyncUser? _toUser(User? user) => user == null
      ? null
      : SyncUser(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
        );

  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw SyncAuthException(_errorFor(error.code), error.code);
    } on PlatformException catch (error) {
      // Google Sign-In reports its failures as platform errors.
      throw SyncAuthException(
        switch (error.code) {
          'sign_in_canceled' => SyncAuthError.cancelled,
          'network_error' => SyncAuthError.network,
          _ => SyncAuthError.unknown,
        },
        '${error.code}: ${error.message}',
      );
    }
  }

  static SyncAuthError _errorFor(String code) => switch (code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'user-disabled' =>
          SyncAuthError.invalidCredentials,
        'invalid-email' => SyncAuthError.invalidEmail,
        'email-already-in-use' ||
        'account-exists-with-different-credential' =>
          SyncAuthError.emailInUse,
        'weak-password' => SyncAuthError.weakPassword,
        'too-many-requests' => SyncAuthError.tooManyRequests,
        'network-request-failed' => SyncAuthError.network,
        _ => SyncAuthError.unknown,
      };
}
