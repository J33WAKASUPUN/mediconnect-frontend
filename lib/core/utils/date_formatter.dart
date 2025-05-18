import 'package:intl/intl.dart';

class DateFormatter {
  static String formatMessageTime(DateTime date) {
    // Ensure we're using local time
    final localDate = date.toLocal();
    return DateFormat('HH:mm').format(localDate);
  }
  
  static String formatMessageDate(DateTime date) {
    // Ensure we're using local time
    final localDate = date.toLocal();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(localDate.year, localDate.month, localDate.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('EEEE').format(localDate); // Day of week
    } else {
      return DateFormat('MMM d, yyyy').format(localDate);
    }
  }
  
  static String formatConversationTime(DateTime date) {
    // Ensure we're using local time
    final localDate = date.toLocal();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(localDate.year, localDate.month, localDate.day);
    
    if (messageDate == today) {
      return DateFormat('HH:mm').format(localDate);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('E').format(localDate); // Abbreviated day of week
    } else {
      return DateFormat('MMM d').format(localDate);
    }
  }
}