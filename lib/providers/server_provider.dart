import 'package:flutter/foundation.dart';

import '../models/remote_audio_entry.dart';
import '../models/server_profile.dart';
import '../services/remote_server_service.dart';
import '../services/server_profile_service.dart';

class ServerProvider extends ChangeNotifier {
  ServerProvider(this._profilesService, this.remoteService);

  final ServerProfileService _profilesService;
  final RemoteServerService remoteService;
  final List<ServerProfile> profiles = [];
  final List<RemoteAudioEntry> entries = [];
  final List<Uri> _history = [];
  ServerProfile? selected;
  Uri? currentUri;
  String _password = '';
  bool loading = false;
  String? error;

  bool get canGoBack => _history.isNotEmpty;
  String get password => _password;

  Future<void> load() async {
    profiles
      ..clear()
      ..addAll(await _profilesService.load());
    notifyListeners();
  }

  Future<void> addProfile(ServerProfile profile, String password) async {
    profiles.add(profile);
    await _profilesService.save(profiles);
    await _profilesService.writePassword(profile.id, password);
    notifyListeners();
  }

  Future<void> deleteProfile(ServerProfile profile) async {
    profiles.removeWhere((item) => item.id == profile.id);
    if (selected?.id == profile.id) disconnect();
    await _profilesService.save(profiles);
    await _profilesService.deletePassword(profile.id);
    notifyListeners();
  }

  Future<void> connect(ServerProfile profile) async {
    selected = profile;
    _password = await _profilesService.readPassword(profile.id);
    _history.clear();
    await _open(_normalizedRoot(profile.baseUrl));
  }

  Future<void> openDirectory(RemoteAudioEntry entry) async {
    if (!entry.isDirectory || currentUri == null) return;
    _history.add(currentUri!);
    await _open(entry.uri);
  }

  Future<void> goBack() async {
    if (_history.isEmpty) return;
    await _open(_history.removeLast());
  }

  void disconnect() {
    selected = null;
    currentUri = null;
    _password = '';
    entries.clear();
    _history.clear();
    error = null;
    notifyListeners();
  }

  Future<void> _open(Uri uri) async {
    final profile = selected;
    if (profile == null) return;
    loading = true;
    error = null;
    currentUri = uri;
    notifyListeners();
    try {
      entries
        ..clear()
        ..addAll(await remoteService.list(profile, uri, _password));
    } catch (exception) {
      error = 'Connexion impossible. Vérifiez l’adresse et les identifiants.';
      debugPrint('Server listing failed: ${exception.runtimeType}');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Uri _normalizedRoot(String value) {
    final uri = Uri.parse(value.trim());
    return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
  }
}
