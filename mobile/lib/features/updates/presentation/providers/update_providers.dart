import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusmart_mobile/main.dart' show navigatorKey;
import 'package:campusmart_mobile/features/updates/data/update_repository.dart';
import 'package:campusmart_mobile/features/updates/presentation/widgets/update_dialog.dart';

final updateRepositoryProvider = Provider<UpdateRepository>(
  (ref) => UpdateRepository(),
);

/// One-shot check for an available update. On start, the app invokes
/// [checkForUpdate] to prompt the user only when a newer build is published.
class UpdateController {
  final UpdateRepository _repository;
  bool _checked = false;

  UpdateController(this._repository);

  /// Whether the initial update check has already run this session, so we only
  /// prompt the user once per launch.
  bool get hasChecked => _checked;

  /// Fetches update metadata and, if a newer build is available, shows the
  /// in-app update dialog on the global navigator once one is ready.
  Future<void> checkForUpdate() async {
    if (_checked) return;
    _checked = true;

    try {
      final update = await _repository.checkForUpdate();
      if (update == null) return;

      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      await showUpdateDialog(ctx, update);
    } catch (e) {
      // Never block the user over a failed update check - just skip silently
      // this session.
      debugPrint('[Update] Check skipped: $e');
    }
  }
}

final updateControllerProvider = Provider<UpdateController>((ref) {
  return UpdateController(ref.read(updateRepositoryProvider));
});
