import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/sync_provider.dart';
import '../services/sync/sync_account.dart';
import '../services/sync/sync_crypto.dart';
import '../services/sync/sync_remote.dart';

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
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _showPassphrase = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _passphrase.dispose();
    _confirmation.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final l10n = context.l10n;
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
            if (!sync.available)
              Text(l10n.syncUnavailable)
            else if (sync.user == null)
              ..._signIn(context, sync)
            else ...[
              _account(context, sync),
              const SizedBox(height: 8),
              if (sync.enabled)
                ..._enabled(context, sync)
              else
                ..._setup(context, sync),
            ],
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
        title: Text(l10n.syncActive),
        subtitle: Text(syncStatusText(context, sync)),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: sync.busy ? null : () => _guard(context, sync.syncNow),
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

  Widget _account(BuildContext context, SyncProvider sync) {
    final user = sync.user!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.account_circle_outlined),
      title: Text(context.l10n
          .syncSignedInAs(user.email ?? user.displayName ?? user.uid)),
      trailing: TextButton(
        onPressed: sync.busy ? null : sync.signOut,
        child: Text(context.l10n.syncSignOut),
      ),
    );
  }

  List<Widget> _signIn(BuildContext context, SyncProvider sync) {
    final l10n = context.l10n;
    final busy = sync.busy;
    return [
      // google_sign_in has no Windows or Linux implementation.
      if (!Platform.isWindows && !Platform.isLinux) ...[
        FilledButton.icon(
          onPressed: busy
              ? null
              : () => _guard(context, sync.signInWithGoogle, signIn: true),
          icon: const Icon(Icons.account_circle_rounded),
          label: Text(l10n.syncSignInGoogle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(l10n.syncOr),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ),
      ],
      TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        autofillHints: const [AutofillHints.email],
        decoration: InputDecoration(labelText: l10n.syncEmail),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _password,
        obscureText: !_showPassword,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: const [AutofillHints.password],
        decoration: InputDecoration(
          labelText: l10n.syncPassword,
          suffixIcon: IconButton(
            tooltip: _showPassword ? l10n.hidePassphrase : l10n.showPassphrase,
            onPressed: () => setState(() => _showPassword = !_showPassword),
            icon: Icon(_showPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: FilledButton.tonal(
              onPressed: busy
                  ? null
                  : () => _guard(
                        context,
                        () => sync.signInWithEmail(_email.text, _password.text),
                        signIn: true,
                      ),
              child: Text(l10n.syncSignIn),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: busy
                  ? null
                  : () => _guard(
                        context,
                        () => sync.createAccount(_email.text, _password.text),
                        signIn: true,
                      ),
              child: Text(l10n.syncCreateAccount),
            ),
          ),
        ],
      ),
      TextButton(
        onPressed: busy ? null : () => _resetPassword(context, sync),
        child: Text(l10n.syncForgotPassword),
      ),
    ];
  }

  Future<void> _resetPassword(BuildContext context, SyncProvider sync) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _error = null);
    try {
      await sync.sendPasswordReset(_email.text);
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncResetSent)));
    } on SyncAuthException catch (error) {
      if (mounted) setState(() => _error = _authMessage(l10n, error));
    }
  }

  List<Widget> _setup(BuildContext context, SyncProvider sync) {
    final l10n = context.l10n;
    return [
      Text(l10n.syncPassphraseStep),
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
    FocusScope.of(context).unfocus();
    await _guard(context, () => sync.enable(passphrase));
  }

  Future<void> _guard(
    BuildContext context,
    Future<void> Function() action, {
    bool signIn = false,
  }) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _error = null);
    FocusScope.of(context).unfocus();
    try {
      await action();
      if (signIn) {
        _password.clear();
      } else {
        messenger.showSnackBar(SnackBar(content: Text(l10n.syncDone)));
      }
    } on SyncAuthException catch (error) {
      debugPrint('Sync sign-in failed: $error');
      if (mounted && error.error != SyncAuthError.cancelled) {
        setState(() => _error = _authMessage(l10n, error));
      }
    } on SyncPassphraseException {
      if (mounted) setState(() => _error = l10n.syncWrongPassphrase);
    } on SyncConflictException {
      if (mounted) setState(() => _error = l10n.syncConflict);
    } catch (error) {
      final detail = _describe(error);
      debugPrint('Sync failed: $detail');
      if (mounted) setState(() => _error = '${l10n.syncFailed} ($detail)');
    }
  }

  static String _authMessage(AppLocalizations l10n, SyncAuthException error) =>
      switch (error.error) {
        SyncAuthError.invalidCredentials => l10n.syncAuthInvalidCredentials,
        SyncAuthError.invalidEmail => l10n.syncAuthInvalidEmail,
        SyncAuthError.emailInUse => l10n.syncAuthEmailInUse,
        SyncAuthError.weakPassword => l10n.syncAuthWeakPassword,
        SyncAuthError.tooManyRequests => l10n.syncAuthTooManyRequests,
        SyncAuthError.network => l10n.syncAuthNetwork,
        SyncAuthError.cancelled ||
        SyncAuthError.unknown =>
          l10n.syncAuthFailed,
      };

  /// A short cause without data or credentials: backend code or type.
  static String _describe(Object error) =>
      error is FirebaseException ? error.code : error.runtimeType.toString();
}
