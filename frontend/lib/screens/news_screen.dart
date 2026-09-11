import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/ticker_logo.dart';
import '../core/data/stock_data.dart';

class NewsArticle {
  final String title;
  final String summary;
  final String source;
  final String timeAgo;
  final String relatedTicker;
  final String sentiment; // 'Bullish', 'Bearish', 'Neutral'
  final String category;

  const NewsArticle({
    required this.title,
    required this.summary,
    required this.source,
    required this.timeAgo,
    required this.relatedTicker,
    required this.sentiment,
    required this.category,
  });
}

class NewsScreen extends StatefulWidget {
  final Function(StockModel stock)? onSelectStock;

  const NewsScreen({
    super.key,
    this.onSelectStock,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String selectedCategory = 'All';

  final List<NewsArticle> articles = const [
    NewsArticle(
      title: 'Reliance Industries Announces ₹75,000 Cr Clean Energy Expansion Plan',
      summary: 'RIL board approves major capital allocation towards solar giga-factories and green hydrogen hubs in Gujarat.',
      source: 'Economic Times',
      timeAgo: '12m ago',
      relatedTicker: 'RELIANCE',
      sentiment: 'Bullish',
      category: 'Markets',
    ),
    NewsArticle(
      title: 'HDFC Bank Q1 Net Profit Jumps 18% YoY to ₹16,175 Cr on Lower NPAs',
      summary: 'Asset quality improves significantly with Gross NPA dropping to 1.22%. Retail loan growth outperforms estimates.',
      source: 'Mint',
      timeAgo: '45m ago',
      relatedTicker: 'HDFCBANK',
      sentiment: 'Bullish',
      category: 'Earnings',
    ),
    NewsArticle(
      title: 'RBI Keeps Repo Rate Unchanged at 6.5%; Maintains "Withdrawal of Accommodation" Stance',
      summary: 'Governor Shaktikanta Das highlights inflation moderation while keeping GDP growth target firm at 7.2%.',
      source: 'Business Standard',
      timeAgo: '2h ago',
      relatedTicker: 'SBIN',
      sentiment: 'Neutral',
      category: 'Economy',
    ),
    NewsArticle(
      title: 'TCS & Infosys Facing Short-Term US Banking IT Spend Slowdown',
      summary: 'Gartner report indicates enterprise software buyers delaying discretionary cloud migration projects till Q3.',
      source: 'Moneycontrol',
      timeAgo: '3h ago',
      relatedTicker: 'TCS',
      sentiment: 'Bearish',
      category: 'Tech',
    ),
    NewsArticle(
      title: 'State Bank of India Raises \$1 Billion via Green Bonds on London Stock Exchange',
      summary: 'Over-subscribed by 3.5x as global ESG funds rush to back India sovereign sustainable financing pool.',
      source: 'Financial Express',
      timeAgo: '5h ago',
      relatedTicker: 'SBIN',
      sentiment: 'Bullish',
      category: 'Markets',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategory == 'All'
        ? articles
        : articles.where((a) => a.category == selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.fromLTRB(AppDim.screenH, 16, AppDim.screenH, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'News & Market Flow',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Real-time Indian Stock Market News',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Filter category chips
              FilterChipRow(
                options: const ['All', 'Markets', 'Earnings', 'Economy', 'Tech'],
                selectedOption: selectedCategory,
                onSelected: (cat) {
                  setState(() {
                    selectedCategory = cat;
                  });
                },
              ),

              // News List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH),
                child: Column(
                  children: filtered.map((article) => _buildArticleCard(article)).toList(),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleCard(NewsArticle article) {
    Color sentimentColor;
    Color sentimentBg;
    if (article.sentiment == 'Bullish') {
      sentimentColor = AppColors.gain;
      sentimentBg = AppColors.gainBg;
    } else if (article.sentiment == 'Bearish') {
      sentimentColor = AppColors.loss;
      sentimentBg = AppColors.lossBg;
    } else {
      sentimentColor = AppColors.warning;
      sentimentBg = AppColors.warningBg;
    }

    final stock = StockRepository.getStock(article.relatedTicker);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDim.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDim.radiusLg),
          onTap: () => _showArticleModal(article),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta Row: Ticker Logo + Source + Time + Sentiment Badge
                Row(
                  children: [
                    TickerLogo(
                      ticker: stock.ticker,
                      logoUrl: stock.logoUrl,
                      logoColor: stock.logoColor,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      article.source,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${article.timeAgo}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: sentimentBg,
                        borderRadius: BorderRadius.circular(AppDim.radiusPill),
                      ),
                      child: Text(
                        article.sentiment.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: sentimentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Title
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                // Summary
                Text(
                  article.summary,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showArticleModal(NewsArticle article) {
    final stock = StockRepository.getStock(article.relatedTicker);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppDim.screenH,
            20,
            AppDim.screenH,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      article.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${article.source} • ${article.timeAgo}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                article.summary,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: AppDim.btnHeight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onSelectStock != null) {
                      widget.onSelectStock!(stock);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Analyze ${stock.ticker}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
