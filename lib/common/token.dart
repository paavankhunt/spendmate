import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

Future<void> removeToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
}
