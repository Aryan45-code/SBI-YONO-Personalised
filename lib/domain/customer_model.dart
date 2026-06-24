enum CustomerSegment { student, senior, rural, standard }

class CustomerProfile {
  final String name;
  final CustomerSegment segment;
  final double accountBalance;

  const CustomerProfile({
    required this.name,
    required this.segment,
    required this.accountBalance,
  });
}