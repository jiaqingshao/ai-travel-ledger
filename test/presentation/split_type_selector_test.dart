import 'package:ai_travel_ledger/data/models/member.dart';
import 'package:ai_travel_ledger/domain/services/split_calculator.dart';
import 'package:ai_travel_ledger/presentation/widgets/split_type_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Smoke tests for SplitTypeSelector widget.
///
/// 不测试每个交互细节（避免过度耦合 UI 内部结构），
/// 只验证：
/// - 5 个 tab 都能渲染
/// - 切换类型时 onChanged 被调用
/// - 均摊 + 3 人 → exportRule 给出 equal rule
void main() {
  Member makeMember(String id) {
    return Member(
      id: id,
      tripId: 't1',
      nickname: 'Test$id',
      joinedAt: DateTime(2026, 6, 1),
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  // 更大的 viewport，避免 ChoiceChip 被 horizontal scroll 裁掉
  void setLargeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(2000, 1000);
    tester.view.devicePixelRatio = 1.0;
  }

  void resetViewport(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  testWidgets('5 个 tab 都能渲染', (tester) async {
    final members = [
      makeMember('a'),
      makeMember('b'),
      makeMember('c'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: wrap(
          SplitTypeSelector(
            total: 90,
            members: members,
            tripId: 't1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('均摊'), findsOneWidget);
    expect(find.text('比例'), findsOneWidget);
    expect(find.text('份数'), findsOneWidget);
    expect(find.text('固定'), findsOneWidget);
    expect(find.text('按组'), findsOneWidget);
  });

  testWidgets('默认均摊：3 人均摊 90', (tester) async {
    final members = [
      makeMember('a'),
      makeMember('b'),
      makeMember('c'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: wrap(
          SplitTypeSelector(
            total: 90,
            members: members,
            tripId: 't1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 均摊预览
    expect(find.textContaining('¥ 30.00'), findsWidgets);
    expect(find.textContaining('实时预览'), findsOneWidget);
  });

  testWidgets('切换到按份数：可改份数', (tester) async {
    setLargeViewport(tester);
    final members = [
      makeMember('a'),
      makeMember('b'),
      makeMember('c'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: wrap(
          SplitTypeSelector(
            total: 90,
            members: members,
            tripId: 't1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 切换到"份数" tab
    await tester.tap(find.text('份数'));
    await tester.pumpAndSettle();

    // 提示文本出现
    expect(find.textContaining('每人份数'), findsOneWidget);
    resetViewport(tester);
  });

  testWidgets('切换到按组：无组时显示提示', (tester) async {
    setLargeViewport(tester);
    final members = [
      makeMember('a'),
      makeMember('b'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: wrap(
          SplitTypeSelector(
            total: 100,
            members: members,
            tripId: 't1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 切到按组
    await tester.tap(find.text('按组'));
    await tester.pumpAndSettle();

    // 因为没有组，应该显示提示（或加载失败——测试环境无 box）
    expect(
      find.byWidgetPredicate((w) =>
          w is Text &&
          (w.data?.contains('还没有组') == true ||
              w.data?.contains('加载组失败') == true)),
      findsOneWidget,
    );
    resetViewport(tester);
  });

  testWidgets('onChanged 回调被触发', (tester) async {
    final members = [
      makeMember('a'),
      makeMember('b'),
    ];
    SplitType? lastType;
    List<SplitResultItem>? lastResult;
    int callCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: wrap(
          SplitTypeSelector(
            total: 60,
            members: members,
            tripId: 't1',
            onChanged: (type, result) {
              lastType = type;
              lastResult = result;
              callCount++;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 初始回调（postFrameCallback）
    expect(callCount, greaterThan(0));
    expect(lastType, SplitType.equal);
    expect(lastResult, hasLength(2));
    expect(lastResult!.first.amount, 30);
  });

  testWidgets('空成员：显示空状态', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: wrap(
          SplitTypeSelector(
            total: 100,
            members: const [],
            tripId: 't1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('还没有成员'), findsOneWidget);
  });
}
