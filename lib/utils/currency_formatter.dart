import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: 'сом',
      decimalDigits: 0, // Commonly used in KGS for whole numbers
    );
    // Replace non-breaking space (intl uses thin space or similar by default in some locales)
    return formatter.format(amount).replaceAll(' ', ' '); 
  }
}
