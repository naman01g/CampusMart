class AppConfig {
  static const String collegeId = 'akgec';
  static const String collegeEmailDomain = 'akgec.ac.in';
  static const String collegeName = 'Ajay Kumar Garg Engineering College';

  /// Official endpoint that publishes app-update metadata (JSON).
  ///
  /// The response must be a JSON object of the form:
  /// {
  ///   "latestVersion": "1.1.0",   // display version
  ///   "latestBuild": 2,           // versionCode / build number
  ///   "apkUrl": "https://.../app.apk",
  ///   "releaseNotes": "What changed in this release"
  /// }
  ///
  /// Only this configured official endpoint is trusted. The update client
  /// refuses any URL that is not HTTPS or is not under this host.
  static const String updateEndpoint = 'https://campusmart.app/versions.json';

  /// Host allowed to serve update metadata and the APK itself.
  static const String updateAllowedHost = 'campusmart.app';
}
