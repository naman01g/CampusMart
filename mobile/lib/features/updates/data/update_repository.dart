import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:campusmart_mobile/core/config/app_config.dart';

/// Metadata describing an available app update, parsed from the official
/// endpoint's JSON response.
class AppUpdateInfo {
  final String latestVersion;
  final int latestBuild;
  final String apkUrl;
  final String releaseNotes;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuild,
    required this.apkUrl,
    required this.releaseNotes,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: (json['latestVersion'] as String?)?.trim() ?? '',
      latestBuild: (json['latestBuild'] as num?)?.toInt() ?? 0,
      apkUrl: (json['apkUrl'] as String?)?.trim() ?? '',
      releaseNotes: (json['releaseNotes'] as String?)?.trim() ?? '',
    );
  }
}

/// Fetches and validates update metadata from the official endpoint.
class UpdateRepository {
  static const String _endpoint = AppConfig.updateEndpoint;
  static const String _allowedHost = AppConfig.updateAllowedHost;

  /// Returns null when the fetched version is not newer than the installed one.
  Future<AppUpdateInfo?> checkForUpdate() async {
    final info = await _fetch();
    if (info == null) return null;

    final installed = await PackageInfo.fromPlatform();
    final installedBuild = int.tryParse(installed.buildNumber) ?? 0;

    // Only surface an update when the server reports a strictly higher build
    // number than the one installed on this device.
    if (info.latestBuild <= installedBuild) return null;

    _validateApkUrl(info.apkUrl);
    return info;
  }

  Future<AppUpdateInfo?> _fetch() async {
    final uri = Uri.parse(_endpoint);

    // Only ever fetch from the configured official HTTPS endpoint.
    if (!_isSecureAndAllowed(uri)) {
      throw const FormatException('Refusing non-official update endpoint.');
    }

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return AppUpdateInfo.fromJson(decoded);
  }

  /// The APK download link must be HTTPS and hosted on the allowed host so a
  /// compromised or malicious URL can never be surfaced to the user.
  void _validateApkUrl(String apkUrl) {
    final uri = Uri.tryParse(apkUrl);
    if (uri == null || !_isSecureAndAllowed(uri)) {
      throw const FormatException('Refusing untrusted APK download URL.');
    }
  }

  bool _isSecureAndAllowed(Uri uri) {
    if (uri.scheme != 'https') return false;
    return uri.host == _allowedHost || uri.host.endsWith('.$_allowedHost');
  }
}
