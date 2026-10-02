import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';

/// Desktop builds have no native Firebase config file. CI passes the web app
/// configuration, base64-encoded JSON, through
/// `--dart-define=FIREBASE_DESKTOP_CONFIG_B64=...`; without it, sync stays off.
FirebaseOptions? desktopFirebaseOptions() {
  const encoded = String.fromEnvironment('FIREBASE_DESKTOP_CONFIG_B64');
  if (encoded.isEmpty) return null;
  final json = (jsonDecode(utf8.decode(base64.decode(encoded))) as Map)
      .cast<String, String>();
  return FirebaseOptions(
    apiKey: json['apiKey']!,
    appId: json['appId']!,
    messagingSenderId: json['messagingSenderId']!,
    projectId: json['projectId']!,
    authDomain: json['authDomain'],
    storageBucket: json['storageBucket'],
  );
}
