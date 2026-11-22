/// Compile-time configuration supplied by the build environment.
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static Uri get apiBaseUri {
    final configuredUrl = apiBaseUrl.trim();
    if (configuredUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL must be provided before creating the HTTP client.',
      );
    }

    final uri = Uri.tryParse(configuredUrl);
    if (uri == null ||
        !uri.isAbsolute ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw StateError('API_BASE_URL must be an absolute HTTP(S) URL.');
    }

    return uri;
  }
}
