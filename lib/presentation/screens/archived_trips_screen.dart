import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/trip_provider.dart';
import 'trip_detail_screen.dart';

/// 归档旅程列表
class ArchivedTripsScreen extends ConsumerWidget {
  const ArchivedTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedTripsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('归档旅程')),
      body: archivedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (trips) {
          if (trips.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 96, color: Colors.grey),
                    SizedBox(height: 24),
                    Text('没有已归档的旅程',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }
          final df = DateFormat('yyyy-MM-dd');
          return ListView.separated(
            itemCount: trips.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = trips[i];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.archive_outlined, color: Colors.white),
                ),
                title: Text(t.name),
                subtitle: Text(
                  t.endDate != null
                      ? '${df.format(t.startDate)} → ${df.format(t.endDate!)}'
                      : df.format(t.startDate),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await ref.read(tripNotifierProvider.notifier).unarchive(t.id);
                    ref.invalidate(archivedTripsProvider);
                    ref.invalidate(activeTripsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('「${t.name}」已恢复')),
                      );
                    }
                  },
                  child: const Text('恢复'),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripDetailScreen(tripId: t.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}