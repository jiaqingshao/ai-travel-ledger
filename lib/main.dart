import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/models/expense.dart';
import 'data/models/group.dart';
import 'data/models/member.dart';
import 'data/models/trip.dart';
import 'presentation/providers/core_providers.dart';
import 'presentation/screens/trip_list_screen.dart';

/// AI 旅行账本 - 入口
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化 Hive
  await Hive.initFlutter();

  // 2. 注册 TypeAdapter
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

  // 3. 打开 Boxes
  final tripsBox = await Hive.openBox<Trip>('trips');
  final membersBox = await Hive.openBox<Member>('members');
  final groupsBox = await Hive.openBox<TripGroup>('groups');
  final expensesBox = await Hive.openBox<Expense>('expenses');

  runApp(
    ProviderScope(
      overrides: [
        hiveBoxesProvider.overrideWithValue(
          HiveBoxes(
            trips: tripsBox,
            members: membersBox,
            groups: groupsBox,
            expenses: expensesBox,
          ),
        ),
      ],
      child: const AITravelLedgerApp(),
    ),
  );
}

class AITravelLedgerApp extends StatelessWidget {
  const AITravelLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 旅行账本',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // 旅行绿
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
      home: const TripListScreen(),
    );
  }
}