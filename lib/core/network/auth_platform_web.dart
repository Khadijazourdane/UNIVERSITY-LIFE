import 'dart:js_interop';

import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

@JS('localStorage')
external _BrowserStorage get _storage;

extension type _BrowserStorage(JSObject _) implements JSObject {
  external String? getItem(String key);
  external void setItem(String key, String value);
  external void removeItem(String key);
}

void configureAuthClient(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
}

// Only an opt-out flag is stored here. The browser owns the HttpOnly cookie.
String _key(String origin) => 'university-life.auth.closed:$origin';

bool isCookieSessionClosed(String origin) =>
    _storage.getItem(_key(origin)) == '1';

void setCookieSessionClosed(String origin, bool closed) {
  final key = _key(origin);
  if (closed) {
    _storage.setItem(key, '1');
  } else {
    _storage.removeItem(key);
  }
}
