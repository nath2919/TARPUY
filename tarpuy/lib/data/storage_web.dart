import 'package:web/web.dart' as web;
void removeLocal(String key) => web.window.localStorage.removeItem('tarpuy.$key');

String? readLocal(String key) => web.window.localStorage.getItem('tarpuy.$key');
void writeLocal(String key, String value) =>
    web.window.localStorage.setItem('tarpuy.$key', value);
