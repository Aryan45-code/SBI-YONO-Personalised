import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_provider.dart';

class StandardHomeShell extends ConsumerWidget {
  const StandardHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('YONO SBI')),
      body: Center(
        child: Text(
          'Good morning, ${user?.name}!\nThis is the data-rich shell for ${user?.segment.name}.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.payment), label: 'Pay'),
        ],
      ),
    );
  }
}