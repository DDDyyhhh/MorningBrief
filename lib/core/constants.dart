class AppConstants {
  const AppConstants._();

  static const weatherApiKey = 'weather_api_key';
  static const stockApiKey = 'stock_api_key';
  static const cityName = 'city_name';
  static const stockSymbols = 'stock_symbols';
  static const moduleConfigs = 'module_configs';

  static const defaultCity = '上海';
  static const defaultStockSymbols = ['600036.SHH', '000001.SHZ'];

  static const cacheWeather = 'cache_weather';
  static const cacheNews = 'cache_news';
  static const cacheStocks = 'cache_stocks';
  static const cacheTechNews = 'cache_tech_news';

  static final generalNewsFeeds = <Uri>[
    Uri.parse('https://www.thepaper.cn/rss_newsDetail.jsp'),
  ];

  static final techNewsFeeds = <Uri>[
    Uri.parse('https://www.jiqizhixin.com/rss'),
    Uri.parse('https://www.qbitai.com/feed'),
  ];
}
