import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:campusmart_mobile/core/config/app_config.dart';

/// Metadata describing an available app update, assembled from the latest
/// GitHub Release for the configured repository.
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
}

/// Fetches update metadata from the public GitHub Releases API.
///
/// The latest release's `body` carries the authoritative Android build number
/// in a simple machine-readable line: `Build: N`. This numeric build number is
/// compared against the installed versionCode, so human-readable version
/// strings are never compared lexicographically.
class UpdateRepository {
  static const String _apiHost = 'api.github.com';
  static const String _owner = AppConfig.githubOwner;
  static const String _repo = AppConfig.githubRepo;

  /// The regex used to extract the authoritative build number from the release
  /// body. Number is captured as a non-negative integer.
  static final RegExp _buildRegex = RegExp(r'Build\s*:\s*(\d+)');

  /// Returns null when the fetched release is not newer than the installed one.
  Future<AppUpdateInfo?> checkForUpdate() async {
    final info = await _fetchLatestRelease();
    if (info == null) return null;

    final installed = await PackageInfo.fromPlatform();
    final installedBuild = int.tryParse(installed.buildNumber) ?? 0;

    // Only surface an update when the release reports a strictly higher build
    // number than the one installed on this device.
    if (info.latestBuild <= installedBuild) return null;

    return info;
  }

  /// Fetches and parses the latest release. Returns null (never throws) for any
  /// failure: unreachable API, non-200 response, malformed JSON, missing APK
  /// asset, or an unparseable build number.
  Future<AppUpdateInfo?> _fetchLatestRelease() async {
    final uri = Uri.https(_apiHost, '/repos/$_owner/$_repo/releases/latest');

    http.Response response;
    try {
      response = await http
          .get(uri, headers: const {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Network error, DNS failure, timeout - fail safely.
      return null;
    }

    if (response.statusCode != 200) {
      return null;
    }

    Map<String, dynamic> release;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      release = decoded;
    } catch (_) {
      return null;
    }

    final tagName = (release['tag_name'] as String?)?.trim() ?? '';
    final body = (release['body'] as String?) ?? '';

    // Extract the authoritative build number from the release body.
    final buildMatch = _buildRegex.firstMatch(body);
    final latestBuild = buildMatch == null
        ? null
        : int.tryParse(buildMatch.group(1)!);
    if (latestBuild == null) {
      // No parseable "Build: N" line - fail safely, show no update.
      return null;
    }

    // Locate the APK release asset.
    final assets = release['assets'];
    String apkUrl = '';
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;
        final name = (asset['name'] as String?) ?? '';
        if (!name.toLowerCase().endsWith('.apk')) continue;
        final url = (asset['browser_download_url'] as String?)?.trim() ?? '';
        if (url.isNotEmpty) {
          apkUrl = url;
          break;
        }
      }
    }
    if (apkUrl.isEmpty) {
      // No APK release asset - fail safely, show no update.
      return null;
    }

    // The APK URL must belong to GitHub's release download infrastructure.
    if (!_isApprovedApkUrl(apkUrl)) {
      return null;
    }

    final releaseNotes = _cleanReleaseNotes(body);

    if (tagName.isEmpty) return null;

    return AppUpdateInfo(
      latestVersion: tagName,
      latestBuild: latestBuild,
      apkUrl: apkUrl,
      releaseNotes: releaseNotes,
    );
  }

  /// Strips the machine-readable `Build: N` lines out of the release body so
  /// only the human-readable release notes are shown in the dialog.
  String _cleanReleaseNotes(String body) {
    final lines = body
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !_buildRegex.hasMatch(l))
        .toList();
    // Drop a leading "Release notes:" label line if present.
    if (lines.isNotEmpty &&
        lines.first.toLowerCase().startsWith('release notes')) {
      lines.removeAt(0);
    }
    return lines.join('\n');
  }

  /// Only HTTPS GitHub release download URLs are accepted:
  ///   - https://github.com/OWNER/REPO/releases/download/... (browser_download_url)
  ///   - https://objects.githubusercontent.com/... (the official CDN that the
  ///     download redirects to)
  bool _isApprovedApkUrl(String apkUrl) {
    final uri = Uri.tryParse(apkUrl);
    if (uri == null || uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    return host == 'github.com' ||
        host.endsWith('.github.com') ||
        host == 'objects.githubusercontent.com';
  }
}
