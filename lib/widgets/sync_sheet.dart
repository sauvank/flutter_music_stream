import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/server_profile.dart';
import '../providers/sync_provider.dart';
import '../services/sync/sync_crypto.dart';
import '../services/sync/sync_service.dart';

Future<void> showSyncSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _SyncSheet(),
    );

/// Localized date and time of the last sync, or a "never" label.
String syncStatusText(BuildContext context, SyncProvider sync) {
  final last = sync.settings?.lastSyncAt?.toLocal();
  if (last == null) return context.l10n.syncNever;
  final material = MaterialLocalizations.of(context);
  return context.l10n.syncLastRun(
    '${material.formatShortDate(last)} '
    '${material.formatTimeOfDay(TimeOfDay.fromDateTime(last))}',
  );
}

class _SyncSheet extends StatefulWidget {
  const _SyncSheet();

  @override
  State<_SyncSheet> createState() => _SyncSheetState();
}

class _SyncSheetState extends State<_SyncSheet> {
  final _passphrase = TextEditingController();
  final _confirmation = TextEditingController();
  ServerProfile? _profile;
  String? _error;
  bool _showPassphrase = false;

  @override
  void dispose() {
    _passphrase.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final l10n = context.l10n;
    final profiles = sync.eligibleProfiles;
    _profile ??= profiles.firstOrNull;
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
              l10n.syncTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(l10n.syncExplanation),
            const SizedBox(height: 18),
            if (sync.enabled)
              ..._enabled(context, sync)
            else if (profiles.isEmpty)
              Text(l10n.syncNeedsWebdav)
            else
              ..._setup(context, sync, profiles),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _enabled(BuildContext context, SyncProvider sync) {
    final l10n = context.l10n;
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.cloud_done_outlined),
        title: Text(sync.profile?.name ?? l10n.syncServerMissing),
        subtitle: Text(syncStatusText(context, sync)),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: sync.busy || sync.profile == null
            ? null
            : () => _guard(context, sync.syncNow),
        icon: sync.busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.sync_rounded),
        label: Text(l10n.syncNow),
      ),
      TextButton(
        onPressed: sync.busy ? null : sync.disable,
        child: Text(l10n.syncDisable),
      ),
    ];
  }

  List<Widget> _setup(
    BuildContext context,
    SyncProvider sync,
    List<ServerProfile> profiles,
  ) {
    final l10n = context.l10n;
    return [
      DropdownButtonFormField<ServerProfile>(
        value: _profile,
        decoration: InputDecoration(labelText: l10n.syncServer),
        items: [
          for (final profile in profiles)
            DropdownMenuItem(value: profile, child: Text(profile.name)),
        ],
        onChanged: (profile) => setState(() => _profile = profile),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _passphrase,
        obscureText: !_showPassphrase,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: l10n.syncPassphrase,
          suffixIcon: IconButton(
            tooltip:
                _showPassphrase ? l10n.hidePassphrase : l10n.showPassphrase,
            onPressed: () => setState(() => _showPassphrase = !_showPassphrase),
            icon: Icon(_showPassphrase
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined),
          ),
          helperText: l10n.syncPassphraseHint,
          helperMaxLines: 3,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _confirmation,
        obscureText: !_showPassphrase,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(labelText: l10n.syncPassphraseConfirm),
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: sync.busy ? null : () => _enable(context, sync),
        icon: sync.busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.lock_outline_rounded),
        label: Text(l10n.syncEnable),
      ),
    ];
  }

  Future<void> _enable(BuildContext context, SyncProvider sync) async {
    final l10n = context.l10n;
    final passphrase = _passphrase.text;
    if (passphrase.length < 8) {
      setState(() => _error = l10n.syncPassphraseTooShort);
      return;
    }
    if (passphrase != _confirmation.text) {
      setState(() => _error = l10n.syncPassphraseMismatch);
      return;
    }
    final profile = _profile;
    if (profile == null) return;
    FocusScope.of(context).unfocus();
    await _guard(context, () => sync.enable(profile, passphrase));
  }

  Future<void> _guard(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _error = null);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncDone)));
    } on SyncPassphraseException {
      if (mounted) setState(() => _error = l10n.syncWrongPassphrase);
    } on SyncConflictException {
      if (mounted) setState(() => _error = l10n.syncConflict);
    } on SyncWriteForbiddenException catch (error) {
      if (mounted) {
        setState(() => _error = l10n.syncWriteForbidden(error.statusCode));
      }
    } catch (error) {
      final detail = _describe(error);
      debugPrint('Sync failed: $detail');
      if (mounted) setState(() => _error = '${l10n.syncFailed} ($detail)');
    }
  }

  /// A short cause without URLs or credentials: HTTP status, network error
  /// kind or exception type.
  static String _describe(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final method = error.requestOptions.method;
      return status != null ? '$method HTTP $status' : error.type.name;
    }
    return error.runtimeType.toString();
  }
}
