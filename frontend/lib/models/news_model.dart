class NewsItem {
  final String title;
  final String source;
  final String url;
  final String publishedAt;

  NewsItem({
    required this.title,
    required this.source,
    required this.url,
    required this.publishedAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      title: json['title'] as String? ?? '',
      source: json['source'] as String? ?? '',
      url: json['url'] as String? ?? '',
      publishedAt: json['published_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'source': source,
      'url': url,
      'published_at': publishedAt,
    };
  }
}

class NewsModel {
  final String symbol;
  final List<NewsItem> articles;
  final String message;

  NewsModel({
    required this.symbol,
    required this.articles,
    this.message = 'News loaded',
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    final rawArticles = json['articles'];
    List<NewsItem> parsedArticles = [];
    if (rawArticles is List) {
      parsedArticles = rawArticles
          .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return NewsModel(
      symbol: json['symbol'] as String? ?? '',
      articles: parsedArticles,
      message: json['message'] as String? ?? 'News loaded',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'articles': articles.map((e) => e.toJson()).toList(),
      'message': message,
    };
  }
}
