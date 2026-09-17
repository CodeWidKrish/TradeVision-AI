// lib/widgets/live_news_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/market_data_provider.dart';

class LiveNewsSection extends ConsumerWidget {
  const LiveNewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final newsState = ref.watch(newsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Latest News • Realtime Stream',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFE8ECF0)
                        : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(newsProvider.notifier).refresh();
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: Color(0xFF8892A4),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // News list
        newsState.when(
          loading: () => const _NewsShimmer(),
          error: (_, __) => const _NewsError(),
          data: (articles) => articles.isEmpty
              ? const _NewsEmpty()
              : Column(
                  children: articles
                      .map((a) => _NewsCard(article: a, isDark: isDark))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticle article;
  final bool isDark;
  const _NewsCard({required this.article, required this.isDark});

  Future<void> _launchUrl(BuildContext context, String urlStr) async {
    if (urlStr.isEmpty || urlStr == '#') return;
    final uri = Uri.tryParse(urlStr);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $urlStr')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color sentColor;
    try {
      sentColor = Color(int.parse('FF${article.sentimentColor}', radix: 16));
    } catch (_) {
      sentColor = const Color(0xFFFF8C00);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _launchUrl(context, article.url),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source + time + sentiment
            Row(
              children: [
                Flexible(
                  child: Text(
                    article.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0066CC),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '• ${article.timeAgo}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF8892A4),
                  ),
                ),
                const Spacer(),
                // Sentiment badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: sentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: sentColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    article.sentiment,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: sentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              article.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFE8ECF0)
                    : const Color(0xFF1A1A2E),
                height: 1.4,
              ),
            ),
            if (article.mentionedStocks.isNotEmpty) ...[
              const SizedBox(height: 8),
              // Mentioned stocks chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: article.mentionedStocks
                      .map(
                        (s) => Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0066CC).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            s,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0066CC),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewsShimmer extends StatelessWidget {
  const _NewsShimmer();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 100,
    child: Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0066CC),
        strokeWidth: 2,
      ),
    ),
  );
}

class _NewsError extends StatelessWidget {
  const _NewsError();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(
      'Unable to load news. Check connection.',
      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8892A4)),
    ),
  );
}

class _NewsEmpty extends StatelessWidget {
  const _NewsEmpty();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(
      'No news available right now.',
      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8892A4)),
    ),
  );
}
