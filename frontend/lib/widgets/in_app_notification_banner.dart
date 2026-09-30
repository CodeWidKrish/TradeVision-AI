import 'package:flutter/material.dart';

/// Transparent wrapper around app root.
/// Per user requirement: In-app popup banners are fully disabled so that notifications
/// only appear in the mobile/device notification center (drag down / status bar).
class InAppNotificationBanner extends StatelessWidget {
  final Widget child;

  const InAppNotificationBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
