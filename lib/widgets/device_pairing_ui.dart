import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/sync_provider.dart';
import '../services/sync/device_pairing.dart';

String _pairingMessage(BuildContext context, PairingError error) =>
    switch (error) {
      PairingError.notGoogleAccount => context.l10n.pairGoogleOnly,
      PairingError.invalidCode => context.l10n.pairInvalidCode,
      PairingError.expired => context.l10n.pairExpired,
      PairingError.failed => context.l10n.pairFailed,
    };

/// Computer side: shows a QR code and waits until a phone signs this device in.
Future<void> showPairingQrDialog(BuildContext context) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PairingQrDialog(),
    );

class _PairingQrDialog extends StatefulWidget {
  const _PairingQrDialog();

  @override
  State<_PairingQrDialog> createState() => _PairingQrDialogState();
}

class _PairingQrDialogState extends State<_PairingQrDialog> {
  final _pairing = DevicePairing();
  final _request = DevicePairing.newRequest();
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_wait());
  }

  Future<void> _wait() async {
    final sync = context.read<SyncProvider>();
    final l10n = context.l10n;
    try {
      final keyPackage = await _pairing.waitForApproval(_request);
      if (keyPackage != null && mounted) {
        await sync.acceptPairingKeyPackage(keyPackage);
      }
      if (mounted) Navigator.of(context).pop();
    } on PairingException catch (error) {
      if (mounted) {
        setState(() => _error = _pairingMessage(context, error.error));
      }
    } catch (_) {
      if (mounted) setState(() => _error = l10n.pairFailed);
    }
  }

  @override
  void dispose() {
    unawaited(_pairing.cancel(_request.id));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.pairQrTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A white tile keeps the code scannable in dark mode.
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: QrImageView(
                data: DevicePairing.uriForRequest(_request),
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.pairQrHint),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else
              Row(
                children: [
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.pairWaiting),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

/// Phone side: scans the computer's QR code, asks for confirmation, then
/// signs the computer in with this phone's Google account.
Future<void> connectComputer(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final sync = context.read<SyncProvider>();
  final request = await Navigator.of(context).push<PairingRequest>(
    MaterialPageRoute(builder: (_) => const _PairingScannerPage()),
  );
  if (request == null || !context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.pairConfirmTitle),
      content: Text(l10n.pairConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.pairConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await DevicePairing().approve(
      request,
      keyPackage: await sync.pairingKeyPackage(),
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.pairDone)));
  } on PairingException catch (error) {
    final message = switch (error.error) {
      PairingError.notGoogleAccount => l10n.pairGoogleOnly,
      PairingError.invalidCode => l10n.pairInvalidCode,
      PairingError.expired => l10n.pairExpired,
      PairingError.failed => l10n.pairFailed,
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PairingScannerPage extends StatefulWidget {
  const _PairingScannerPage();

  @override
  State<_PairingScannerPage> createState() => _PairingScannerPageState();
}

class _PairingScannerPageState extends State<_PairingScannerPage> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final request = DevicePairing.requestFromUri(barcode.rawValue);
      if (request != null) {
        _done = true;
        Navigator.of(context).pop(request);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.pairScanTitle)),
        body: MobileScanner(controller: _controller, onDetect: _onDetect),
      );
}
