import 'package:intl/intl.dart';
import '../../config/app_config.dart';

class DateTimeHelper {
  static String getCurrentUTC() {
    final now = DateTime.now().toUtc();
    return DateFormat(AppConfig.dateTimeFormat).format(now);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConfig.dateTimeFormat).format(dateTime.toUtc());
  }

  static DateTime? parseDateTime(String? dateTime) {
    if (dateTime == null) return null;
    try {
      return DateFormat(AppConfig.dateTimeFormat).parse(dateTime, true);
    } catch (e) {
      return null;
    }
  }

  static String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}