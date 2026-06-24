import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_provider.dart';

class AccessibleHomeShell extends ConsumerWidget {
  const AccessibleHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('YONO SBI', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B57D0),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.waving_hand, size: 64, color: Colors.amber),
            const SizedBox(height: 20),
            Text(
              'नमस्ते ${user?.name ?? 'User'}!',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'This is the Rural/Senior Interface',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}