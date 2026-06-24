import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'customer_model.dart';

// Simulating an active user session. Change the segment here to test different UIs.
//
final authProvider = StateProvider<CustomerProfile?>((ref) {
  return const CustomerProfile(
    name: 'Aryan', 
    segment: CustomerSegment.student,
    accountBalance: 0.0,
  );
});