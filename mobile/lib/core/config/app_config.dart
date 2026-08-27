class AppConfig {
  static const String collegeId = 'akgec';
  static const String collegeEmailDomain = 'akgec.ac.in';
  static const String collegeName = 'Ajay Kumar Garg Engineering College';

  /// GitHub repository that publishes CampusMart releases.
  ///
  /// The update source is the public GitHub Releases API for this repository:
  ///   https://api.github.com/repos/{githubOwner}/{githubRepo}/releases/latest
  ///
  /// For production users to reach the update metadata and APK, this repository
  /// MUST be PUBLIC (or exposed via a public proxy). A private repository
  /// returns 404 for the latest-release API and asset downloads without
  /// authentication, so a key/token would be required - which is intentionally
  /// NOT embedded in the app.
  static const String githubOwner = 'naman01g';
  static const String githubRepo = 'CampusMart';
}
