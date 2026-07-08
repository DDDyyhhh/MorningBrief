class NewsArticle {
  NewsArticle({
    required this.title,
    required this.summary,
    required this.source,
    required this.url,
    required this.publishedAt,
  });

  final String title;
  final String summary;
  final String source;
  final Uri url;
  final DateTime publishedAt;

  Map<String, dynamic> toJson() => {
    'title': title,
    'summary': summary,
    'source': source,
    'url': url.toString(),
    'publishedAt': publishedAt.toIso8601String(),
  };

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
    title: json['title'] as String,
    summary: json['summary'] as String,
    source: json['source'] as String,
    url: Uri.parse(json['url'] as String),
    publishedAt: DateTime.parse(json['publishedAt'] as String),
  );
}
