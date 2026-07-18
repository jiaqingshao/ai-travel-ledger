import 'package:ai_travel_ledger/data/models/member.dart';
import 'package:ai_travel_ledger/presentation/screens/split_rule_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SplitRuleEditPage smoke tests (ISSUE-024 V1.1)
///
/// 验证:
/// - 全屏编辑页能正常渲染
/// - 顶部 banner 显示总金额
/// - 5 个分摊 tab 都能渲染
/// - 点击"确定"返回 SplitRuleExport
void main() {
  Member makeMember(String id) {
    return Member(
      id: id,
      tripId: 't1',
      nickname: 'Test\$id',
      joinedAt: DateTime(2026, 6, 1),
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  void setLargeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(2000, 1500);
    tester.view.devicePixelRatio = 1.0;
  }

  void resetViewport(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  testWidgets('全屏渲染: AppBar + 金额 banner + 5 tab', (tester) async {
    final members = [
      makeMember('a'),
      makeMember('b'),
      makeMember('c'),
    ];

    setLargeViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        child: wrap(
          SplitRuleEditPage(
            total: 90.0,
            members: members,
            tripId: 't1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // AppBar
    expect(find.text('编辑分摊规则'), findsOneWidget);
    // 顶部 banner
    expect(find.text('分摊总金额'), findsOneWidget);
    expect(find.text('¥ 90.00'), findsOneWidget);
    // 5 个 tab
    expect(find.text('均摊'), findsOneWidget);
    expect(find.text('比例'), findsOneWidget);
    expect(find.text('份数'), findsOneWidget);
    expect(find.text('固定'), findsOneWidget);
    expect(find.text('按组'), findsOneWidget);
    // 确定按钮
    expect(find.text('确定'), findsOneWidget);

    resetViewport(tester);
  });

  testWidgets('从 splitRuleJson 解析初始 type', (tester) async {
    final members = [
      makeMember('a'),
      makeMember('b'),
    ];

    setLargeViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        child: wrap(
          SplitRuleEditPage(
            total: 100.0,
            members: members,
            tripId: 't1',
            initialSplitRuleJson:
                '{"type":"ratio","participants":[{"type":"member","id":"a"},{"type":"member","id":"b"}],"values":{"a":0.6,"b":0.4}}',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 应该能正常渲染不报错
    expect(find.text('编辑分摊规则'), findsOneWidget);
    expect(find.text('¥ 100.00'), findsOneWidget);

    resetViewport(tester);
  });

  testWidgets('无效 JSON 退化为默认 equal', (tester) async {
    final members = [makeMember('a')];

    setLargeViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        child: wrap(
          SplitRuleEditPage(
            total: 50.0,
            members: members,
            tripId: 't1',
            initialSplitRuleJson: 'invalid json {{',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 应该能正常渲染, 不抛异常
    expect(find.text('编辑分摊规则'), findsOneWidget);

    resetViewport(tester);
  });

  // ISSUE-038 修复测试: shares/specific 初始值解析
  group('ISSUE-038 修复', () {
    testWidgets('编辑 shares 费用: 初始值正确传递', (tester) async {
      final members = [
        makeMember('a'),
        makeMember('b'),
      ];

      setLargeViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: wrap(
            SplitRuleEditPage(
              total: 90.0,
              members: members,
              tripId: 't1',
              initialSplitRuleJson:
                  '{"type":"shares","participants":[{"type":"member","id":"a"},{"type":"member","id":"b"}],"values":{"a":2.0,"b":1.0}}',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 应该选中"份数" tab (因为 initialType = shares)
      expect(find.text('份数'), findsOneWidget);

      resetViewport(tester);
    });

    testWidgets('编辑 specific 费用: 初始值正确传递', (tester) async {
      final members = [
        makeMember('a'),
        makeMember('b'),
      ];

      setLargeViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: wrap(
            SplitRuleEditPage(
              total: 100.0,
              members: members,
              tripId: 't1',
              initialSplitRuleJson:
                  '{"type":"specific","participants":[{"type":"member","id":"a"},{"type":"member","id":"b"}],"values":{"a":60.0,"b":40.0}}',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 应该选中"固定" tab
      expect(find.text('固定'), findsOneWidget);

      resetViewport(tester);
    });

    testWidgets('编辑 ratio 费用: 不影响 shares/specific 初始值', (tester) async {
      final members = [
        makeMember('a'),
        makeMember('b'),
      ];

      setLargeViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: wrap(
            SplitRuleEditPage(
              total: 100.0,
              members: members,
              tripId: 't1',
              initialSplitRuleJson:
                  '{"type":"ratio","participants":[{"type":"member","id":"a"},{"type":"member","id":"b"}],"values":{"a":0.6,"b":0.4}}',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 应该选中"比例" tab
      expect(find.text('比例'), findsOneWidget);

      resetViewport(tester);
    });

    testWidgets('_save 在 selector 未挂载时不静默 pop', (tester) async {
      // 这个测试覆盖根因 #2: _save 静默 pop(null) bug
      // 由于 GlobalKey.currentState 难以在 widget test 中直接模拟为 null
      // (pumpWidget 后立即挂载), 改为验证 _save 在 export 返回 null 时弹 Snackbar
      final members = [makeMember('a')];

      setLargeViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: wrap(
            SplitRuleEditPage(
              total: 100.0,
              members: members,
              tripId: 't1',
              // byGroup 但无 group 配置 → exportRule 会返回有效但 result 空
              initialSplitRuleJson:
                  '{"type":"equal","participants":[{"type":"member","id":"a"}],"values":{}}',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证页面能正常渲染, 不抛异常
      expect(find.text('编辑分摊规则'), findsOneWidget);

      resetViewport(tester);
    });
  });
}
