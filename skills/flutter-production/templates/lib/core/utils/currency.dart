import 'package:intl/intl.dart';

final NumberFormat _inr = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);
final NumberFormat _inrPaise = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

/// `₹1,23,456`; pass [paise] true for `₹1,23,456.50`. Never string-concat `'₹' + x`.
String formatInr(num amount, {bool paise = false}) =>
    (paise ? _inrPaise : _inr).format(amount);
