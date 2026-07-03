import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/supabase/supabase_service.dart';
import 'data/models/expense.dart';
import 'data/models/group.dart';
import 'data/models/member.dart';
import 'data/models/transfer_record.dart';
import 'data/models/trip.dart';
import 'data/seed_data.dart';
import 'presentation/providers/core_providers.dart';
import 'presentation/screens/group_settlement_screen.dart';
import 'presentation/screens/settlement_screen.dart';
import 'presentation/screens/trip_detail_screen.dart';
import 'presentation/screens/trip_list_screen.dart';

/// AI 旅行账本 - 入口
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Supabase（如已配置；未配置则静默跳过,APP 以纯本地模式运行）
  await SupabaseService.instance.init();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TripStatusAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TripAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MemberAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(TripGroupAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ExpenseAdapter());
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(GroupTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(ExpenseCategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(SyncStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(13)) {
    Hive.registerAdapter(MemberRoleAdapter());
  }
  if (!Hive.isAdapterRegistered(14)) {
    Hive.registerAdapter(TransferRecordAdapter());
  }

  final tripsBox = await Hive.openBox<Trip>('trips');
  final membersBox = await Hive.openBox<Member>('members');
  final groupsBox = await Hive.openBox<TripGroup>('groups');
  final expensesBox = await Hive.openBox<Expense>('expenses');
  final transferRecordsBox = await Hive.openBox<TransferRecord>('transfer_records');

  const seedMode = String.fromEnvironment('SEED', defaultValue: '');
  if (seedMode == 'demo') {
    DemoSeed.apply(HiveBoxes(
      trips: tripsBox,
      members: membersBox,
      groups: groupsBox,
      expenses: expensesBox,
      transferRecords: transferRecordsBox,
    ));
  }

  final boxes = HiveBoxes(
    trips: tripsBox,
    members: membersBox,
    groups: groupsBox,
    expenses: expensesBox,
    transferRecords: transferRecordsBox,
  );

  runApp(
    ProviderScope(
      overrides: [
        hiveBoxesProvider.overrideWithValue(boxes),
      ],
      child: AITravelLedgerApp(boxes: boxes),
    ),
  );
}

class AITravelLedgerApp extends StatelessWidget {
  const AITravelLedgerApp({super.key, required this.boxes});
  final HiveBoxes boxes;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 旅行账本',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF2E7DD7), // 旅行蓝 (UI 设计稿 v0.1 §1)
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFD8E8FB),
          onPrimaryContainer: Color(0xFF001D36),
          secondary: Color(0xFFF59E0B), // 暖阳橙
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFFFE0B2),
          onSecondaryContainer: Color(0xFF291800),
          tertiary: Color(0xFF10B981), // 草地绿 (成功)
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFC9F2E0),
          onTertiaryContainer: Color(0xFF002117),
          error: Color(0xFFEF4444), // 落日红
          onError: Colors.white,
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF410002),
          surface: Color(0xFFFDFCFF),
          onSurface: Color(0xFF1A1C1E),
          surfaceContainerHighest: Color(0xFFEEF1F4),
          outline: Color(0xFF73777F),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF89B8F0),
          onPrimary: Color(0xFF003258),
          primaryContainer: Color(0xFF154878),
          onPrimaryContainer: Color(0xFFD8E8FB),
          secondary: Color(0xFFFFB95C),
          onSecondary: Color(0xFF482900),
          secondaryContainer: Color(0xFF683C00),
          onSecondaryContainer: Color(0xFFFFE0B2),
          tertiary: Color(0xFF8DD6BB),
          onTertiary: Color(0xFF00382C),
          tertiaryContainer: Color(0xFF005142),
          onTertiaryContainer: Color(0xFFC9F2E0),
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
          errorContainer: Color(0xFF93000A),
          onErrorContainer: Color(0xFFFFDAD6),
          surface: Color(0xFF1A1C1E),
          onSurface: Color(0xFFE2E2E5),
          surfaceContainerHighest: Color(0xFF2A2D31),
          outline: Color(0xFF8D9199),
        ),
      ),
      // 用 ?screen=trip_list|trip_detail|settlement|group_settlement 跳转
      home: const _ScreenRouter(),
    );
  }
}

/// 路由：根据 URL query 决定首页
class _ScreenRouter extends StatefulWidget {
  const _ScreenRouter();
  @override
  State<_ScreenRouter> createState() => _ScreenRouterState();
}

class _ScreenRouterState extends State<_ScreenRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final params = Uri.base.queryParameters;
      final screen = params['screen'] ?? 'trip_list';
      _navigate(screen);
    });
  }

  void _navigate(String screen) async {
    final ctx = context;
    if (!ctx.mounted) return;
    final tripId = boxesForRouter;
    switch (screen) {
      case 'trip_detail':
        if (tripId != null) {
          Navigator.of(ctx).push(MaterialPageRoute(
            builder: (_) => TripDetailScreen(tripId: tripId),
          ));
        }
        break;
      case 'settlement':
        if (tripId != null) {
          Navigator.of(ctx).push(MaterialPageRoute(
            builder: (_) => SettlementScreen(tripId: tripId),
          ));
        }
        break;
      case 'group_settlement':
        if (tripId != null) {
          Navigator.of(ctx).push(MaterialPageRoute(
            builder: (_) => GroupSettlementScreen(tripId: tripId),
          ));
        }
        break;
      case 'trip_list':
      default:
        // 默认就在 TripListScreen
        break;
    }
  }

  String? get boxesForRouter {
    // 从 URL 取 tripId，否则用 seed 的固定 ID
    final t = Uri.base.queryParameters['tripId'];
    if (t != null && t.isNotEmpty) return t;
    return 'trip-demo-001';
  }

  @override
  Widget build(BuildContext context) {
    return const TripListScreen();
  }
}