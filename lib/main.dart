import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/ai_config.dart';
import 'presentation/screens/ai_settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AIConfigProvider(),
      child: MaterialApp(
        title: 'AI 旅行账本',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 模型配置演示'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ModelStatusIndicator(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'AI 旅行账本',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('智能记账与分摊工具'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AISettingsScreen(),
                  ),
                );
              },
              child: const Text('配置 AI 模型'),
            ),
          ],
        ),
      ),
    );
  }
}
