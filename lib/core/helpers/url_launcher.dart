import 'package:url_launcher/url_launcher.dart';

void urlLauncher(String url) async {
  final Uri uri = Uri.parse(url); // استبدل الرابط بالرابط الخاص بكل زرار
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'Could not launch $uri';
  }
}
