import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/geotagging/data/services/raw_thumbnail_service.dart';

const _prefKeyDontShowAgain = 'exiftool_reminder_dont_show_again';

/// Shows a one-time reminder on desktop when exiftool is not installed.
/// Uses a "Don't show this again" checkbox and persists the choice.
class ExiftoolReminderOverlay extends StatefulWidget {
  const ExiftoolReminderOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<ExiftoolReminderOverlay> createState() => _ExiftoolReminderOverlayState();
}

class _ExiftoolReminderOverlayState extends State<ExiftoolReminderOverlay> {
  bool _checkDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowReminder());
  }

  Future<void> _maybeShowReminder() async {
    if (!mounted || _checkDone) return;
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKeyDontShowAgain) == true) return;

    final deps = await RawThumbnailService.instance.checkDependencies();
    if (deps.exiftoolAvailable) return;

    _checkDone = true;
    if (!mounted) return;
    await showExiftoolReminderDialog(
      context: context,
      onDontShowAgain: (value) async {
        await prefs.setBool(_prefKeyDontShowAgain, value);
      },
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Shows the exiftool reminder dialog. Returns when the dialog is closed.
Future<void> showExiftoolReminderDialog({
  required BuildContext context,
  required Future<void> Function(bool dontShowAgain) onDontShowAgain,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _ExiftoolReminderDialog(
      onOk: (dontShowAgain) async {
        Navigator.of(context).pop();
        await onDontShowAgain(dontShowAgain);
      },
    ),
  );
}

class _ExiftoolReminderDialog extends StatefulWidget {
  const _ExiftoolReminderDialog({required this.onOk});

  final void Function(bool dontShowAgain) onOk;

  @override
  State<_ExiftoolReminderDialog> createState() => _ExiftoolReminderDialogState();
}

class _ExiftoolReminderDialogState extends State<_ExiftoolReminderDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final isWindows = Platform.isWindows;
    final installHint = isWindows
        ? 'Install exiftool (e.g. winget install exiftool) to write location into photo files. Until then, location is saved to .xmp sidecar files.'
        : 'Install exiftool (e.g. pacman -S perl-image-exiftool) to write location into photo files and to show RAW thumbnails. Until then, location is saved to .xmp sidecar files.';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 12),
          Text('exiftool not found'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(installHint),
            const SizedBox(height: 20),
            CheckboxListTile(
              value: _dontShowAgain,
              onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
              title: const Text('Don\'t show this again'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => widget.onOk(_dontShowAgain),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
