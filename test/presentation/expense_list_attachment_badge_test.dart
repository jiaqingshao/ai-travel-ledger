// AI 旅行账本 - ExpenseList 附件徽章测试 (ISSUE-026 step 3)
//
// 覆盖:
// - 附件数 = 0: 不显示附件徽章 (只显示金额)
// - 附件数 = 1: 显示 📎1 徽章
// - 附件数 = 3: 显示 📎3 徽章 (多附件)
// - 金额数字格式化正确 (保留 2 位小数)
//
// 注: 因为 _ExpenseTrailing 是 private class, 通过构造 _ExpenseTile 间接测;
//     _ExpenseTile 又依赖完整的 _ExpenseListScreen, 这里只对 _ExpenseTrailing 直接构造

import 'package:ai_travel_ledger/presentation/screens/expense_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('ExpenseTrailing (附件徽章)', () {
    testWidgets('附件数 = 0: 不显示徽章, 只显示金额', (tester) async {
      final df = NumberFormat('#,##0.00');
      await tester.pumpWidget(_wrap(
        ExpenseTrailing(amount: 100, attachmentCount: 0, df: df),
      ));
      await tester.pump();
      expect(find.text('¥ 100.00'), findsOneWidget);
      // 没有附件时, attach_file 图标不应存在
      expect(find.byIcon(Icons.attach_file), findsNothing);
    });

    testWidgets('附件数 = 1: 显示 📎1 徽章', (tester) async {
      final df = NumberFormat('#,##0.00');
      await tester.pumpWidget(_wrap(
        ExpenseTrailing(amount: 100, attachmentCount: 1, df: df),
      ));
      await tester.pump();
      expect(find.text('¥ 100.00'), findsOneWidget);
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('附件数 = 3: 显示 📎3 徽章', (tester) async {
      final df = NumberFormat('#,##0.00');
      await tester.pumpWidget(_wrap(
        ExpenseTrailing(amount: 1500.5, attachmentCount: 3, df: df),
      ));
      await tester.pump();
      expect(find.text('¥ 1,500.50'), findsOneWidget);
      expect(find.byIcon(Icons.attach_file), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('金额数字 0 显示 ¥ 0.00', (tester) async {
      final df = NumberFormat('#,##0.00');
      await tester.pumpWidget(_wrap(
        ExpenseTrailing(amount: 0, attachmentCount: 0, df: df),
      ));
      await tester.pump();
      expect(find.text('¥ 0.00'), findsOneWidget);
    });
  });
}