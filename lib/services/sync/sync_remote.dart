import 'package:cloud_firestore/cloud_firestore.dart';

/// The shared encrypted envelope, with the revision needed to replace it
/// safely.
typedef RemoteSyncFile = ({Map<String, Object?> envelope, int revision});

/// Another device replaced the envelope between download and upload.
class SyncConflictException implements Exception {
  const SyncConflictException();
}

/// Where an account keeps its encrypted envelope.
abstract class SyncRemote {
  Future<RemoteSyncFile?> download(String uid);

  /// Stores [envelope] only if the remote copy is still [replacing].
  Future<void> upload(
    String uid,
    Map<String, Object?> envelope, {
    required RemoteSyncFile? replacing,
  });
}

/// One Firestore document per account, `users/{uid}`, readable and
/// writable only by that account (see `firestore.rules`). It only ever
/// holds cipher text.
class FirestoreSyncRemote implements SyncRemote {
  FirestoreSyncRemote({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Future<RemoteSyncFile?> download(String uid) async {
    // Always ask the server: a cached copy could hide another device's sync.
    final snapshot =
        await _document(uid).get(const GetOptions(source: Source.server));
    return _read(snapshot);
  }

  @override
  Future<void> upload(
    String uid,
    Map<String, Object?> envelope, {
    required RemoteSyncFile? replacing,
  }) =>
      _firestore.runTransaction((transaction) async {
        final document = _document(uid);
        final current = _read(await transaction.get(document));
        if (current?.revision != replacing?.revision) {
          throw const SyncConflictException();
        }
        transaction.set(document, {
          'envelope': envelope,
          'revision': (current?.revision ?? 0) + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

  static RemoteSyncFile? _read(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final envelope = data?['envelope'];
    if (envelope is! Map) return null;
    return (
      envelope: envelope.cast<String, Object?>(),
      revision: (data!['revision'] as num?)?.toInt() ?? 0,
    );
  }
}
