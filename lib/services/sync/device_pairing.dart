import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum PairingError { notGoogleAccount, invalidCode, expired, failed }

class PairingException implements Exception {
  const PairingException(this.error);
  final PairingError error;

  @override
  String toString() => 'PairingException(${error.name})';
}

/// Signs a computer in with the Google account of a phone, through a short-lived
/// Firestore document. The computer shows a QR code holding a random 128-bit
/// id; the signed-in phone scans it and drops a Google ID token (valid about an
/// hour) in `pairings/{id}`; the computer reads it, signs in and deletes it.
class DevicePairing {
  DevicePairing({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    GoogleSignIn? google,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _google = google;

  static const uriPrefix = 'musicstream://pair/';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  GoogleSignIn? _google;

  DocumentReference<Map<String, dynamic>> _document(String id) =>
      _firestore.collection('pairings').doc(id);

  /// A fresh unguessable session id: 16 random bytes, hex encoded.
  static String newSessionId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static String uriFor(String id) => '$uriPrefix$id';

  /// The session id inside a scanned QR payload, or null if it is not ours.
  static String? idFromUri(String? value) {
    if (value == null || !value.startsWith(uriPrefix)) return null;
    final id = value.substring(uriPrefix.length);
    return RegExp(r'^[0-9a-f]{32}$').hasMatch(id) ? id : null;
  }

  /// Computer side: waits for a phone to approve session [id], then signs in.
  Future<void> waitForApproval(
    String id, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final document = _document(id);
    try {
      final snapshot = await document
          .snapshots()
          .firstWhere((snapshot) => snapshot.exists)
          .timeout(timeout);
      final token = snapshot.data()?['idToken'];
      if (token is! String) throw const PairingException(PairingError.failed);
      await _auth.signInWithCredential(GoogleAuthProvider.credential(
        idToken: token,
      ));
    } on TimeoutException {
      throw const PairingException(PairingError.expired);
    } on FirebaseException {
      throw const PairingException(PairingError.failed);
    } finally {
      await cancel(id);
    }
  }

  /// Removes session [id]; safe to call when nothing was written.
  Future<void> cancel(String id) async {
    try {
      await _document(id).delete();
    } catch (_) {
      // Best effort: the token expires on its own.
    }
  }

  /// Phone side: whether the signed-in account can sign a computer in.
  bool get canApprove =>
      _auth.currentUser?.providerData
          .any((info) => info.providerId == 'google.com') ??
      false;

  /// Phone side: hands this phone's Google sign-in to the computer showing [id].
  Future<void> approve(String id) async {
    if (!canApprove) {
      throw const PairingException(PairingError.notGoogleAccount);
    }
    try {
      final google = _google ??= GoogleSignIn(scopes: const ['email']);
      final account = await google.signInSilently() ?? await google.signIn();
      final token = (await account?.authentication)?.idToken;
      if (token == null) throw const PairingException(PairingError.failed);
      await _document(id).set({
        'idToken': token,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      });
    } on FirebaseException {
      throw const PairingException(PairingError.failed);
    }
  }
}
