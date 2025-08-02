// ignore_for_file: depend_on_referenced_packages

import 'package:intl/intl.dart';

String showData(dynamic date) {
  DateTime parsedDate = DateTime.parse(date.toString());

  // تنسيق التاريخ بالشكل المطلوب
  String formattedDate = DateFormat('yyyy-MM-dd', 'en').format(parsedDate);
  //  hh:mm a
  return formattedDate;
}

String showDataAndTime(DateTime date) {
  DateTime parsedDate = DateTime.parse(date.toString());

  // تنسيق التاريخ بالشكل المطلوب
  String formattedDate =
      DateFormat('yyyy-MM-dd' ' ' 'hh:mm a', 'en').format(parsedDate);
  //  hh:mm a
  return formattedDate;
}
