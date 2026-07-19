import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/trip.dart';
import '../../data/seed_data.dart';
import '../providers/core_providers.dart';
import '../providers/expense_provider.dart';
import '../providers/member_provider.dart';
import '../providers/sync_providers.dart';
import '../providers/trip_provider.dart';
import 'about_screen.dart';
import 'ai_settings_screen.dart';
import 'archived_trips_screen.dart';
import 'auth_screen.dart';
import 'supabase_settings_screen.dart';
import 'trip_create_screen.dart';
import 'trip_detail_screen.dart';

/// 旅程列表（首页）
///
/// 顶部：统计卡片（总旅程/总费用/未结算）
/// 中部：旅程卡片（带背景色 + 状态徽章 + 关键数据）
/// 空状态：插图 + 引导文案
class TripListScreen extends ConsumerStatefulWidget {
  const TripListScreen({super.key});

  @override
  ConsumerState<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends ConsumerState<TripListScreen> {
  @override
  Widget build(BuildContext context) {
    final activeTripsAsync = ref.watch(activeTripsProvider);
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: 60,
              title: const Text(
                '我的旅程',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              actions: [
                IconButton(
                  tooltip: auth.isSignedIn ? '已登录' : '云端同步/设置',
                  icon: Icon(
                    auth.isSignedIn
                        ? Icons.cloud_done
                        : Icons.cloud_sync_outlined,
                    color: auth.isSignedIn ? Colors.green : null,
                  ),
                  onPressed: _openAuth,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) {
                    switch (v) {
                      case 'demo':
                        _loadDemoData();
                        break;
                      case 'archived':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ArchivedTripsScreen(),
                          ),
                        );
                        break;
                      case 'ai':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AISettingsScreen(),
                          ),
                        );
                        break;
                      case 'about':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        );
                        break;
                      case 'cloud':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupabaseSettingsScreen(),
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'demo',
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 18),
                          SizedBox(width: 8),
                          Text('加载演示数据'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'archived',
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('归档列表'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'ai',
                      child: Row(
                        children: [
                          Icon(Icons.psychology_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('AI 设置'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'about',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18),
                          SizedBox(width: 8),
                          Text('关于'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'cloud',
                      child: Row(
                        children: [
                          Icon(Icons.cloud_sync_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('云端设置'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            activeTripsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: _ErrorView(
                  message: '加载旅程失败：$e',
                  onRetry: () => ref.invalidate(activeTripsProvider),
                ),
              ),
              data: (trips) {
                if (trips.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyTripsView(onLoadDemo: _loadDemoData),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return _SummaryHeader(trips: trips);
                      }
                      final trip = trips[index - 1];
                      return _TripCard(
                        trip: trip,
                        onTap: () => _openDetail(trip),
                        onArchive: () => _confirmArchive(trip),
                      );
                    },
                    childCount: trips.length + 1,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('新建旅程'),
      ),
    );
  }

  void _openAuth() async {
    // 检查是否已配置 Supabase
    final settings = ref.read(appSettingsRepositoryProvider).load();
    if (!settings.isCloudMode) {
      // 未配置或本地模式 -> 跳到云端设置页
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SupabaseSettingsScreen()),
      );
      return;
    }
    // 已配置 -> 跳到登录页
    final loggedIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (loggedIn == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 登录成功,数据即将同步')),
      );
    }
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
            '建议：清空应用数据后重启,或浏览现有旅程。',
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

/// 顶部统计卡片：总旅程 / 总费用 / 成员总数
class _SummaryHeader extends ConsumerWidget {
  const _SummaryHeader({required this.trips});
  final List<Trip> trips;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 计算总费用（异步获取）
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7DD7), Color(0xFF5B9BE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_takeoff, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Text(
                '旅程概览',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.map_outlined,
                label: '活跃旅程',
                value: '${trips.length}',
              ),
              _StatDivider(),
              _StatItem(
                icon: Icons.attach_money,
                label: '总笔数',
                value: _totalExpenseCount(ref, trips),
              ),
              _StatDivider(),
              _StatItem(
                icon: Icons.people_outline,
                label: '成员数',
                value: _totalMemberCount(ref, trips),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _totalExpenseCount(WidgetRef ref, List<Trip> trips) {
    // 简化：直接监听第一个 trip 的费用
    if (trips.isEmpty) return '0';
    final firstTripId = trips.first.id;
    final expensesAsync = ref.watch(expensesByTripProvider(firstTripId));
    return expensesAsync.maybeWhen(
      data: (list) => '${list.length}',
      orElse: () => '...',
    );
  }

  String _totalMemberCount(WidgetRef ref, List<Trip> trips) {
    if (trips.isEmpty) return '0';
    final firstTripId = trips.first.id;
    final membersAsync = ref.watch(membersByTripProvider(firstTripId));
    return membersAsync.maybeWhen(
      data: (list) => '${list.length}',
      orElse: () => '...',
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }
}

/// 旅程卡片 - 带渐变头部 + 关键数据
class _TripCard extends ConsumerWidget {
  const _TripCard({
    required this.trip,
    required this.onTap,
    required this.onArchive,
  });

  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final df = DateFormat('M月d日');
    final dateRange = trip.endDate != null
        ? '${df.format(trip.startDate)} – ${df.format(trip.endDate!)}'
        : df.format(trip.startDate);

    // 计算天数
    final days = trip.endDate != null
        ? trip.endDate!.difference(trip.startDate).inDays + 1
        : 1;

    final expensesAsync = ref.watch(expensesByTripProvider(trip.id));
    final membersAsync = ref.watch(membersByTripProvider(trip.id));

    final expenseCount = expensesAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    final memberCount = membersAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 头部：渐变 + 状态徽章
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _statusColor(trip.status),
                        _statusColor(trip.status).withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _statusIcon(trip.status),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (trip.destination != null &&
                                trip.destination!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.place,
                                        size: 13, color: Colors.white70),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        trip.destination!,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      _StatusBadge(status: trip.status),
                    ],
                  ),
                ),

                // 底部：日期 + 数据
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CardDataItem(
                          icon: Icons.calendar_today_outlined,
                          label: dateRange,
                          sublabel: '$days 天',
                        ),
                      ),
                      Container(
                        height: 32,
                        width: 1,
                        color: Colors.grey.withOpacity(0.2),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Expanded(
                        child: _CardDataItem(
                          icon: Icons.receipt_long_outlined,
                          label: '$expenseCount 笔',
                          sublabel: '费用',
                        ),
                      ),
                      Container(
                        height: 32,
                        width: 1,
                        color: Colors.grey.withOpacity(0.2),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Expanded(
                        child: _CardDataItem(
                          icon: Icons.people_outline,
                          label: '$memberCount 人',
                          sublabel: '成员',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, size: 20),
                        color: Colors.grey,
                        onPressed: () => _showActionMenu(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('归档'),
              onTap: () {
                Navigator.pop(context);
                onArchive();
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(TripStatus s) {
    switch (s) {
      case TripStatus.preparing:
        return Icons.flight_takeoff;
      case TripStatus.ongoing:
        return Icons.timeline;
      case TripStatus.ended:
        return Icons.check_circle_outline;
      case TripStatus.archived:
        return Icons.archive;
    }
  }

  Color _statusColor(TripStatus s) {
    switch (s) {
      case TripStatus.preparing:
        return const Color(0xFFF59E0B); // 暖阳橙
      case TripStatus.ongoing:
        return const Color(0xFF10B981); // 草地绿
      case TripStatus.ended:
        return const Color(0xFF6B7280); // 中灰
      case TripStatus.archived:
        return const Color(0xFF4B5563); // 深灰
    }
  }
}

class _CardDataItem extends StatelessWidget {
  const _CardDataItem({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  final IconData icon;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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
            // 渐变圆形背景
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7DD7), Color(0xFF5B9BE0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.luggage_outlined,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '开始你的第一段旅程',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '记录旅行中的每一笔花费\n自动计算 AA 结算,不再为"谁欠谁"烦恼',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.tonalIcon(
              onPressed: onLoadDemo,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('加载演示数据'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.error_outline, size: 56, color: Colors.red),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }
}
