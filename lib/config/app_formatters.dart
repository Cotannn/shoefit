import 'package:intl/intl.dart';
import 'package:shoefit/config/app_environment.dart';

class AppFormatters {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_MY',
    symbol: AppEnvironment.currencySymbol,
    decimalDigits: 0,
  );

  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

  static String currency(double amount) => _currency.format(amount);
  static String date(DateTime date) => _date.format(date);
  static String dateTime(DateTime dateTime) => _dateTime.format(dateTime);
}
