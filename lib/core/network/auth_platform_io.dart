import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

void configureAuthClient(Dio dio) {
  const localCertificate = String.fromEnvironment('AUTH_DEBUG_CA_BASE64');
  if (!kDebugMode || localCertificate.isEmpty) return;

  final context = SecurityContext(withTrustedRoots: true)
    ..setTrustedCertificatesBytes(base64Decode(localCertificate));
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () => HttpClient(context: context),
  );
}

bool isCookieSessionClosed(String origin) => false;

void setCookieSessionClosed(String origin, bool closed) {}
