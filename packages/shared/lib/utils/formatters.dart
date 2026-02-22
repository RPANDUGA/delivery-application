import 'package:intl/intl.dart';

class Formatters {
  static final _currency = NumberFormat.currency(symbol: '\$');

  static String money(num value) => _currency.format(value);
}
