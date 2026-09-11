import 'package:flutter/material.dart';
import '../core/state/async_view_state.dart';
import 'empty_state_widget.dart';

class AsyncStateView<T> extends StatelessWidget {
  final AsyncViewState<T> state;
  final Widget Function(T data) onData;
  final Widget Function()? onLoading;
  final VoidCallback? onRetry;

  const AsyncStateView({
    super.key,
    required this.state,
    required this.onData,
    this.onLoading,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ViewLoading() => onLoading?.call() ?? const _DefaultSkeleton(),
      ViewData(:final data) => onData(data),
      ViewError(:final message) => EmptyStateWidget(
          icon: Icons.wifi_off_rounded,
          title: "Couldn't load data",
          subtitle: message.isEmpty ? 'Check your connection and try again.' : message,
          actionLabel: 'Retry',
          onAction: onRetry ?? () {},
        ),
    };
  }
}

class _DefaultSkeleton extends StatelessWidget {
  const _DefaultSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
