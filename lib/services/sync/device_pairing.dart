import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'sync_crypto.dart';

enum PairingError { notGoogleAccount, invalidCode, expired, failed }

class PairingRequest {
  const PairingRequest(this.id, this.secret);
  final String id;
  final String secret;
}

class PairingException implements Exception {
  const PairingException(this.error);
  final PairingError error;

  @override
  String toString() => 'PairingException(${error.name})';
}

/// Signs a computer in with the Google account of a phone, through a short-lived
/// Firestore document. The computer shows a QR code holding a random 128-bit
/// id plus an AES key; the signed-in phone scans it and drops a short-lived
/// Google ID token and optionally an encrypted sync key in `pairings/{id}`.
/// The computer reads it, signs in, unwraps the key locally and deletes it.
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
  static String uriForRequest(PairingRequest request) =>
      '$uriPrefix${request.id}/${request.secret}';

  static PairingRequest newRequest() => PairingRequest(
        newSessionId(),
        base64UrlEncode(SyncCrypto.newPairingSecret()),
      );

  /// The session id and one-time encryption secret from the QR code.
  static PairingRequest? requestFromUri(String? value) {
    if (value == null || !value.startsWith(uriPrefix)) return null;
    final parts = value.substring(uriPrefix.length).split('/');
    if (parts.length != 2 || !RegExp(r'^[0-9a-f]{32}$').hasMatch(parts[0])) {
      return null;
    }
    try {
      final secret = base64Url.decode(base64Url.normalize(parts[1]));
      if (secret.length != 32) return null;
      return PairingRequest(parts[0], parts[1]);
    } on FormatException {
      return null;
    }
  }

  /// Computer side: waits for a phone to approve [request], then signs in.
  Future<Map<String, Object?>?> waitForApproval(
    PairingRequest request, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final document = _document(request.id);
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
      final wrapped = snapshot.data()?['wrappedKey'];
      if (wrapped is Map) {
        return await SyncCrypto().unwrapFromPairing(
          wrapped.cast<String, Object?>(),
          base64Url.decode(base64Url.normalize(request.secret)),
        );
      }
      return null;
    } on TimeoutException {
      throw const PairingException(PairingError.expired);
    } on FirebaseException {
      throw const PairingException(PairingError.failed);
    } finally {
      await cancel(request.id);
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

  /// Phone side: hands this phone's Google sign-in and sync key to the QR PC.
  Future<void> approve(
    PairingRequest request, {
    Map<String, Object?>? keyPackage,
  }) async {
    if (!canApprove) {
      throw const PairingException(PairingError.notGoogleAccount);
    }
    try {
      final google = _google ??= GoogleSignIn(scopes: const ['email']);
      final account = await google.signInSilently() ?? await google.signIn();
      final token = (await account?.authentication)?.idToken;
      if (token == null) throw const PairingException(PairingError.failed);
      final wrappedKey = keyPackage == null
          ? null
          : await SyncCrypto().wrapForPairing(
              keyPackage,
              base64Url.decode(base64Url.normalize(request.secret)),
            );
      await _document(request.id).set({
        'idToken': token,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
        if (wrappedKey != null) 'wrappedKey': wrappedKey,
      });
    } on FirebaseException {
      throw const PairingException(PairingError.failed);
    }
  }
}
