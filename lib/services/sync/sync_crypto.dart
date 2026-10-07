import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// The passphrase does not open this sync file.
class SyncPassphraseException implements Exception {
  const SyncPassphraseException();
}

/// Key derivation parameters stored in clear next to the cipher text, so
/// every device derives the same key from the same passphrase.
class SyncKdf {
  const SyncKdf({required this.salt, this.iterations = defaultIterations});

  static const defaultIterations = 310000;

  final List<int> salt;
  final int iterations;

  Map<String, Object?> toJson() => {
        'name': 'pbkdf2-sha256',
        'iterations': iterations,
        'salt': base64UrlEncode(salt),
      };

  factory SyncKdf.fromJson(Map<String, Object?> json) {
    if (json['name'] != 'pbkdf2-sha256') {
      throw const FormatException('Unknown key derivation');
    }
    return SyncKdf(
      salt: base64Url.decode(json['salt']! as String),
      iterations: json['iterations']! as int,
    );
  }
}

/// AES-256-GCM envelope: the server only stores the salt, nonce, cipher
/// text and authentication tag, never the metadata in clear.
class SyncCrypto {
  SyncCrypto({Cipher? cipher}) : _cipher = cipher ?? AesGcm.with256bits();

  static const format = 'musicstream-sync';
  final Cipher _cipher;

  static List<int> newSalt() => SecretKeyData.random(length: 16).bytes;
  static List<int> newPairingSecret() => SecretKeyData.random(length: 32).bytes;

  Future<Map<String, Object?>> wrapForPairing(
    Map<String, Object?> value,
    List<int> pairingSecret,
  ) async {
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(value)),
      secretKey: SecretKey(pairingSecret),
    );
    return {
      'nonce': base64UrlEncode(box.nonce),
      'ciphertext': base64UrlEncode(box.cipherText),
      'mac': base64UrlEncode(box.mac.bytes),
    };
  }

  Future<Map<String, Object?>> unwrapFromPairing(
    Map<String, Object?> wrapped,
    List<int> pairingSecret,
  ) async {
    final box = SecretBox(
      base64Url.decode(wrapped['ciphertext']! as String),
      nonce: base64Url.decode(wrapped['nonce']! as String),
      mac: Mac(base64Url.decode(wrapped['mac']! as String)),
    );
    try {
      return (jsonDecode(utf8.decode(await _cipher.decrypt(
        box,
        secretKey: SecretKey(pairingSecret),
      ))) as Map)
          .cast<String, Object?>();
    } on SecretBoxAuthenticationError {
      throw const FormatException('Invalid pairing secret');
    }
  }

  Future<List<int>> deriveKey(String passphrase, SyncKdf kdf) async {
    final key = await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: kdf.iterations,
      bits: 256,
    ).deriveKeyFromPassword(password: passphrase, nonce: kdf.salt);
    return key.extractBytes();
  }

  Future<Map<String, Object?>> seal(
    Map<String, Object?> payload, {
    required List<int> key,
    required SyncKdf kdf,
  }) async {
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(payload)),
      secretKey: SecretKey(key),
    );
    return {
      'format': format,
      'v': 1,
      'kdf': kdf.toJson(),
      'nonce': base64UrlEncode(box.nonce),
      'ciphertext': base64UrlEncode(box.cipherText),
      'mac': base64UrlEncode(box.mac.bytes),
    };
  }

  static SyncKdf kdfOf(Map<String, Object?> envelope) {
    if (envelope['format'] != format || envelope['v'] != 1) {
      throw const FormatException('Unknown sync file');
    }
    return SyncKdf.fromJson((envelope['kdf']! as Map).cast<String, Object?>());
  }

  Future<Map<String, Object?>> open(
    Map<String, Object?> envelope, {
    required List<int> key,
  }) async {
    kdfOf(envelope);
    final box = SecretBox(
      base64Url.decode(envelope['ciphertext']! as String),
      nonce: base64Url.decode(envelope['nonce']! as String),
      mac: Mac(base64Url.decode(envelope['mac']! as String)),
    );
    try {
      final clear = await _cipher.decrypt(box, secretKey: SecretKey(key));
      return (jsonDecode(utf8.decode(clear)) as Map).cast<String, Object?>();
    } on SecretBoxAuthenticationError {
      throw const SyncPassphraseException();
    }
  }
}
