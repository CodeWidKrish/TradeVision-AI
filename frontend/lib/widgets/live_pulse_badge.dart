import 'package:flutter/material.dart';

class LivePulseBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const LivePulseBadge({
    super.key,
    this.label = '',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
