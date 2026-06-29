import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
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