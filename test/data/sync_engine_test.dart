import 'package:flutter_test/flutter_test.dart';

import 'package:ai_travel_ledger/data/sync/sync_engine.dart';

/// 测试 SyncEngine 的边界行为
///
/// 重点：不依赖 Supabase,只测离线逻辑
void main() {
  group('SyncResult', () {
    test('skipped - 默认 false', () {
      final r = SyncResult();
      expect(r.skipped, false);
      expect(r.pushed, 0);
      expect(r.pulled, 0);
      expect(r.hasError, false);
    });

    test('toString - skipped', () {
      final r = SyncResult(skipped: true, reason: 'not signed in');
      expect(r.toString(), contains('SKIP'));
      expect(r.toString(), contains('not signed in'));
    });

    test('toString - error', () {
      final r = SyncResult(error: 'network down');
      expect(r.toString(), contains('ERROR'));
    });

    test('toString - OK', () {
      final r = SyncResult()
        ..pushed = 5
        ..pulled = 3
        ..completedAt = DateTime.now();
      expect(r.toString(), contains('OK'));
      expect(r.toString(), contains('pushed=5'));
      expect(r.toString(), contains('pulled=3'));
    });
  });

  group('SyncState enum', () {
    test('包含三个状态', () {
      expect(SyncState.values, contains(SyncState.idle));
      expect(SyncState.values, contains(SyncState.syncing));
      expect(SyncState.values, contains(SyncState.error));
      expect(SyncState.values.length, 3);
    });
  });
}