import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/trip.dart';
import '../../data/seed_data.dart';
import '../providers/core_providers.dart';
import '../providers/trip_provider.dart';
import 'ai_settings_screen.dart';
import 'archived_trips_screen.dart';
import 'trip_create_screen.dart';
import 'trip_detail_screen.dart';

/// 旅程列表（首页）
///
/// 顶部 Tab：活跃 / 归档
/// 空状态引导用户创建
/// 右上角：归档列表 + AI 设置
class TripListScreen extends ConsumerStatefulWidget {
  const TripListScreen({super.key});

  @override
  ConsumerState<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends ConsumerState<TripListScreen> {
  @override
  Widget build(BuildContext context) {
    final activeTripsAsync = ref.watch(activeTripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的旅程'),
        actions: [
          IconButton(
            tooltip: '加载演示数据',
            icon: const Icon(Icons.auto_awesome),
            onPressed: _loadDemoData,
          ),
          IconButton(
            tooltip: '归档列表',
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ArchivedTripsScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'AI 设置',
            icon: const Icon(Icons.psychology_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AISettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: activeTripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: '加载旅程失败：$e',
          onRetry: () => ref.invalidate(activeTripsProvider),
        ),
        data: (trips) {
          if (trips.isEmpty) return _EmptyTripsView(onLoadDemo: _loadDemoData);
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final trip = trips[index];
              return _TripListTile(
                trip: trip,
                onTap: () => _openDetail(trip),
                onArchive: () => _confirmArchive(trip),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('新建旅程'),
      ),
    );
  }

  void _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TripCreateScreen()),
    );
    if (created == true) {
      ref.invalidate(activeTripsProvider);
    }
  }

  void _openDetail(Trip trip) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TripDetailScreen(tripId: trip.id),
      ),
    );
    if (changed == true) {
      ref.invalidate(activeTripsProvider);
    }
  }

  Future<void> _confirmArchive(Trip trip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('归档旅程'),
        content: Text('确定要把「${trip.name}」归档吗？归档后可从「归档列表」恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('归档'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(tripNotifierProvider.notifier).archive(trip.id);
      ref.invalidate(activeTripsProvider);
    }
  }

  Future<void> _loadDemoData() async {
    final boxes = ref.read(hiveBoxesProvider);
    if (boxes.trips.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('已有数据'),
          content: const Text(
            '检测到现有旅程数据。\n'
            '演示数据需要全新的数据库。\n\n'
            '建议：在浏览器 DevTools → Application → Storage → Clear site data 后重启应用。\n\n'
            '或者：你也可以手动浏览现有旅程（不加载演示）。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('明白了'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      ref.invalidate(activeTripsProvider);
      return;
    }
    DemoSeed.apply(boxes);
    ref.invalidate(activeTripsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ 演示数据已加载：京都·大阪赏樱 7 日'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

class _TripListTile extends StatelessWidget {
  const _TripListTile({
    required this.trip,
    required this.onTap,
    required this.onArchive,
  });

  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    final dateRange = trip.endDate != null
        ? '${df.format(trip.startDate)} → ${df.format(trip.endDate!)}'
        : df.format(trip.startDate);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _statusColor(trip.status).withOpacity(0.2),
        child: Icon(
          Icons.flight_takeoff,
          color: _statusColor(trip.status),
        ),
      ),
      title: Text(
        trip.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trip.destination != null && trip.destination!.isNotEmpty)
            Text('📍 ${trip.destination}'),
          Text('🗓 $dateRange'),
          const SizedBox(height: 4),
          _StatusChip(status: trip.status),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'archive') onArchive();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                Icon(Icons.archive_outlined, size: 18),
                SizedBox(width: 8),
                Text('归档'),
              ],
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Color _statusColor(TripStatus s) {
    switch (s) {
      case TripStatus.preparing:
        return Colors.orange;
      case TripStatus.ongoing:
        return Colors.green;
      case TripStatus.ended:
        return Colors.grey;
      case TripStatus.archived:
        return Colors.blueGrey;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status == TripStatus.ongoing
        ? Colors.green
        : status == TripStatus.preparing
            ? Colors.orange
            : status == TripStatus.ended
                ? Colors.grey
                : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _EmptyTripsView extends StatelessWidget {
  const _EmptyTripsView({required this.onLoadDemo});
  final VoidCallback onLoadDemo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.luggage_outlined,
                size: 96, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              '还没有旅程',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              '点击右下角 + 按钮创建你的第一个旅程',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: onLoadDemo,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('一键加载演示数据'),
            ),
            const SizedBox(height: 6),
            const Text(
              '京都赏樱 7 日 · 3 成员 · 4 笔费用',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}