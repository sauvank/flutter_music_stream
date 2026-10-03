import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/l10n.dart';
import '../models/server_profile.dart';
import '../providers/server_provider.dart';

/// Result of the sheet: the profile and its password (kept out of the profile).
typedef NewServer = (ServerProfile, String);

Future<NewServer?> showAddServerSheet(BuildContext context) =>
    showModalBottomSheet<NewServer>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddServerSheet(),
    );

class _AddServerSheet extends StatefulWidget {
  const _AddServerSheet();

  @override
  State<_AddServerSheet> createState() => _AddServerSheetState();
}

class _AddServerSheetState extends State<_AddServerSheet> {
  final _name = TextEditingController();
  final _url = TextEditingController(text: 'https://');
  final _username = TextEditingController();
  final _password = TextEditingController();
  var _type = ServerType.webdav;
  var _showErrors = false;
  var _showPassword = false;
  var _testing = false;
  String? _failure;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _validAddress {
    final uri = Uri.tryParse(_url.text.trim());
    final validScheme = _type == ServerType.ftp
        ? uri?.scheme == 'ftp'
        : {'http', 'https'}.contains(uri?.scheme);
    return uri != null &&
        validScheme &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty;
  }

  void _edited() => setState(() => _failure = null);

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || !_validAddress) {
      setState(() => _showErrors = true);
      return;
    }
    final servers = context.read<ServerProvider>();
    final l10n = context.l10n;
    final profile = ServerProfile(
      id: const Uuid().v4(),
      name: _name.text.trim(),
      baseUrl: Uri.parse(_url.text.trim()).toString(),
      type: _type,
      username: _username.text.trim(),
    );
    // After a failed test, a second tap saves anyway.
    if (_failure == null) {
      setState(() => _testing = true);
      final error = await servers.testConnection(profile, _password.text);
      if (!mounted) return;
      if (error != null) {
        final status =
            error is DioException ? error.response?.statusCode : null;
        setState(() {
          _testing = false;
          _failure = status == null
              ? l10n.connectionTestFailed
              : l10n.connectionTestFailedStatus(status);
        });
        return;
      }
    }
    Navigator.pop(context, (profile, _password.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final ftp = _type == ServerType.ftp;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.addServer,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(l10n.addServerHint),
            const SizedBox(height: 18),
            TextField(
              controller: _name,
              enabled: !_testing,
              autocorrect: false,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.name,
                errorText: _showErrors && _name.text.trim().isEmpty
                    ? l10n.serverNameRequired
                    : null,
              ),
              onChanged: (_) => _edited(),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ServerType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ServerType.webdav, label: Text('WebDAV')),
                ButtonSegment(value: ServerType.http, label: Text('HTTP')),
                ButtonSegment(value: ServerType.ftp, label: Text('FTP')),
              ],
              selected: {_type},
              onSelectionChanged: _testing
                  ? null
                  : (value) => setState(() {
                        _type = value.single;
                        _failure = null;
                        if (_url.text == 'https://' || _url.text == 'ftp://') {
                          _url.text =
                              _type == ServerType.ftp ? 'ftp://' : 'https://';
                        }
                      }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _url,
              enabled: !_testing,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: ftp ? l10n.ftpAddress : l10n.httpAddress,
                errorText: _showErrors && !_validAddress
                    ? (ftp
                        ? l10n.serverAddressInvalidFtp
                        : l10n.serverAddressInvalidHttp)
                    : null,
                errorMaxLines: 3,
              ),
              onChanged: (_) => _edited(),
            ),
            if (ftp)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.ftpUnencrypted,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _username,
              enabled: !_testing,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.usernameOptional),
              onChanged: (_) => _edited(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              enabled: !_testing,
              obscureText: !_showPassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.password,
                suffixIcon: IconButton(
                  tooltip:
                      _showPassword ? l10n.hidePassword : l10n.showPassword,
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(_showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                ),
              ),
              onChanged: (_) => _edited(),
            ),
            if (_failure != null) ...[
              const SizedBox(height: 12),
              Text(
                _failure!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _testing ? null : _save,
              icon: _testing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_failure == null
                      ? Icons.wifi_tethering_rounded
                      : Icons.save_outlined),
              label: Text(_testing
                  ? l10n.testingConnection
                  : _failure == null
                      ? l10n.saveAndTest
                      : l10n.saveAnyway),
            ),
            TextButton(
              onPressed: _testing ? null : () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
