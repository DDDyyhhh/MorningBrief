class StockItem {
  StockItem({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.updatedAt,
  });

  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final DateTime updatedAt;

  bool get isUp => change >= 0;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'price': price,
    'change': change,
    'changePercent': changePercent,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
    symbol: json['symbol'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    change: (json['change'] as num).toDouble(),
    changePercent: (json['changePercent'] as num).toDouble(),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
