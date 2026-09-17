import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../providers/market_providers.dart';
import '../services/live_news_service.dart';

class MarketNewsWidget extends ConsumerWidget {
  const MarketNewsWidget({super.key});

  Color _sentimentColor(String? sentiment) {
    final s = sentiment?.toUpperCase() ?? 'NEUTRAL';
    if (s == 'BULLISH') return AppColors.gain;
    if (s == 'BEARISH') return AppColors.loss;
    return AppColors.warning;
  }

  Future<void> _openArticle(BuildContext context, String? urlStr) async {
    if (urlStr == null || urlStr.isEmpty || urlStr == '#') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Original source link unavailable for this preview.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(urlStr);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open link: $urlStr'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final newsAsync = ref.watch(marketNewsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Latest News • Realtime Stream',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => ref.refresh(marketNewsProvider),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        newsAsync.when(
          loading: () {
            final list = LiveNewsService.getInitialArticles().take(5).toList();
            return _buildArticlesList(context, theme, list);
          },
          error: (err, stack) {
            final list = LiveNewsService.getInitialArticles().take(5).toList();
            return _buildArticlesList(context, theme, list);
          },
          data: (articles) {
            final list = (articles.isNotEmpty ? articles : LiveNewsService.getInitialArticles()).take(5).toList();
            return _buildArticlesList(context, theme, list);
          },
        ),
      ],
    );
  }

  Widget _buildArticlesList(BuildContext context, ThemeData theme, List<Map<String, dynamic>> displayList) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH),
      itemCount: displayList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final news = displayList[index];
        final sentiment = (news['sentiment'] as String?)?.toUpperCase() ?? 'NEUTRAL';
        final color = _sentimentColor(sentiment);
        final source = (news['source'] as String?) ?? 'Market News';
        final timeAgo = (news['time_ago'] as String?) ?? 'Just now';
        final title = (news['title'] as String?) ?? '';
        final url = news['url'] as String?;
        final related = news['related_ticker'] as String?;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openArticle(context, url),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor, width: 1.2),
            ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      source,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '• $timeAgo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (related != null && related.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        related,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                sentiment,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
          ),
        );
      },
    );
  }

}
