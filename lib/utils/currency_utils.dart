class CurrencyUtils {
  static const List<String> supportedCodes = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'INR',
    'VND',
    'IDR',
    'SGD',
    'MYR',
    'AUD',
    'CAD',
  ];

  static const Map<String, String> _symbols = {
    'USD': r'$',
    'EUR': 'EUR ',
    'GBP': 'GBP ',
    'JPY': 'JPY ',
    'INR': 'INR ',
    'VND': 'VND ',
    'IDR': 'IDR ',
    'SGD': 'SGD ',
    'MYR': 'MYR ',
    'AUD': 'AUD ',
    'CAD': 'CAD ',
  };

  static String symbol(String code) => _symbols[code] ?? '$code ';

  static String formatAmount(double amount, String code) {
    return '${symbol(code)}${amount.toStringAsFixed(2)}';
  }
}
