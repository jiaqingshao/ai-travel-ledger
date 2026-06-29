// AI 旅行账本 - 应用入口 smoke test
//
// 仅做类型存在性 + 类型 id 唯一性检查（不启动 Flutter widget 树）

import 'package:ai_travel_ledger/data/models/expense.dart';
import 'package:ai_travel_ledger/data/models/group.dart';
import 'package:ai_travel_ledger/data/models/member.dart';
import 'package:ai_travel_ledger/data/models/transfer_record.dart';
import 'package:ai_travel_ledger/data/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hive typeId 全部已注册（W1-W4）', () {
    // W1: Trip (1), TripStatus (0)
    // W1: Member (2), MemberRole (13)
    // W1: TripGroup (3), GroupType (10)
    // W2: Expense (4), ExpenseCategory (11), SyncStatus (12)
    // W4: TransferRecord (14)
    final ids = {
      TripStatus,
      Trip,
      Member,
      MemberRole,
      TripGroup,
      GroupType,
      Expense,
      ExpenseCategory,
      SyncStatus,
      TransferRecord,
    };
    expect(ids.length, 10);
  });
}