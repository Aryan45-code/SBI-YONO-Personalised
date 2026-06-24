// ============================================================================
// YONO SBI — GFF 2026 | ULTIMATE PRODUCTION BUILD | main.dart
// Zero Errors · Secure Storage · ML Pipeline · Cold-Start · Accessible UI
// Compound Interest · UUID IDs · YONO Quick · Full Feature Parity
// ============================================================================
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ── dart:math shim so legacy code using sin/pi still compiles ────────────────
double sin(double x) => math.sin(x);
const double pi = math.pi;

// ============================================================================
// SECURE STORAGE SERVICE
// AES-GCM on Android, Keychain on iOS, libsecret on Linux.
// Single instance shared across the app.
// ============================================================================
final _storage = FlutterSecureStorage(
  aOptions: const AndroidOptions(
    encryptedSharedPreferences: true,
  ),
);
const _kQuickUsage = 'yono_quick_usage_v1';
const _kColdStart  = 'yono_cold_start_v1';
const _kLastUser   = 'yono_last_user_v1';

Future<Map<String, int>> loadQuickUsage() async {
  try {
    final raw = await _storage.read(key: _kQuickUsage);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  } catch (_) { return {}; }
}

Future<void> saveQuickUsage(Map<String, int> data) async {
  try { await _storage.write(key: _kQuickUsage, value: jsonEncode(data)); } catch (_) {}
}

Future<void> clearSecureData() async {
  try {
    await _storage.delete(key: _kQuickUsage);
    await _storage.delete(key: _kColdStart);
    await _storage.delete(key: _kLastUser);
  } catch (_) {}
}

// ============================================================================
// DESIGN TOKENS
// ============================================================================
class YonoColors {
  static const deepBlue      = Color(0xFF0D1B3E);
  static const navyBlue      = Color(0xFF1A2F6B);
  static const royalBlue     = Color(0xFF2244A8);
  static const cyan          = Color(0xFF00C2E0);
  static const cyanLight     = Color(0xFFE0F7FB);
  static const gold          = Color(0xFFD4A843);
  static const goldLight     = Color(0xFFFBF3DF);
  static const easeForest    = Color(0xFF1B5E3B);
  static const easeAmber     = Color(0xFFF59E0B);
  static const surface       = Color(0xFFF5F7FC);
  static const card          = Color(0xFFFFFFFF);
  static const divider       = Color(0xFFE8ECF4);
  static const success       = Color(0xFF16A34A);
  static const successBg     = Color(0xFFDCFCE7);
  static const error         = Color(0xFFDC2626);
  static const errorBg       = Color(0xFFFEE2E2);
  static const warning       = Color(0xFFD97706);
  static const warningBg     = Color(0xFFFEF3C7);
  static const textPrimary   = Color(0xFF0D1B3E);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary  = Color(0xFF9CA3AF);
}

class YonoTextStyles {
  static TextStyle display(double size, {Color? color, FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.outfit(fontSize: size, fontWeight: weight,
          color: color ?? YonoColors.textPrimary, letterSpacing: -0.5);
  static TextStyle body(double size, {Color? color, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.outfit(fontSize: size, fontWeight: weight,
          color: color ?? YonoColors.textPrimary);
  static TextStyle mono(double size, {Color? color, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: weight,
          color: color ?? YonoColors.textPrimary);
  static TextStyle hindi(double size, {Color? color, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.hind(fontSize: size, fontWeight: weight,
          color: color ?? YonoColors.textPrimary);
}

// ============================================================================
// UTILITIES
// ============================================================================
String fmt(double amount) {
  final intPart = amount.toInt();
  final decPart = ((amount - intPart) * 100).toInt().abs().toString().padLeft(2, '0');
  String s = intPart.abs().toString();
  if (s.length > 3) {
    final last3 = s.substring(s.length - 3);
    String rest = s.substring(0, s.length - 3);
    rest = rest.replaceAllMapped(RegExp(r'(\d{1,2})(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
    s = '$rest,$last3';
  }
  return '${amount < 0 ? '-' : ''}$s.$decPart';
}

String fmtPaise(int paise) => fmt(paise / 100.0);

String fmtShort(double amount) {
  if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(2)} Cr';
  if (amount >= 100000)   return '${(amount / 100000).toStringAsFixed(2)} L';
  if (amount >= 1000)     return '${(amount / 1000).toStringAsFixed(1)}K';
  return amount.toStringAsFixed(0);
}

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

String timeGreeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good Morning';
  if (h < 17) return 'Good Afternoon';
  return 'Good Evening';
}

String txnEmoji(String? cat) {
  switch (cat) {
    case 'Food':          return '🍽️';
    case 'Income':        return '💰';
    case 'Entertainment': return '🎬';
    case 'Shopping':      return '🛍️';
    case 'Health':        return '💊';
    case 'Utility':       return '💡';
    case 'Family':        return '👨‍👩‍👦';
    case 'Insurance':     return '🛡️';
    case 'Investment':    return '📈';
    case 'Transfer':      return '↔️';
    case 'Electricity':   return '⚡';
    case 'Mobile':        return '📱';
    default:              return '📋';
  }
}

// ============================================================================
// FIX 1 — UUID v4 (replaces all millisecondsSinceEpoch IDs)
// ============================================================================
class YonoUUID {
  YonoUUID._();
  static final _rng = math.Random.secure();
  static String v4() {
    final b = List<int>.generate(16, (_) => _rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String h(int x) => x.toRadixString(16).padLeft(2, '0');
    return '${h(b[0])}${h(b[1])}${h(b[2])}${h(b[3])}-'
           '${h(b[4])}${h(b[5])}-${h(b[6])}${h(b[7])}-'
           '${h(b[8])}${h(b[9])}-'
           '${h(b[10])}${h(b[11])}${h(b[12])}${h(b[13])}${h(b[14])}${h(b[15])}';
  }
  static String shortRef([String prefix = 'SBI']) =>
      '$prefix-${v4().replaceAll('-','').substring(0,8).toUpperCase()}';
}

// ============================================================================
// FIX 2 — FINANCIAL MATH (Compound Interest + Paise Scaling)
// ============================================================================
int    rupeesToPaise(double r)    => (r * 100).round();
double paiseToRupees(int p)       => p / 100.0;

double compoundMaturity(double principal, double annualRate, int months) {
  const n = 4; // quarterly
  final t = months / 12.0;
  final raw = principal * math.pow(1.0 + annualRate / n, n * t);
  return (raw * 100).roundToDouble() / 100.0;
}

class FinancialMath {
  FinancialMath._();
  static double fdMaturity(double p, double r, int m) => compoundMaturity(p, r, m);
  static double? deductBalance(double bal, double amt) {
    if (amt <= 0) return null;
    final bp = rupeesToPaise(bal), ap = rupeesToPaise(amt);
    if (ap > bp) return null;
    return paiseToRupees(bp - ap);
  }
  static double addBalance(double bal, double amt) =>
      paiseToRupees(rupeesToPaise(bal) + rupeesToPaise(amt));
}

// ============================================================================
// MODELS
// ============================================================================
enum CustomerSegment { nextgen, ease }

class Transaction {
  final String id, title; final double amount;
  final DateTime date; final bool isDebit; final String? category;
  Transaction({required this.id, required this.title, required this.amount,
      required this.date, required this.isDebit, this.category});
}

class FixedDeposit {
  final String id;
  final double principal, maturityAmount, interestRate;
  final int months; final DateTime date;
  FixedDeposit({required this.id, required this.principal, required this.months,
      required this.maturityAmount, required this.date, required this.interestRate});
  double get earnedInterest => maturityAmount - principal;
  DateTime get maturityDate =>
      DateTime(date.year, date.month + months, date.day);
}

class InsurancePolicy {
  final String id, title; final double coverAmount, premium; final DateTime date;
  InsurancePolicy({required this.id, required this.title,
      required this.coverAmount, required this.premium, required this.date});
}

class BillPayment {
  final String id, biller, category; final double amount; final DateTime date;
  BillPayment({required this.id, required this.biller, required this.category,
      required this.amount, required this.date});
}

class AppNotification {
  final String id, title, body, type; final DateTime date; bool isRead;
  AppNotification({required this.id, required this.title, required this.body,
      required this.type, required this.date, this.isRead = false});
}

class LoanApplication {
  final String id, type, status; final double amount, emi; final int tenure;
  LoanApplication({required this.id, required this.type, required this.amount,
      required this.emi, required this.tenure, required this.status});
}

class CustomerProfile {
  final String id, name, accountNumber, ifscCode, profileEmoji, mobileNumber, email;
  final CustomerSegment segment;
  final double accountBalance;
  final int creditScore, rewardPoints;
  final bool balanceHidden;
  final List<FixedDeposit> activeFDs;
  final List<Transaction> transactions;
  final List<InsurancePolicy> insurancePolicies;
  final List<BillPayment> billPayments;
  final List<AppNotification> notifications;
  final List<LoanApplication> loans;

  CustomerProfile({
    required this.id, required this.name, required this.segment,
    required this.accountBalance, required this.accountNumber, required this.ifscCode,
    this.activeFDs = const [], this.transactions = const [],
    this.insurancePolicies = const [], this.billPayments = const [],
    this.notifications = const [], this.loans = const [],
    this.creditScore = 0, this.profileEmoji = '👤',
    this.rewardPoints = 0, this.mobileNumber = '', this.email = '',
    this.balanceHidden = false,
  });

  CustomerProfile copyWith({
    double? accountBalance, List<FixedDeposit>? activeFDs,
    List<Transaction>? transactions, List<InsurancePolicy>? insurancePolicies,
    List<BillPayment>? billPayments, List<AppNotification>? notifications,
    List<LoanApplication>? loans, int? rewardPoints, bool? balanceHidden,
  }) => CustomerProfile(
    id: id, name: name, segment: segment,
    accountBalance: accountBalance ?? this.accountBalance,
    accountNumber: accountNumber, ifscCode: ifscCode,
    activeFDs: activeFDs ?? this.activeFDs,
    transactions: transactions ?? this.transactions,
    insurancePolicies: insurancePolicies ?? this.insurancePolicies,
    billPayments: billPayments ?? this.billPayments,
    notifications: notifications ?? this.notifications,
    loans: loans ?? this.loans,
    creditScore: creditScore, profileEmoji: profileEmoji,
    rewardPoints: rewardPoints ?? this.rewardPoints,
    mobileNumber: mobileNumber, email: email,
    balanceHidden: balanceHidden ?? this.balanceHidden,
  );

  double get totalFDValue  => activeFDs.fold(0, (s, fd) => s + fd.principal);
  double get monthlyCredit => transactions.where((t) => !t.isDebit).fold(0.0, (s, t) => s + t.amount);
  double get monthlyDebit  => transactions.where((t) =>  t.isDebit).fold(0.0, (s, t) => s + t.amount);
  int    get unreadCount   => notifications.where((n) => !n.isRead).length;
  Map<String, double> get spendByCategory {
    final map = <String, double>{};
    for (final t in transactions.where((t) => t.isDebit)) {
      map[t.category ?? 'Other'] = (map[t.category ?? 'Other'] ?? 0) + t.amount;
    }
    return map;
  }
}

// ============================================================================
// MOCK DATABASE — 5 demo users covering all segments and ML paths
// ============================================================================
final _mockDatabase = {
  // User 1: Aryan — Young, no transactions → cold start → NextGen
  'aryan': CustomerProfile(
    id: 'aryan', name: 'Aryan Pandey', segment: CustomerSegment.nextgen,
    accountBalance: 124850.75, accountNumber: '•••• •••• 5678',
    ifscCode: 'SBIN0001234', creditScore: 768, profileEmoji: '😎',
    rewardPoints: 2340, mobileNumber: '+91 98765 43210',
    email: 'aryan.pandey@email.com',
    loans: [LoanApplication(id: 'l1', type: 'Home Loan',
        amount: 5000000, emi: 44491, tenure: 240, status: 'Active')],
    transactions: [], // empty → triggers cold start survey
    billPayments: [BillPayment(id: 'b1', biller: 'UPPCL Electricity',
        category: 'Electricity', amount: 1240,
        date: DateTime.now().subtract(const Duration(days: 20)))],
    notifications: [AppNotification(id: 'n3', title: 'New Offer',
        body: '5% cashback on SBI Credit Card spends this weekend.',
        type: 'offer', date: DateTime.now(), isRead: false)],
  ),

  // User 2: Ashok — Senior, pension income → ML routes to Ease
  'ashok': CustomerProfile(
    id: 'ashok', name: 'Ashok Kumar', segment: CustomerSegment.ease,
    accountBalance: 850000.00, accountNumber: '•••• •••• 9012',
    ifscCode: 'SBIN0005678', profileEmoji: '🙏',
    rewardPoints: 850, mobileNumber: '+91 87654 32109',
    email: 'ashok.kumar@email.com',
    transactions: [
      Transaction(id: 't10', title: 'पेंशन (Pension)', amount: 35000,
          date: DateTime.now().subtract(const Duration(days: 2)),
          isDebit: false, category: 'Income'),
      Transaction(id: 't11', title: 'दवाई — MedPlus', amount: 1200,
          date: DateTime.now().subtract(const Duration(days: 5)),
          isDebit: true, category: 'Health'),
      Transaction(id: 't12', title: 'बिजली बिल (UPPCL)', amount: 890,
          date: DateTime.now().subtract(const Duration(days: 8)),
          isDebit: true, category: 'Utility'),
      Transaction(id: 't13', title: 'बेटे से (Son Transfer)', amount: 5000,
          date: DateTime.now().subtract(const Duration(days: 12)),
          isDebit: false, category: 'Family'),
      Transaction(id: 't14', title: 'पानी बिल (Water Bill)', amount: 320,
          date: DateTime.now().subtract(const Duration(days: 15)),
          isDebit: true, category: 'Utility'),
    ],
    billPayments: [BillPayment(id: 'b3', biller: 'UPPCL Electricity',
        category: 'Electricity', amount: 890,
        date: DateTime.now().subtract(const Duration(days: 8)))],
    notifications: [
      AppNotification(id: 'n4', title: 'पेंशन जमा हुई',
          body: '₹35,000 आपके खाते में जमा हुए।',
          type: 'credit', date: DateTime.now().subtract(const Duration(days: 2))),
      AppNotification(id: 'n5', title: 'FD विशेष ऑफर',
          body: 'वरिष्ठ नागरिकों के लिए 7.6% FD ऑफर।',
          type: 'offer', date: DateTime.now(), isRead: false),
    ],
  ),

  // User 3: Priya — Working professional, rich transaction history → high confidence NextGen
  'priya': CustomerProfile(
    id: 'priya', name: 'Priya Sharma', segment: CustomerSegment.nextgen,
    accountBalance: 287340.50, accountNumber: '•••• •••• 3421',
    ifscCode: 'SBIN0002345', creditScore: 812, profileEmoji: '👩‍💼',
    rewardPoints: 4750, mobileNumber: '+91 91234 56789',
    email: 'priya.sharma@email.com',
    transactions: [
      Transaction(id: 'p1', title: 'Salary Credit — TCS',
          amount: 95000, date: DateTime.now().subtract(const Duration(days: 1)),
          isDebit: false, category: 'Income'),
      Transaction(id: 'p2', title: 'Swiggy — Dinner',
          amount: 450, date: DateTime.now().subtract(const Duration(days: 2)),
          isDebit: true, category: 'Food'),
      Transaction(id: 'p3', title: 'Netflix — Subscription',
          amount: 649, date: DateTime.now().subtract(const Duration(days: 3)),
          isDebit: true, category: 'Entertainment'),
      Transaction(id: 'p4', title: 'Amazon — Skincare',
          amount: 1899, date: DateTime.now().subtract(const Duration(days: 4)),
          isDebit: true, category: 'Shopping'),
      Transaction(id: 'p5', title: 'Zomato — Lunch',
          amount: 320, date: DateTime.now().subtract(const Duration(days: 5)),
          isDebit: true, category: 'Food'),
      Transaction(id: 'p6', title: 'UPI — Gym Fees',
          amount: 2500, date: DateTime.now().subtract(const Duration(days: 7)),
          isDebit: true, category: 'Health'),
      Transaction(id: 'p7', title: 'BookMyShow — Concert',
          amount: 1800, date: DateTime.now().subtract(const Duration(days: 10)),
          isDebit: true, category: 'Entertainment'),
    ],
    activeFDs: [
      FixedDeposit(id: 'fd_p1', principal: 50000, months: 12,
          maturityAmount: compoundMaturity(50000, 0.071, 12),
          date: DateTime.now().subtract(const Duration(days: 60)),
          interestRate: 0.071),
    ],
    billPayments: [
      BillPayment(id: 'bp1', biller: 'Airtel Postpaid',
          category: 'Mobile', amount: 999,
          date: DateTime.now().subtract(const Duration(days: 5))),
    ],
    notifications: [
      AppNotification(id: 'np1', title: 'Salary Credited',
          body: '₹95,000 credited to your account.',
          type: 'credit', date: DateTime.now().subtract(const Duration(days: 1))),
      AppNotification(id: 'np2', title: 'FD Renewal Due',
          body: 'Your FD of ₹50,000 matures in 30 days.',
          type: 'offer', date: DateTime.now(), isRead: false),
    ],
  ),

  // User 4: Ramesh — Farmer, rural, Hindi preference → strong Ease signal
  'ramesh': CustomerProfile(
    id: 'ramesh', name: 'Ramesh Yadav', segment: CustomerSegment.ease,
    accountBalance: 42500.00, accountNumber: '•••• •••• 7823',
    ifscCode: 'SBIN0009876', profileEmoji: '🧑‍🌾',
    rewardPoints: 120, mobileNumber: '+91 94523 11098',
    email: 'ramesh.yadav@kisan.in',
    transactions: [
      Transaction(id: 'r1', title: 'PM-KISAN सहायता',
          amount: 2000, date: DateTime.now().subtract(const Duration(days: 3)),
          isDebit: false, category: 'Income'),
      Transaction(id: 'r2', title: 'बीज खरीद — कृषि केंद्र',
          amount: 3200, date: DateTime.now().subtract(const Duration(days: 8)),
          isDebit: true, category: 'Investment'),
      Transaction(id: 'r3', title: 'बिजली बिल',
          amount: 560, date: DateTime.now().subtract(const Duration(days: 12)),
          isDebit: true, category: 'Utility'),
      Transaction(id: 'r4', title: 'फसल बिक्री',
          amount: 18000, date: DateTime.now().subtract(const Duration(days: 20)),
          isDebit: false, category: 'Income'),
    ],
    notifications: [
      AppNotification(id: 'rn1', title: 'PM-KISAN किश्त',
          body: '₹2,000 की किश्त आपके खाते में जमा हुई।',
          type: 'credit', date: DateTime.now().subtract(const Duration(days: 3))),
    ],
  ),

  // User 5: Kavya — Student, minimal transactions → cold start → NextGen expected
  'kavya': CustomerProfile(
    id: 'kavya', name: 'Kavya Reddy', segment: CustomerSegment.nextgen,
    accountBalance: 18200.00, accountNumber: '•••• •••• 4467',
    ifscCode: 'SBIN0003456', creditScore: 0, profileEmoji: '🧑‍🎓',
    rewardPoints: 80, mobileNumber: '+91 99887 76655',
    email: 'kavya.reddy@student.edu',
    transactions: [
      Transaction(id: 'k1', title: 'Scholarship Credit',
          amount: 15000, date: DateTime.now().subtract(const Duration(days: 5)),
          isDebit: false, category: 'Income'),
      Transaction(id: 'k2', title: 'UPI — Hostel Mess',
          amount: 2800, date: DateTime.now().subtract(const Duration(days: 7)),
          isDebit: true, category: 'Food'),
    ],
    notifications: [
      AppNotification(id: 'kn1', title: 'Welcome to YONO',
          body: 'Start your financial journey with SBI.',
          type: 'offer', date: DateTime.now(), isRead: false),
    ],
  ),
};

// ============================================================================
// STATE — AuthNotifier
// ============================================================================
// PIN MAP — demo credentials
// aryan/1234 → cold start → NextGen
// ashok/5678 → pension signals → Ease
// priya/2345 → rich txn history → high confidence NextGen
// ramesh/6789 → rural/farmer → Ease
// kavya/3456 → student, minimal txns → cold start → NextGen
const _pinMap = {
  'aryan':  '123456',
  'ashok':  '567890',
  'priya':  '234567',
  'ramesh': '678901',
  'kavya':  '345678',
};
int _loginAttempts = 0;

class AuthNotifier extends Notifier<CustomerProfile?> {
  @override CustomerProfile? build() => null;

  bool login(String username, String pin) {
    if (_loginAttempts >= 5) return false; // lockout after 5 attempts
    final key = username.trim().toLowerCase();
    final expected = _pinMap[key];
    if (_mockDatabase.containsKey(key) && expected != null && pin == expected) {
      _loginAttempts = 0;
      state = _mockDatabase[key]; return true;
    }
    _loginAttempts++;
    return false;
  }

  void logout() { _loginAttempts = 0; state = null; }

  void toggleBalance() {
    if (state == null) return;
    state = state!.copyWith(balanceHidden: !state!.balanceHidden);
  }

  /// Demo hot-state: inject 5 realistic transactions so ML fires NextGen.
  void triggerDemoHotState() {
    if (state == null) return;
    final now = DateTime.now();
    final demo = [
      Transaction(id: YonoUUID.v4(), title: 'Zomato — Pav Bhaji & Sweets',
          amount: 340, date: now.subtract(const Duration(hours: 2)),
          isDebit: true, category: 'Food'),
      Transaction(id: YonoUUID.v4(), title: 'Amazon Pay — Tech Accessories',
          amount: 1299, date: now.subtract(const Duration(hours: 5)),
          isDebit: true, category: 'Shopping'),
      Transaction(id: YonoUUID.v4(), title: 'BookMyShow — Movie Tickets',
          amount: 650, date: now.subtract(const Duration(days: 1)),
          isDebit: true, category: 'Entertainment'),
      Transaction(id: YonoUUID.v4(), title: 'UPI — E-Cell Event',
          amount: 500, date: now.subtract(const Duration(days: 2)),
          isDebit: true, category: 'Transfer'),
      Transaction(id: YonoUUID.v4(), title: 'Swiggy — South Indian Thali',
          amount: 280, date: now.subtract(const Duration(days: 3)),
          isDebit: true, category: 'Food'),
      Transaction(id: YonoUUID.v4(), title: 'Salary Credit',
          amount: 85000, date: now.subtract(const Duration(days: 4)),
          isDebit: false, category: 'Income'),
    ];
    const deducted = 340 + 1299 + 650 + 500 + 280;
    state = state!.copyWith(
      transactions: [...demo, ...state!.transactions],
      accountBalance: FinancialMath.addBalance(
          state!.accountBalance, 85000 - deducted.toDouble()),
    );
  }

  // ── Compound interest createFD ─────────────────────────────────────────────
  bool createFD(double amount, int months, double rate) {
    final newBal = FinancialMath.deductBalance(state?.accountBalance ?? 0, amount);
    if (state == null || newBal == null) return false;
    final maturity = FinancialMath.fdMaturity(amount, rate, months);
    final fd  = FixedDeposit(id: YonoUUID.v4(), principal: amount,
        months: months, maturityAmount: maturity,
        date: DateTime.now(), interestRate: rate);
    final txn = Transaction(id: YonoUUID.v4(), title: 'FD Created',
        amount: amount, date: DateTime.now(), isDebit: true, category: 'Investment');
    state = state!.copyWith(
      accountBalance: newBal,
      activeFDs: [fd, ...state!.activeFDs],
      transactions: [txn, ...state!.transactions],
      rewardPoints: state!.rewardPoints + (amount / 1000).round() * 5,
    );
    return true;
  }

  bool buyInsurance(double premium, String title, double cover) {
    final newBal = FinancialMath.deductBalance(state?.accountBalance ?? 0, premium);
    if (state == null || newBal == null) return false;
    final policy = InsurancePolicy(id: YonoUUID.v4(), title: title,
        coverAmount: cover, premium: premium, date: DateTime.now());
    final txn = Transaction(id: YonoUUID.v4(), title: title,
        amount: premium, date: DateTime.now(), isDebit: true, category: 'Insurance');
    state = state!.copyWith(
      accountBalance: newBal,
      insurancePolicies: [policy, ...state!.insurancePolicies],
      transactions: [txn, ...state!.transactions],
      rewardPoints: state!.rewardPoints + 50,
    );
    return true;
  }

  bool sendMoney(double amount, String to) {
    final newBal = FinancialMath.deductBalance(state?.accountBalance ?? 0, amount);
    if (state == null || newBal == null) return false;
    final txn = Transaction(id: YonoUUID.v4(), title: 'UPI — $to',
        amount: amount, date: DateTime.now(), isDebit: true, category: 'Transfer');
    state = state!.copyWith(
      accountBalance: newBal,
      transactions: [txn, ...state!.transactions],
      rewardPoints: state!.rewardPoints + 2,
    );
    return true;
  }

  bool payBill(double amount, String biller, String category) {
    final newBal = FinancialMath.deductBalance(state?.accountBalance ?? 0, amount);
    if (state == null || newBal == null) return false;
    final bill = BillPayment(id: YonoUUID.v4(), biller: biller,
        category: category, amount: amount, date: DateTime.now());
    final txn  = Transaction(id: YonoUUID.v4(), title: biller,
        amount: amount, date: DateTime.now(), isDebit: true, category: category);
    state = state!.copyWith(
      accountBalance: newBal,
      billPayments: [bill, ...state!.billPayments],
      transactions: [txn, ...state!.transactions],
      rewardPoints: state!.rewardPoints + 10,
    );
    return true;
  }

  void markAllRead() {
    if (state == null) return;
    final updated = state!.notifications.map((n) => AppNotification(
        id: n.id, title: n.title, body: n.body,
        type: n.type, date: n.date, isRead: true)).toList();
    state = state!.copyWith(notifications: updated);
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, CustomerProfile?>(AuthNotifier.new);

// ============================================================================
// YONO QUICK — Usage tracking with secure-storage persistence
// ============================================================================
class QuickUsageNotifier extends Notifier<Map<String, int>> {
  @override Map<String, int> build() => {};

  void init(Map<String, int> saved) => state = Map.from(saved);

  void recordTap(String actionId) {
    final updated = Map<String, int>.from(state);
    updated[actionId] = (updated[actionId] ?? 0) + 1;
    state = updated;
    saveQuickUsage(updated); // async write to secure storage
  }

  List<String> topActions(int n) {
    final sorted = state.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }

  void reset() { state = {}; saveQuickUsage({}); }
}

final quickUsageProvider =
    NotifierProvider<QuickUsageNotifier, Map<String, int>>(QuickUsageNotifier.new);

// ============================================================================
// ML PIPELINE — Segment Prediction
// ============================================================================
class SegmentPrediction {
  final CustomerSegment recommended;
  final double confidence;
  final List<String> signals;
  final String headline;
  final bool isHighConfidence;
  const SegmentPrediction({
    required this.recommended, required this.confidence,
    required this.signals, required this.headline, required this.isHighConfidence,
  });
}

class YonoMLPipeline {
  static Map<String, double> _extract(CustomerProfile u) {
    final txns = u.transactions;
    final totalSpend = u.monthlyDebit;
    final digital = ['upi','swiggy','zomato','netflix','amazon',
                     'spotify','blinkit','zepto','ola','uber'];
    final dCount = txns.where((t) =>
        digital.any((k) => t.title.toLowerCase().contains(k))).length;
    final dRatio = txns.isEmpty ? 0.0 : dCount / txns.length;
    final pension = txns.where((t) =>
        t.title.toLowerCase().contains('pension') ||
        (t.category == 'Income' && t.amount > 25000)).length;
    final cats  = txns.map((t) => t.category).toSet().length.toDouble();
    final avg   = txns.isEmpty ? 0.0 : totalSpend / (txns.length + 1);
    final util  = totalSpend == 0 ? 0.0 :
        txns.where((t) => t.isDebit &&
            (t.category == 'Utility' || t.category == 'Health'))
            .fold(0.0, (s, t) => s + t.amount) / totalSpend;
    final ent   = totalSpend == 0 ? 0.0 :
        txns.where((t) => t.isDebit &&
            (t.category == 'Entertainment' || t.category == 'Food'))
            .fold(0.0, (s, t) => s + t.amount) / totalSpend;
    final balR  = u.monthlyCredit == 0 ? 1.0 :
        u.accountBalance / (u.monthlyCredit + 1);
    return {
      'digital_ratio':   dRatio,
      'pension_signal':  pension > 0 ? 1.0 : 0.0,
      'category_div':    (cats / 7.0).clamp(0.0, 1.0),
      'avg_txn_norm':    (avg / 5000.0).clamp(0.0, 1.0),
      'utility_ratio':   util,
      'entertain_ratio': ent,
      'balance_ratio':   balR.clamp(0.0, 10.0) / 10.0,
      'credit_norm':     (u.creditScore / 850.0).clamp(0.0, 1.0),
      'has_fds':         u.activeFDs.isNotEmpty ? 1.0 : 0.0,
    };
  }

  static SegmentPrediction predict(CustomerProfile u) {
    final f = _extract(u);
    double ng = f['digital_ratio']!   * 2.8
              + f['category_div']!    * 1.6
              + f['entertain_ratio']! * 2.1
              + f['credit_norm']!     * 1.2
              + f['avg_txn_norm']!    * 0.8;
    double ease = f['pension_signal']! * 3.5
                + f['utility_ratio']!  * 2.4
                + f['has_fds']!        * 1.8
                + f['balance_ratio']!  * 1.0;
    final total  = ng + ease + 0.001;
    final ngProb = ng   / total;
    final eProb  = ease / total;
    final isNG   = ngProb >= eProb;
    final conf   = isNG ? ngProb : eProb;
    final sigs   = <String>[];
    if (f['digital_ratio']!   > 0.3)  sigs.add('High digital payment activity (UPI, apps)');
    if (f['pension_signal']! == 1.0)  sigs.add('Pension income detected in transactions');
    if (f['entertain_ratio']! > 0.15) sigs.add('Regular entertainment & food spending');
    if (f['utility_ratio']!   > 0.2)  sigs.add('Steady utility & health bill payments');
    if (f['has_fds']!        == 1.0)  sigs.add('Active Fixed Deposits portfolio');
    if (f['credit_norm']!     > 0.7)  sigs.add('Strong credit profile (score ${u.creditScore})');
    if (sigs.isEmpty) sigs.add('General transaction pattern analysis');
    return SegmentPrediction(
      recommended: isNG ? CustomerSegment.nextgen : CustomerSegment.ease,
      confidence:  double.parse(conf.toStringAsFixed(2)),
      signals:     sigs,
      headline:    isNG
          ? 'Your profile matches YONO NextGen'
          : 'आपकी प्रोफ़ाइल YONO Ease से मेल खाती है',
      isHighConfidence: conf >= 0.68,
    );
  }
}

class MLPipelineNotifier extends Notifier<SegmentPrediction?> {
  @override
  SegmentPrediction? build() {
    ref.keepAlive();
    return _globalPredictionCache; // restore from cache on rebuild
  }

  Future<void> runPipeline(CustomerProfile u) async {
    if (state != null) return; // already set — don't overwrite
    await Future.delayed(const Duration(milliseconds: 600));
    final result = YonoMLPipeline.predict(u);
    _globalPredictionCache = result;
    state = result;
  }

  void setSurveyResult(SegmentPrediction p) {
    _globalPredictionCache = p;
    state = p;
  }

  void reset() {
    _globalPredictionCache = null;
    state = null;
  }
}


final mlPipelineProvider =
    NotifierProvider<MLPipelineNotifier, SegmentPrediction?>(
      MLPipelineNotifier.new,
    );
// Global cache — survives Riverpod provider resets on screen navigation
SegmentPrediction? _globalPredictionCache;

// ── Cold start ────────────────────────────────────────────────────────────────
const int kWarmThreshold = 5;
bool needsColdStart(CustomerProfile u) => u.transactions.length < 3;

class ColdStartAnswers {
  final int ageGroup; final bool prefersHindi;
  const ColdStartAnswers({required this.ageGroup, required this.prefersHindi});
  CustomerSegment get segment =>
      (ageGroup >= 2 || prefersHindi) ? CustomerSegment.ease : CustomerSegment.nextgen;
  SegmentPrediction toSegmentPrediction() => SegmentPrediction(
    recommended: segment, confidence: 0.62,
    signals: ['Age group: ${_ag()}',
              'Language preference: ${prefersHindi ? "Hindi" : "English"}',
              'New user profile — intelligent onboarding applied'],
    headline: segment == CustomerSegment.nextgen
        ? 'Welcome to YONO NextGen' : 'YONO Ease में आपका स्वागत है',
    isHighConfidence: false,
  );
  String _ag() { switch(ageGroup){case 0:return '18–25';case 1:return '26–45';case 2:return '46–60';default:return '60+';} }
}

// ============================================================================
// QUICK-ACTION CATALOGUE
// ============================================================================
class QuickAction {
  final String id, label, emoji, route;
  final bool isNextGen, isHindi;
  const QuickAction({required this.id, required this.label,
      required this.emoji, required this.route,
      this.isNextGen = true, this.isHindi = false});
}

const _ngActions = [
  QuickAction(id:'ng_scan',   label:'Scan & Pay',  emoji:'📷', route:'/nextgen/scan-pay'),
  QuickAction(id:'ng_send',   label:'Send Money',  emoji:'💸', route:'/nextgen/send-money'),
  QuickAction(id:'ng_bills',  label:'Pay Bills',   emoji:'📄', route:'/nextgen/pay-bills'),
  QuickAction(id:'ng_fd',     label:'Open FD',     emoji:'🏦', route:'/nextgen/fd-create'),
  QuickAction(id:'ng_loan',   label:'Loan EMI',    emoji:'🏠', route:'/nextgen/loan-calc'),
  QuickAction(id:'ng_reward', label:'Rewards',     emoji:'🎁', route:'/nextgen/rewards'),
];
const _easeActions = [
  QuickAction(id:'ease_send',   label:'पैसे भेजें',    emoji:'💸', route:'/ease/send-money',  isNextGen:false, isHindi:true),
  QuickAction(id:'ease_fd',     label:'FD खोलें',      emoji:'🏦', route:'/ease/fd-create',   isNextGen:false, isHindi:true),
  QuickAction(id:'ease_bima',   label:'फसल बीमा',      emoji:'🌾', route:'/ease/fasal-bima',  isNextGen:false, isHindi:true),
  QuickAction(id:'ease_health', label:'स्वास्थ्य बीमा', emoji:'🏥', route:'/ease/health-ins',  isNextGen:false, isHindi:true),
];

// ============================================================================
// ROUTER
// ============================================================================
// ============================================================================
// SPLASH SCREEN
// ============================================================================
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _fade  = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D20),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF060D20), Color(0xFF0D1B3E), Color(0xFF1A2F6B)],
          ),
        ),
        child: SafeArea(child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Opacity(opacity: _fade.value,
              child: Transform.scale(scale: _scale.value, child: child)),
          child: Center(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15), width: 1.5)),
                child: const Icon(Icons.account_balance,
                    size: 52, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('yono SBI',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: -1)),
              const SizedBox(height: 6),
              Text('You Only Need One',
                style: TextStyle(fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.45),
                    letterSpacing: 0.5)),
              const SizedBox(height: 56),
              SizedBox(
                width: double.infinity, height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D1B3E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.go('/login');
                  },
                  child: const Text('Get Started',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Protected by 256-bit SSL  •  © State Bank of India',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.25))),
            ]),
          )),
        )),
      ),
    );
  }
}

// ============================================================================
// ROUTER
// ============================================================================
final routerProvider = Provider<GoRouter>((ref) => GoRouter(
  initialLocation: '/login',
  redirect: (ctx, s) {
    final loggedIn = ref.read(authProvider) != null;
    final loc = s.matchedLocation;
    // Allow splash and login without auth
    if (loc == '/splash' || loc == '/login') return null;
    // All other routes require login
    if (!loggedIn) return '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login',  builder: (_, __) => const MLAwareLoginScreenV2()),
    GoRoute(path: '/portal', builder: (_, __) => const SmartPortalScreen()),
    GoRoute(path: '/nextgen', builder: (_, __) => const NextGenShell(), routes: [
      GoRoute(path: 'fd-create',     builder: (_, __) => const NextGenFDScreen()),
      GoRoute(path: 'send-money',    builder: (_, __) => const NextGenSendMoneyScreen()),
      GoRoute(path: 'pay-bills',     builder: (_, __) => const NextGenBillPayScreen()),
      GoRoute(path: 'scan-pay',      builder: (_, __) => const ScanPayScreen()),
      GoRoute(path: 'loan-calc',     builder: (_, __) => const LoanCalculatorScreen()),
      GoRoute(path: 'notifications', builder: (_, __) => const NotificationsScreen(isNextGen: true)),
      GoRoute(path: 'analytics',     builder: (_, __) => const SpendAnalyticsScreen()),
      GoRoute(path: 'rewards',       builder: (_, __) => const RewardsScreen(isNextGen: true)),
      GoRoute(path: 'change-mpin',   builder: (_, __) => const ChangeMpinScreen()),
      GoRoute(path: 'success', builder: (_, s) {
        final e = s.extra as Map<String,String>? ?? {};
        return AnimatedSuccessScreen(title: e['title'] ?? 'Done!',
            subtitle: e['subtitle'] ?? '', returnRoute: e['route'] ?? '/nextgen',
            isHindi: false);
      }),
    ]),
    GoRoute(path: '/ease', builder: (_, __) => const EaseShell(), routes: [
      GoRoute(path: 'fasal-bima',    builder: (_, __) => const EaseBimaScreen()),
      GoRoute(path: 'fd-create',     builder: (_, __) => const EaseFDScreen()),
      GoRoute(path: 'send-money',    builder: (_, __) => const EaseSendMoneyScreen()),
      GoRoute(path: 'health-ins',    builder: (_, __) => const EaseHealthInsuranceScreen()),
      GoRoute(path: 'notifications', builder: (_, __) => const NotificationsScreen(isNextGen: false)),
      GoRoute(path: 'rewards',       builder: (_, __) => const RewardsScreen(isNextGen: false)),
      GoRoute(path: 'success', builder: (_, s) {
        final e = s.extra as Map<String,String>? ?? {};
        return AnimatedSuccessScreen(title: e['title'] ?? 'हो गया!',
            subtitle: e['subtitle'] ?? '', returnRoute: e['route'] ?? '/ease',
            isHindi: true);
      }),
    ]),
  ],
));

// ============================================================================
// MAIN
// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load persisted quick-usage from secure storage before first frame
  final savedUsage = await loadQuickUsage();
  runApp(ProviderScope(
    overrides: [
      quickUsageProvider.overrideWith(() {
        final n = QuickUsageNotifier();
        // schedule init after build
        Future.microtask(() => n.init(savedUsage));
        return n;
      }),
    ],
    child: const YonoApp(),
  ));
}

class YonoApp extends ConsumerWidget {
  const YonoApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'YONO SBI',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: YonoColors.surface,
      textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
      colorScheme: ColorScheme.fromSeed(seedColor: YonoColors.navyBlue),
      splashFactory: InkRipple.splashFactory,
    ),
    routerConfig: ref.watch(routerProvider),
  );
}

// ============================================================================
// FIX 3 — ACCESSIBLE WIDGETS (no hardcoded pixel sizes for text containers)
// ============================================================================
class AccessibleAvatar extends StatelessWidget {
  final String emoji; final List<Color> gradient; final double baseSize;
  const AccessibleAvatar({super.key, required this.emoji,
      required this.gradient, this.baseSize = 86});
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
    final size  = baseSize * scale;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient,
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          shape: BoxShape.circle),
      child: Center(child: FittedBox(child: Padding(
          padding: EdgeInsets.all(size * 0.18),
          child: Text(emoji, style: TextStyle(fontSize: baseSize * 0.48))))),
    );
  }
}

class AccessibleBalanceHidden extends StatelessWidget {
  const AccessibleBalanceHidden({super.key});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 40, minWidth: 160),
    child: IntrinsicWidth(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8)),
      child: const FittedBox(fit: BoxFit.scaleDown,
          child: Text('••••••', style: TextStyle(
              color: Colors.white38, fontSize: 28, letterSpacing: 6))),
    )),
  );
}

class AccessibleContactChip extends StatelessWidget {
  final String emoji, label; final bool selected; final VoidCallback onTap;
  const AccessibleContactChip({super.key, required this.emoji,
      required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.8);
    final size  = 64.0 * scale;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(duration: const Duration(milliseconds: 200),
          width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: selected ? YonoColors.easeForest
                : YonoColors.easeForest.withValues(alpha: 0.10),
            border: Border.all(
                color: selected ? YonoColors.easeAmber : Colors.transparent,
                width: 2.5)),
          child: Center(child: FittedBox(child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(emoji, style: TextStyle(fontSize: 28.0 * scale)))))),
        const SizedBox(height: 6),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 72),
          child: Text(label,
              style: YonoTextStyles.hindi(13, weight: FontWeight.w600),
              textAlign: TextAlign.center, maxLines: 1,
              overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class AccessibleSuccessCircle extends StatelessWidget {
  final Color accentColor; final bool isHindi;
  const AccessibleSuccessCircle({super.key,
      required this.accentColor, required this.isHindi});
  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: 0.38,
    child: AspectRatio(aspectRatio: 1, child: Container(
      decoration: BoxDecoration(shape: BoxShape.circle,
          color: accentColor.withValues(alpha: 0.10),
          border: Border.all(color: accentColor.withValues(alpha: 0.30), width: 2)),
      child: Padding(padding: const EdgeInsets.all(14), child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: LinearGradient(colors: isHindi
              ? [YonoColors.easeForest, const Color(0xFF14532D)]
              : [YonoColors.royalBlue, YonoColors.navyBlue],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.35),
              blurRadius: 24, offset: const Offset(0, 8))]),
        child: const Center(child: FractionallySizedBox(widthFactor: 0.50,
            child: FittedBox(child: Icon(Icons.check_rounded, color: Colors.white)))),
      )),
    )),
  );
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================
class YonoCard extends StatelessWidget {
  final Widget child; final EdgeInsetsGeometry? padding;
  final Color? color; final double radius; final List<BoxShadow>? shadows;
  const YonoCard({super.key, required this.child, this.padding,
      this.color, this.radius = 20, this.shadows});
  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(color: color ?? YonoColors.card,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadows ?? [BoxShadow(
          color: const Color(0xFF0D1B3E).withValues(alpha: 0.06),
          blurRadius: 16, offset: const Offset(0, 4))]),
    child: child,
  );
}

class GradientButton extends StatefulWidget {
  final String label; final VoidCallback? onTap; final List<Color> colors;
  final double height, fontSize; final IconData? icon;
  const GradientButton({super.key, required this.label, required this.onTap,
      this.colors = const [YonoColors.royalBlue, YonoColors.navyBlue],
      this.height = 60, this.fontSize = 18, this.icon});
  @override State<GradientButton> createState() => _GBState();
}
class _GBState extends State<GradientButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return GestureDetector(
      onTapDown: (_) { if (!disabled) _ctrl.forward(); },
      onTapUp:   (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      onTap: () { if (!disabled) { HapticFeedback.mediumImpact(); widget.onTap!(); } },
      child: ScaleTransition(scale: _scale, child: AnimatedContainer(
        duration: const Duration(milliseconds: 180), height: widget.height,
        decoration: BoxDecoration(
          gradient: disabled ? null : LinearGradient(colors: widget.colors),
          color: disabled ? YonoColors.textTertiary : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled ? [] : [BoxShadow(
              color: widget.colors.first.withValues(alpha: 0.32),
              blurRadius: 18, offset: const Offset(0, 7))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: Colors.white, size: 21),
            const SizedBox(width: 9)],
          Text(widget.label, style: YonoTextStyles.body(widget.fontSize,
              color: Colors.white, weight: FontWeight.w700)),
        ]),
      )),
    );
  }
}

class TxnTile extends StatelessWidget {
  final Transaction t; final bool large;
  const TxnTile({super.key, required this.t, this.large = false});
  @override
  Widget build(BuildContext context) {
    final fs = large ? 20.0 : 15.0; final iconSz = large ? 44.0 : 38.0;
    return Row(children: [
      Container(width: iconSz, height: iconSz,
          decoration: BoxDecoration(
              color: t.isDebit ? YonoColors.errorBg : YonoColors.successBg,
              borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(txnEmoji(t.category),
              style: TextStyle(fontSize: large ? 22 : 18)))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.title, style: YonoTextStyles.body(fs, weight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(fmtDate(t.date),
            style: YonoTextStyles.body(12, color: YonoColors.textTertiary)),
      ])),
      Text('${t.isDebit ? '−' : '+'}  ₹${fmt(t.amount)}',
          style: YonoTextStyles.mono(fs,
              color: t.isDebit ? YonoColors.textPrimary : YonoColors.success,
              weight: FontWeight.w700)),
    ]);
  }
}

class SectionHeader extends StatelessWidget {
  final String title; final String? actionLabel; final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title,
      this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: YonoTextStyles.display(18, color: YonoColors.deepBlue)),
        if (actionLabel != null)
          GestureDetector(onTap: onAction,
              child: Text(actionLabel!, style: YonoTextStyles.body(13,
                  color: YonoColors.royalBlue, weight: FontWeight.w600))),
      ]);
}

class _Divider extends StatelessWidget {
  @override Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 20, endIndent: 20, color: YonoColors.divider);
}

class _MenuItem extends StatelessWidget {
  final String emoji, label; final VoidCallback onTap;
  const _MenuItem({required this.emoji, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () { HapticFeedback.lightImpact(); onTap(); },
    borderRadius: BorderRadius.circular(16),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)), const SizedBox(width: 14),
        Expanded(child: Text(label, style: YonoTextStyles.body(15))),
        const Icon(Icons.arrow_forward_ios, size: 13, color: YonoColors.textTertiary),
      ])),
  );
}

Widget profileRow(String label, String value) =>
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: YonoTextStyles.body(14, color: YonoColors.textSecondary)),
      Text(value,  style: YonoTextStyles.mono(14, weight: FontWeight.w600)),
    ]);

class _InputField extends StatelessWidget {
  final TextEditingController ctrl; final String label;
  final IconData icon; final TextInputType keyboardType; final String? prefix;
  const _InputField({required this.ctrl, required this.label,
      required this.icon, required this.keyboardType, this.prefix});
  @override
  Widget build(BuildContext context) => TextField(controller: ctrl,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: YonoTextStyles.body(13, color: YonoColors.textSecondary),
      prefixText: prefix,
      prefixIcon: Icon(icon, size: 18, color: YonoColors.royalBlue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: YonoColors.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: YonoColors.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: YonoColors.royalBlue, width: 1.5))),
  );
}

// ============================================================================
// COLD START SURVEY SHEET
// ============================================================================
class ColdStartSurveySheet extends ConsumerStatefulWidget {
  const ColdStartSurveySheet({super.key});
  @override ConsumerState<ColdStartSurveySheet> createState() =>
      _ColdStartSurveySheetState();
}
class _ColdStartSurveySheetState extends ConsumerState<ColdStartSurveySheet> {
  int? _ageGroup; bool? _prefersHindi;
  bool get _ready => _ageGroup != null && _prefersHindi != null;

  static const _ageOptions = [
    ('🧑‍🎓', '18 – 25', 'Student / Young'),
    ('💼',   '26 – 45', 'Working / Family'),
    ('🏠',   '46 – 60', 'Senior professional'),
    ('🧓',   '60+',     'Retired / Senior'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: YonoColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: YonoColors.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 18),
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: const LinearGradient(
                colors: [YonoColors.royalBlue, YonoColors.navyBlue]),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Quick Setup', style: YonoTextStyles.body(16,
                color: YonoColors.deepBlue, weight: FontWeight.w700)),
            Text('2 questions • 10 seconds',
                style: YonoTextStyles.body(12, color: YonoColors.textSecondary)),
          ])),
        ]),
        const SizedBox(height: 22),
        Align(alignment: Alignment.centerLeft,
          child: Text('How old are you?', style: YonoTextStyles.body(14,
              color: YonoColors.textPrimary, weight: FontWeight.w700))),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: _ageOptions.asMap().entries.map((e) {
          final selected = _ageGroup == e.key;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _ageGroup = e.key); },
            child: AnimatedContainer(duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: selected ? YonoColors.royalBlue : YonoColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? YonoColors.royalBlue : YonoColors.divider)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(e.value.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.value.$2, style: YonoTextStyles.body(13,
                      color: selected ? Colors.white : YonoColors.textPrimary,
                      weight: FontWeight.w700)),
                  Text(e.value.$3, style: YonoTextStyles.body(11,
                      color: selected ? Colors.white60 : YonoColors.textTertiary)),
                ]),
              ])),
          );
        }).toList()),
        const SizedBox(height: 20),
        Align(alignment: Alignment.centerLeft,
          child: Text('Which interface do you prefer?', style: YonoTextStyles.body(14,
              color: YonoColors.textPrimary, weight: FontWeight.w700))),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _prefersHindi = false); },
            child: AnimatedContainer(duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: _prefersHindi == false ? const Color(0xFFEEF2FF) : YonoColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _prefersHindi == false ? YonoColors.royalBlue : YonoColors.divider,
                      width: _prefersHindi == false ? 1.5 : 1)),
              child: Column(children: [
                const Text('🌐', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text('English', style: YonoTextStyles.body(14,
                    color: _prefersHindi == false ? YonoColors.royalBlue : YonoColors.textPrimary,
                    weight: FontWeight.w700)),
                Text('YONO NextGen',
                    style: YonoTextStyles.body(11, color: YonoColors.textTertiary)),
              ]),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _prefersHindi = true); },
            child: AnimatedContainer(duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: _prefersHindi == true ? const Color(0xFFF0FDF4) : YonoColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _prefersHindi == true ? YonoColors.easeForest : YonoColors.divider,
                      width: _prefersHindi == true ? 1.5 : 1)),
              child: Column(children: [
                const Text('🇮🇳', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text('हिन्दी', style: YonoTextStyles.hindi(14,
                    color: _prefersHindi == true ? YonoColors.easeForest : YonoColors.textPrimary,
                    weight: FontWeight.w700)),
                Text('YONO Ease',
                    style: YonoTextStyles.body(11, color: YonoColors.textTertiary)),
              ]),
            ),
          )),
        ]),
        const SizedBox(height: 24),
        GradientButton(
          label: _ready ? 'Continue' : 'Select both options above',
          icon: _ready ? Icons.arrow_forward : null,
          colors: _ready
              ? [YonoColors.royalBlue, YonoColors.navyBlue]
              : [YonoColors.textTertiary, YonoColors.textSecondary],
          height: 56, fontSize: 16,
          onTap: _ready ? () async {
            final answers = ColdStartAnswers(ageGroup: _ageGroup!, prefersHindi: _prefersHindi!);
            final prediction = answers.toSegmentPrediction();
            ref.read(mlPipelineProvider.notifier).setSurveyResult(prediction);
            await Future.delayed(const Duration(milliseconds: 50));
            if (!mounted) return;
            Navigator.pop(context);
          } : null,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Skip — I'll explore myself",
              style: YonoTextStyles.body(12, color: YonoColors.textTertiary)),
        ),
      ]),
    );
  }
}

// ============================================================================
// ML-AWARE LOGIN SCREEN V2 (Cold Start + ML Pipeline)
// ============================================================================
class MLAwareLoginScreenV2 extends ConsumerStatefulWidget {
  const MLAwareLoginScreenV2({super.key});
  @override ConsumerState<MLAwareLoginScreenV2> createState() =>
      _MLAwareLoginScreenV2State();
}
class _MLAwareLoginScreenV2State extends ConsumerState<MLAwareLoginScreenV2> {
  @override
  Widget build(BuildContext context) {
    ref.listen<CustomerProfile?>(authProvider, (prev, next) async {
      if (prev == null && next != null) {
        if (needsColdStart(next)) {
          await Future.microtask(() {});
          if (!mounted) return;
          await showModalBottomSheet(
            context: context, isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom),
              child: const ColdStartSurveySheet()));
          if (!mounted) return;
          context.go('/portal');
        } else {
          ref.read(mlPipelineProvider.notifier).runPipeline(next);
          if (!mounted) return;
          context.go('/portal');
        }
      }
      if (prev != null && next == null) {
        ref.read(mlPipelineProvider.notifier).reset();
        ref.read(quickUsageProvider.notifier).reset();
        await clearSecureData();
      }
    });
    return const LoginScreen();
  }
}

// ============================================================================
// LOGIN SCREEN
// ============================================================================
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override ConsumerState<LoginScreen> createState() => _LoginState();
}
class _LoginState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  String _pin = ''; bool _loading = false; String? _error;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
  }
  @override void dispose() { _userCtrl.dispose(); _shakeCtrl.dispose(); super.dispose(); }

  void _onKey(String v) {
    if (_pin.length < 6) setState(() { _pin += v; _error = null; });
  }
  void _onDel() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _login() async {
    if (_pin.length < 6) {
      setState(() => _error = 'Enter complete 6-digit MPIN');
      _shakeCtrl.forward(from: 0); return;
    }
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 900));
    final ok = ref.read(authProvider.notifier).login(_userCtrl.text.trim(), _pin);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) { HapticFeedback.heavyImpact(); }
    // Navigation handled by MLAwareLoginScreenV2 ref.listen after pipeline runs
    else {
      final locked = _loginAttempts >= 5;
      setState(() {
        _error = locked
            ? 'Too many attempts. Restart the app.'
            : 'Incorrect User ID or MPIN. (${5 - _loginAttempts} attempts left)';
        _pin = '';
      });
      _shakeCtrl.forward(from: 0); HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(children: [
      Container(decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF060D20), Color(0xFF0D1B3E), Color(0xFF1A2F6B)]))),
      Positioned(top: -80,   right: -60, child: _Blob(240, YonoColors.royalBlue.withValues(alpha: 0.12))),
      Positioned(bottom: 80, left: -80,  child: _Blob(280, YonoColors.cyan.withValues(alpha: 0.08))),
      Positioned(top: 200,   left: 40,   child: _Blob(60,  YonoColors.gold.withValues(alpha: 0.15))),
      SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(children: [
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
            child: const Icon(Icons.account_balance, color: Colors.white, size: 38)),
          const SizedBox(height: 14),
          Text('yono SBI', style: YonoTextStyles.display(44, color: Colors.white)),
          Text('You Only Need One',
              style: YonoTextStyles.body(14, color: Colors.white38)),
          const SizedBox(height: 40),
          ClipRRect(borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.13))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Secure Login',
                      style: YonoTextStyles.display(22, color: Colors.white)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Demo Accounts', style: YonoTextStyles.body(11,
                          color: Colors.white60, weight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      _DemoHint('aryan',  '123456', 'NextGen • Cold Start'),
                      _DemoHint('priya',  '234567', 'NextGen • High Confidence'),
                      _DemoHint('kavya',  '345678', 'NextGen • Student'),
                      _DemoHint('ashok',  '567890', 'Ease • Pension'),
                      _DemoHint('ramesh', '678901', 'Ease • Farmer'),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  TextField(controller: _userCtrl,
                    style: YonoTextStyles.body(16, color: Colors.white),
                    decoration: InputDecoration(labelText: 'User ID',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.person_outline,
                          color: Colors.white38, size: 20),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: YonoColors.cyan, width: 1.5),
                          borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05))),
                  const SizedBox(height: 24),
                  Text('MPIN', style: YonoTextStyles.body(13, color: Colors.white60)),
                  const SizedBox(height: 12),
                  AnimatedBuilder(animation: _shakeAnim, builder: (_, child) =>
                      Transform.translate(
                          offset: Offset(sin(_shakeAnim.value * pi * 6) * 8, 0),
                          child: child),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (i) {
                        final filled = i < _pin.length;
                        return Container(margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 14, height: 14,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                              color: filled ? YonoColors.cyan : Colors.transparent,
                              border: Border.all(
                                  color: filled ? YonoColors.cyan : Colors.white30,
                                  width: 2)));
                      }))),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Center(child: Text(_error!,
                        style: YonoTextStyles.body(13, color: const Color(0xFFFF6B6B)))),
                  ],
                  const SizedBox(height: 24),
                  _NumPad(onKey: _onKey, onDelete: _onDel,
                      onSubmit: _loading ? null : _login),
                  const SizedBox(height: 20),
                  _loading
                      ? const Center(child: CircularProgressIndicator(
                          color: YonoColors.cyan, strokeWidth: 2))
                      : GradientButton(label: 'Login Securely', onTap: _login,
                          colors: const [YonoColors.cyan, YonoColors.royalBlue],
                          icon: Icons.lock_open_outlined),
                  const SizedBox(height: 14),
                  Center(child: Text('256-bit AES encrypted  •  Secure MPIN',
                      style: YonoTextStyles.body(12, color: Colors.white24))),
                ])))),
          const SizedBox(height: 28),
          Text('Protected by 256-bit SSL\n© State Bank of India',
              textAlign: TextAlign.center,
              style: YonoTextStyles.body(12,
                  color: Colors.white.withValues(alpha: 0.18))),
        ]),
      )),
    ]),
  );
}

class _DemoHint extends StatelessWidget {
  final String user, pin, label;
  const _DemoHint(this.user, this.pin, this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(children: [
      SizedBox(width: 58, child: Text(user,
          style: YonoTextStyles.mono(11,
              color: Colors.white70, weight: FontWeight.w700))),
      Text(pin, style: YonoTextStyles.mono(11, color: YonoColors.cyan)),
      const SizedBox(width: 8),
      Text('• $label', style: YonoTextStyles.body(10, color: Colors.white38)),
    ]),
  );
}

class _Blob extends StatelessWidget {
  final double size; final Color color;
  const _Blob(this.size, this.color);
  @override Widget build(BuildContext context) => Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _NumPad extends StatelessWidget {
  final void Function(String) onKey;
  final VoidCallback onDelete;
  final VoidCallback? onSubmit;
  const _NumPad({required this.onKey, required this.onDelete, this.onSubmit});
  @override
  Widget build(BuildContext context) {
    final rows = [['1','2','3'],['4','5','6'],['7','8','9'],['','0','⌫']];
    return Column(children: rows.map((row) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((k) {
        if (k.isEmpty) return const SizedBox(width: 72);
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick();
              k == '⌫' ? onDelete() : onKey(k); },
          child: Container(width: 72, height: 52,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10))),
            child: Center(child: k == '⌫'
                ? const Icon(Icons.backspace_outlined, color: Colors.white60, size: 20)
                : Text(k, style: YonoTextStyles.mono(22,
                    color: Colors.white, weight: FontWeight.w500)))),
        );
      }).toList()))).toList());
  }
}

// ============================================================================
// SMART PORTAL SCREEN (ML Recommendation + Manual Selection)
// ============================================================================
class SmartPortalScreen extends ConsumerWidget {
  const SmartPortalScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final prediction = ref.watch(mlPipelineProvider);
    if (user == null) return const SizedBox.shrink();
    if (prediction == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (needsColdStart(user)) {
          final fallback = ColdStartAnswers(
            ageGroup: 0,
            prefersHindi: false,
          ).toSegmentPrediction();
          ref.read(mlPipelineProvider.notifier).setSurveyResult(fallback);
        } else {
          ref.read(mlPipelineProvider.notifier).runPipeline(user);
        }
      });
    }
    return Scaffold(
      backgroundColor: YonoColors.deepBlue,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF060D20), Color(0xFF0D1B3E)])),
        child: SafeArea(bottom: false, child: Column(children: [
          Padding(padding: const EdgeInsets.all(24), child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(timeGreeting(),
                    style: YonoTextStyles.body(13, color: Colors.white38)),
                // Double-tap = demo trigger
                GestureDetector(
                  onDoubleTap: () async {
                    HapticFeedback.heavyImpact();
                    ref.read(authProvider.notifier).triggerDemoHotState();
                    ref.read(mlPipelineProvider.notifier).reset(); // force re-run
                    await ref.read(mlPipelineProvider.notifier)
                        .runPipeline(ref.read(authProvider)!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('🚀 Demo State Injected! ML Refreshed.'),
                          backgroundColor: YonoColors.success,
                          duration: Duration(seconds: 2)));
                    }
                  },
                  child: Text('${user.name.split(' ')[0]} 👋',
                      style: YonoTextStyles.display(30, color: Colors.white)),
                ),
              ]),
              GestureDetector(
                onTap: () { ref.read(authProvider.notifier).logout(); context.go('/login'); },
                child: Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
                  child: const Icon(Icons.power_settings_new,
                      color: Colors.white70, size: 20)),
              ),
            ])),
          Expanded(child: Container(
            width: double.infinity, padding: const EdgeInsets.only(top: 24),
            decoration: const BoxDecoration(color: YonoColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            child: SingleChildScrollView(child: Column(children: [
              const SmartRouteCard(),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Row(children: [
                  const Expanded(child: Divider(color: YonoColors.divider)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or choose manually',
                          style: YonoTextStyles.body(12, color: YonoColors.textTertiary))),
                  const Expanded(child: Divider(color: YonoColors.divider)),
                ])),
              const SizedBox(height: 16),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  _buildManualCard(context, 'YONO NextGen',
                      'Smart banking for the digital generation',
                      Icons.auto_awesome,
                      const [Color(0xFF3B2FC9), Color(0xFF6D28D9)], '/nextgen'),
                  const SizedBox(height: 14),
                  _buildManualCard(context, 'YONO Ease',
                      'सरल, सुरक्षित और सुगम बैंकिंग अनुभव',
                      Icons.eco_outlined,
                      [YonoColors.easeForest, const Color(0xFF14532D)], '/ease'),
                  const SizedBox(height: 40),
                ])),
            ])),
          )),
        ])),
      ),
    );
  }

  Widget _buildManualCard(BuildContext ctx, String title, String sub,
      IconData icon, List<Color> grad, String route) =>
      GestureDetector(
        onTap: () { HapticFeedback.mediumImpact(); ctx.go(route); },
        child: Container(padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(gradient: LinearGradient(colors: grad,
              begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: grad.first.withValues(alpha: 0.35),
                  blurRadius: 20, offset: const Offset(0, 8))]),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 26)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: YonoTextStyles.display(17, color: Colors.white)),
              const SizedBox(height: 3),
              Text(sub, style: YonoTextStyles.body(13, color: Colors.white60)),
            ])),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 15),
          ])),
      );
}

// ── Warming banner ────────────────────────────────────────────────────────────
class WarmingBanner extends StatelessWidget {
  final int txnCount;
  const WarmingBanner({super.key, required this.txnCount});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: YonoColors.warningBg,
        borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.show_chart, color: YonoColors.warning, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(
          'Warming up AI... ($txnCount/$kWarmThreshold txns)',
          style: YonoTextStyles.body(12,
              color: YonoColors.warning, weight: FontWeight.w700))),
    ]),
  );
}

// ── Smart Route Card ──────────────────────────────────────────────────────────
class SmartRouteCard extends ConsumerWidget {
  const SmartRouteCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = ref.watch(mlPipelineProvider);
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink();
    if (prediction == null) return const _PipelineLoadingCard();
    final isNG  = prediction.recommended == CustomerSegment.nextgen;
    final pct   = (prediction.confidence * 100).toInt();
    final color = isNG ? YonoColors.royalBlue : YonoColors.easeForest;
    final grad  = isNG
        ? [const Color(0xFF3B2FC9), const Color(0xFF2244A8)]
        : [YonoColors.easeForest, const Color(0xFF14532D)];

    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(gradient: LinearGradient(colors: grad),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          Text('AI Smart Route', style: YonoTextStyles.body(14,
              color: YonoColors.deepBlue, weight: FontWeight.w700)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('$pct% match', style: YonoTextStyles.mono(12,
                  color: color, weight: FontWeight.w700))),
        ]),
        const SizedBox(height: 12),
        // Warming banner when we have some but not enough transactions
        if (user.transactions.isNotEmpty && user.transactions.length < kWarmThreshold) ...[
          WarmingBanner(txnCount: user.transactions.length),
          const SizedBox(height: 12),
        ],
        Container(padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                grad[0].withValues(alpha: 0.08), grad[1].withValues(alpha: 0.03)]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(prediction.headline, style: YonoTextStyles.body(15,
                color: YonoColors.deepBlue, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: prediction.confidence,
                    backgroundColor: YonoColors.divider, color: color, minHeight: 5))),
              const SizedBox(width: 10),
              Text('$pct%', style: YonoTextStyles.mono(12,
                  color: color, weight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            ...prediction.signals.take(3).map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check_circle_outline, size: 14, color: color),
                const SizedBox(width: 7),
                Expanded(child: Text(s, style: YonoTextStyles.body(12,
                    color: YonoColors.textSecondary))),
              ]))),
            const SizedBox(height: 14),
            GradientButton(
                label: isNG ? 'Go to NextGen  →' : 'YONO Ease पर जाएं  →',
                colors: grad, height: 46, fontSize: 14, icon: Icons.bolt,
                onTap: () { HapticFeedback.mediumImpact();
                    context.go(isNG ? '/nextgen' : '/ease'); }),
            const SizedBox(height: 8),
            Center(child: TextButton(onPressed: () => context.go(isNG ? '/ease' : '/nextgen'),
              child: Text(isNG ? 'Or continue to YONO Ease instead'
                  : 'Or switch to YONO NextGen instead',
                  style: YonoTextStyles.body(12, color: YonoColors.textTertiary)))),
          ])),
        const SizedBox(height: 8),
        Center(child: Text('AI suggestion only • You can always switch dashboards',
            style: YonoTextStyles.body(11, color: YonoColors.textTertiary))),
        const SizedBox(height: 20),
      ]));
  }
}

class _PipelineLoadingCard extends StatefulWidget {
  const _PipelineLoadingCard();
  @override State<_PipelineLoadingCard> createState() => _PLCState();
}
class _PLCState extends State<_PipelineLoadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl; late Animation<double> _fade; int _step = 0;
  final _steps = ['Analysing transaction patterns…','Evaluating spending behaviour…',
                  'Running segment classifier…','Preparing your smart route…'];
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true); _rotateStep();
  }
  void _rotateStep() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _step = (_step + 1) % _steps.length);
    }
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: YonoColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: YonoColors.divider),
          boxShadow: [BoxShadow(color: YonoColors.deepBlue.withValues(alpha: 0.05),
              blurRadius: 16, offset: const Offset(0, 4))]),
      child: Row(children: [
        Container(width: 44, height: 44,
            decoration: BoxDecoration(gradient: const LinearGradient(
                colors: [YonoColors.royalBlue, YonoColors.navyBlue]),
                borderRadius: BorderRadius.circular(12)),
            child: const Center(child: SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: YonoColors.royalBlue, size: 14),
            const SizedBox(width: 5),
            Text('AI Smart Route', style: YonoTextStyles.body(13,
                color: YonoColors.royalBlue, weight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          FadeTransition(opacity: _fade,
              child: Text(_steps[_step], style: YonoTextStyles.body(12,
                  color: YonoColors.textSecondary))),
        ])),
      ])),
  );
}

// ============================================================================
// ANIMATED SUCCESS SCREEN
// ============================================================================
class AnimatedSuccessScreen extends StatefulWidget {
  final String title, subtitle, returnRoute; final bool isHindi;
  const AnimatedSuccessScreen({super.key, required this.title,
      required this.subtitle, required this.returnRoute, required this.isHindi});
  @override State<AnimatedSuccessScreen> createState() => _ASSState();
}
class _ASSState extends State<AnimatedSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _circleCtrl, _contentCtrl;
  late Animation<double> _circleScale, _circleFade, _contentSlide, _contentFade;
  @override void initState() {
    super.initState();
    _circleCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _circleScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _circleCtrl, curve: Curves.elasticOut));
    _circleFade  = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _circleCtrl, curve: const Interval(0, 0.4)));
    _contentSlide = Tween<double>(begin: 30, end: 0)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));
    _contentFade  = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeIn));
    HapticFeedback.heavyImpact();
    _circleCtrl.forward().then((_) => _contentCtrl.forward());
  }
  @override void dispose() { _circleCtrl.dispose(); _contentCtrl.dispose(); super.dispose(); }
  Color get _accent => widget.isHindi ? YonoColors.easeForest : YonoColors.royalBlue;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: YonoColors.surface,
    body: SafeArea(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Spacer(),
        AnimatedBuilder(animation: _circleCtrl,
          builder: (_, child) => Opacity(opacity: _circleFade.value,
              child: Transform.scale(scale: _circleScale.value, child: child)),
          child: AccessibleSuccessCircle(accentColor: _accent, isHindi: widget.isHindi)),
        const SizedBox(height: 36),
        AnimatedBuilder(animation: _contentCtrl,
          builder: (_, child) => Opacity(opacity: _contentFade.value,
              child: Transform.translate(
                  offset: Offset(0, _contentSlide.value), child: child)),
          child: Column(children: [
            Text(widget.title, style: YonoTextStyles.display(28,
                color: YonoColors.deepBlue), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(widget.subtitle, style: YonoTextStyles.body(16,
                color: YonoColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(color: YonoColors.successBg,
                  borderRadius: BorderRadius.circular(12)),
              child: Text(widget.isHindi ? 'लेनदेन सफल रहा' : 'Transaction Successful',
                  style: YonoTextStyles.body(13,
                      color: YonoColors.success, weight: FontWeight.w600))),
          ])),
        const Spacer(),
        AnimatedBuilder(animation: _contentCtrl,
          builder: (_, child) => Opacity(opacity: _contentFade.value, child: child),
          child: Column(children: [
            YonoCard(color: YonoColors.surface, child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(widget.isHindi ? 'संदर्भ संख्या' : 'Reference No.',
                    style: YonoTextStyles.body(13, color: YonoColors.textSecondary)),
                Text(YonoUUID.shortRef(), style: YonoTextStyles.mono(13,
                    color: YonoColors.deepBlue, weight: FontWeight.w700)),
              ])),
            const SizedBox(height: 20),
            GradientButton(
              label: widget.isHindi ? 'होम पर जाएं' : 'Back to Home',
              icon: Icons.home_outlined,
              colors: widget.isHindi
                  ? [YonoColors.easeForest, const Color(0xFF14532D)]
                  : [YonoColors.royalBlue, YonoColors.navyBlue],
              onTap: () => context.go(widget.returnRoute),
              height: 58, fontSize: 17),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(widget.isHindi
                      ? 'रसीद ईमेल पर भेजी गई'
                      : 'Receipt sent to your registered email.'),
                  backgroundColor: YonoColors.success)),
              child: Text(widget.isHindi ? 'रसीद डाउनलोड करें' : 'Download Receipt',
                  style: YonoTextStyles.body(14, color: _accent, weight: FontWeight.w600))),
          ])),
      ]))),
  );
}

// ============================================================================
// YONO QUICK FAB
// ============================================================================
class YonoQuickFAB extends ConsumerStatefulWidget {
  final bool isNextGen;
  const YonoQuickFAB({super.key, required this.isNextGen});
  @override ConsumerState<YonoQuickFAB> createState() => _YQFABState();
}
class _YQFABState extends ConsumerState<YonoQuickFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotate, _scale;
  bool _open = false;

  @override void initState() {
    super.initState();
    _ctrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _rotate = Tween<double>(begin: 0, end: 0.375)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scale  = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  Color get _fabColor =>
      widget.isNextGen ? YonoColors.royalBlue : YonoColors.easeForest;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      ScaleTransition(scale: _scale, alignment: Alignment.bottomRight,
        child: FadeTransition(opacity: _scale,
          child: _open ? _YQSheet(isNextGen: widget.isNextGen, onClose: _toggle)
              : const SizedBox.shrink())),
      const SizedBox(height: 12),
      GestureDetector(onTap: _toggle,
        child: AnimatedBuilder(animation: _rotate,
          builder: (_, child) => Transform.rotate(
              angle: _rotate.value * 2 * math.pi, child: child),
          child: Container(width: 58, height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.isNextGen
                  ? [YonoColors.royalBlue, YonoColors.navyBlue]
                  : [YonoColors.easeForest, const Color(0xFF14532D)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _fabColor.withValues(alpha: 0.4),
                  blurRadius: 20, offset: const Offset(0, 8))]),
            child: Icon(_open ? Icons.close : Icons.flash_on,
                color: Colors.white, size: 26)))),
    ]);
}

class _YQSheet extends ConsumerWidget {
  final bool isNextGen; final VoidCallback onClose;
  const _YQSheet({required this.isNextGen, required this.onClose});

  List<QuickAction> get _all => isNextGen ? _ngActions : _easeActions;

  List<_PendingBill> _bills(CustomerProfile u) {
    final bills = <_PendingBill>[];
    final now   = DateTime.now();
    final lastPaid = <String, DateTime>{};
    for (final b in u.billPayments) {
      if (!lastPaid.containsKey(b.category) ||
          b.date.isAfter(lastPaid[b.category]!)) {
        lastPaid[b.category] = b.date;
      }
    }
    final defs = {'Electricity': ('⚡','Electricity Bill'),
                  'Mobile': ('📱','Mobile Recharge'),
                  'Utility': ('💧','Water/Gas Bill')};
    for (final e in lastPaid.entries) {
      final days = now.difference(e.value).inDays;
      if (days >= 25) {
        final d = defs[e.key];
        if (d != null) {
          bills.add(_PendingBill(emoji: d.$1, label: d.$2,
            dueIn: math.max(0, 30 - days), isOverdue: 30 - days <= 0));
        }
      }
    }
    if (bills.isEmpty) {
      bills.add(_PendingBill(emoji: '⚡',
          label: u.segment == CustomerSegment.ease ? 'बिजली बिल (UPPCL)' : 'Electricity Bill',
          dueIn: 3, isOverdue: false));
      bills.add(_PendingBill(emoji: '📱',
          label: u.segment == CustomerSegment.ease ? 'मोबाइल रिचार्ज' : 'Mobile Recharge',
          dueIn: 7, isOverdue: false));
    }
    return bills.take(2).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user  = ref.watch(authProvider)!;
    final usage = ref.watch(quickUsageProvider);
    final sorted = [..._all]..sort((a,b) =>
        (usage[b.id] ?? 0).compareTo(usage[a.id] ?? 0));
    final top3  = sorted.take(3).toList();
    final bills = _bills(user);
    final accent = isNextGen ? YonoColors.royalBlue : YonoColors.easeForest;
    final grad   = isNextGen
        ? [YonoColors.royalBlue, YonoColors.navyBlue]
        : [YonoColors.easeForest, const Color(0xFF14532D)];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300, minWidth: 240),
      child: Container(
      decoration: BoxDecoration(color: YonoColors.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: YonoColors.deepBlue.withValues(alpha: 0.15),
              blurRadius: 32, offset: const Offset(0, 8))]),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.fromLTRB(16,14,16,12),
          decoration: BoxDecoration(gradient: LinearGradient(colors: grad),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
          child: Row(children: [
            const Icon(Icons.flash_on, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('YONO Quick', style: YonoTextStyles.body(15,
                color: Colors.white, weight: FontWeight.w700)),
            const Spacer(),
            Text(isNextGen ? 'Personalised' : 'व्यक्तिगत',
                style: YonoTextStyles.body(11, color: Colors.white60)),
          ])),
        Padding(padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.touch_app_outlined, size: 14, color: accent),
              const SizedBox(width: 5),
              Text(isNextGen ? 'Your most-used actions' : 'आपके सबसे उपयोगी बटन',
                  style: YonoTextStyles.body(12,
                      color: YonoColors.textSecondary, weight: FontWeight.w600)),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: top3.map((a) => _QChip(action: a,
                  tapCount: usage[a.id] ?? 0, accent: accent, onTap: () {
                ref.read(quickUsageProvider.notifier).recordTap(a.id);
                onClose(); context.go(a.route);
              })).toList()),
            if (bills.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(color: YonoColors.divider, height: 1),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.notifications_active_outlined,
                    size: 14, color: YonoColors.warning),
                const SizedBox(width: 5),
                Text(isNextGen ? 'Bill Reminders' : 'बिल रिमाइंडर',
                    style: YonoTextStyles.body(12,
                        color: YonoColors.textSecondary, weight: FontWeight.w600)),
              ]),
              const SizedBox(height: 10),
              ...bills.map((b) => _BillTile(bill: b, isNextGen: isNextGen,
                  accent: accent, onPay: () {
                onClose();
                context.go(isNextGen ? '/nextgen/pay-bills' : '/ease/send-money');
              })),
            ],
            const SizedBox(height: 4),
          ])),
      ])),
    );
  }
}

class _PendingBill {
  final String emoji, label; final int dueIn; final bool isOverdue;
  const _PendingBill({required this.emoji, required this.label,
      required this.dueIn, required this.isOverdue});
}

class _QChip extends StatelessWidget {
  final QuickAction action; final int tapCount;
  final Color accent; final VoidCallback onTap;
  const _QChip({required this.action, required this.tapCount,
      required this.accent, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: 80, padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.15))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(action.emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 5),
        Text(action.label, style: YonoTextStyles.body(10, weight: FontWeight.w600),
            textAlign: TextAlign.center, maxLines: 2),
        if (tapCount > 0) ...[
          const SizedBox(height: 3),
          Text('×$tapCount', style: YonoTextStyles.mono(10,
              color: accent, weight: FontWeight.w700)),
        ],
      ])));
}

class _BillTile extends StatelessWidget {
  final _PendingBill bill; final bool isNextGen;
  final Color accent; final VoidCallback onPay;
  const _BillTile({required this.bill, required this.isNextGen,
      required this.accent, required this.onPay});
  @override
  Widget build(BuildContext context) {
    final urgColor = bill.isOverdue ? YonoColors.error : YonoColors.warning;
    final urgBg    = bill.isOverdue ? YonoColors.errorBg : YonoColors.warningBg;
    final dueLabel = bill.isOverdue
        ? (isNextGen ? 'Overdue!' : 'अतिदेय!')
        : (isNextGen ? 'Due in ${bill.dueIn}d' : '${bill.dueIn} दिन में');
    return Padding(padding: const EdgeInsets.only(bottom: 8),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: urgBg.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: urgColor.withValues(alpha: 0.25))),
        child: Row(children: [
          Text(bill.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(bill.label, style: YonoTextStyles.body(12, weight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Container(margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: urgColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(dueLabel, style: YonoTextStyles.body(10,
                  color: urgColor, weight: FontWeight.w700))),
          ])),
          GestureDetector(onTap: onPay, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: accent,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(isNextGen ? 'Pay' : 'भुगतान', style: YonoTextStyles.body(11,
                  color: Colors.white, weight: FontWeight.w700)))),
        ])));
  }
}

// ============================================================================
// NEXTGEN SHELL
// ============================================================================
class NextGenShell extends ConsumerStatefulWidget {
  const NextGenShell({super.key});
  @override ConsumerState<NextGenShell> createState() => _NGShellState();
}
class _NGShellState extends ConsumerState<NextGenShell> {
  int _idx = 0;
  @override
  Widget build(BuildContext context) {
    final user  = ref.watch(authProvider)!;
    final pages = [_NextGenHome(user: user, onSeeAll: () => setState(() => _idx = 2)), _NextGenWealth(user: user),
                   _NextGenTransactions(user: user), _NextGenProfile(user: user)];
    return Scaffold(
      backgroundColor: YonoColors.surface,
      appBar: AppBar(
        backgroundColor: YonoColors.deepBlue, elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: () => context.go('/portal')),
        title: Row(children: [
          const Icon(Icons.auto_awesome, color: YonoColors.cyan, size: 18),
          const SizedBox(width: 8),
          Text('YONO NextGen', style: YonoTextStyles.body(18,
              color: Colors.white, weight: FontWeight.w700)),
        ]),
        actions: [
          Stack(children: [
            IconButton(icon: const Icon(Icons.notifications_outlined,
                color: Colors.white70, size: 24),
                onPressed: () => context.go('/nextgen/notifications')),
            if (user.unreadCount > 0) Positioned(top: 10, right: 10,
                child: Container(width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: YonoColors.error, shape: BoxShape.circle))),
          ]),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white38, size: 20),
              onPressed: () { ref.read(authProvider.notifier).logout();
                context.go('/login'); }),
        ],
      ),
      body: IndexedStack(index: _idx, children: pages),
      floatingActionButton: const Padding(
        padding: EdgeInsets.only(bottom: 8, right: 4),
        child: YonoQuickFAB(isNextGen: true)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white, elevation: 0, height: 68,
        indicatorColor: YonoColors.cyan.withValues(alpha: 0.14),
        selectedIndex: _idx,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick(); setState(() => _idx = i);},
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: YonoColors.cyan), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.trending_up_outlined),
              selectedIcon: Icon(Icons.trending_up, color: YonoColors.cyan), label: 'Wealth'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long, color: YonoColors.cyan), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: YonoColors.cyan), label: 'Profile'),
        ],
      ),
    );
  }
}

// ---- NextGen Home ----
class _NextGenHome extends ConsumerWidget {
  final CustomerProfile user;
  final VoidCallback? onSeeAll;
  const _NextGenHome({required this.user, this.onSeeAll});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${timeGreeting()},', style: YonoTextStyles.body(14,
                color: YonoColors.textSecondary)),
            Text('${user.name.split(' ')[0]} 👋',
                style: YonoTextStyles.display(28, color: YonoColors.deepBlue)),
          ]),
          GestureDetector(onTap: () => context.go('/nextgen/rewards'),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: YonoColors.goldLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: YonoColors.gold.withValues(alpha: 0.4))),
              child: Row(children: [
                const Icon(Icons.star, color: YonoColors.gold, size: 14),
                const SizedBox(width: 4),
                Text('${user.rewardPoints} pts', style: YonoTextStyles.body(12,
                    color: YonoColors.warning, weight: FontWeight.w700)),
              ]))),
        ]),
        const SizedBox(height: 22),
        // Hero balance card
        Container(padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B3E), Color(0xFF1A2F6B), Color(0xFF2244A8)]),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: YonoColors.deepBlue.withValues(alpha: 0.4),
                blurRadius: 30, offset: const Offset(0, 12))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Savings Account', style: YonoTextStyles.body(12, color: Colors.white38)),
                Text(user.accountNumber, style: YonoTextStyles.body(12, color: Colors.white24)),
              ]),
              Row(children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(
                    color: YonoColors.success, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('Active', style: YonoTextStyles.body(11, color: Colors.white60)),
                const SizedBox(width: 12),
                GestureDetector(onTap: () => ref.read(authProvider.notifier).toggleBalance(),
                    child: Icon(user.balanceHidden
                        ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white54, size: 20)),
              ]),
            ]),
            const SizedBox(height: 18),
            Text('Available Balance', style: YonoTextStyles.body(11, color: Colors.white38)),
            const SizedBox(height: 4),
            user.balanceHidden
                ? Container(height: 44, width: 180, margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text('••••••',
                        style: TextStyle(color: Colors.white38, fontSize: 24, letterSpacing: 6))))
                : Text('₹ ${fmt(user.accountBalance)}',
                    style: YonoTextStyles.mono(40, color: Colors.white, weight: FontWeight.w800)),
            const SizedBox(height: 20),
            Row(children: [
              _StatChip('↑ ${fmtShort(user.monthlyCredit)}', 'In', Colors.greenAccent),
              const SizedBox(width: 10),
              _StatChip('↓ ${fmtShort(user.monthlyDebit)}', 'Out', Colors.redAccent),
              const SizedBox(width: 10),
              if (user.creditScore > 0)
                _StatChip('${user.creditScore}', 'Score', YonoColors.gold),
            ]),
          ])),
        const SizedBox(height: 22),
        GestureDetector(onTap: () => context.go('/nextgen/analytics'),
          child: YonoCard(color: YonoColors.goldLight, child: Row(children: [
            const Text('💡', style: TextStyle(fontSize: 26)), const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Smart Insight  •  Tap for full analytics',
                  style: YonoTextStyles.body(11, color: YonoColors.warning, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text('Spent ₹${fmt(user.monthlyDebit)} this month. '
                   'Invest ₹5,000 → earn ₹355 guaranteed.',
                  style: YonoTextStyles.body(13)),
            ])),
            const Icon(Icons.arrow_forward_ios, size: 13, color: YonoColors.warning),
          ]))),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _QuickBtn(emoji: '📷', label: 'Scan & Pay',
              onTap: () => context.go('/nextgen/scan-pay')),
          _QuickBtn(emoji: '💸', label: 'Send Money',
              onTap: () => context.go('/nextgen/send-money')),
          _QuickBtn(emoji: '📄', label: 'Pay Bills',
              onTap: () => context.go('/nextgen/pay-bills')),
          _QuickBtn(emoji: '🏦', label: 'Loan EMI',
              onTap: () => context.go('/nextgen/loan-calc')),
        ]),
        const SizedBox(height: 24),
        GestureDetector(onTap: () => context.go('/nextgen/loan-calc'),
          child: Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(
                colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SBI Personal Loan',
                    style: YonoTextStyles.display(16, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Up to ₹20L  •  10.5% p.a.  •  Instant approval',
                    style: YonoTextStyles.body(13, color: Colors.white70)),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('Calculate EMI', style: YonoTextStyles.body(13,
                      color: const Color(0xFF4F46E5), weight: FontWeight.w700))),
              ])),
              const Text('💰', style: TextStyle(fontSize: 52)),
            ]))),
        const SizedBox(height: 24),
        SectionHeader(title: 'Recent Activity', actionLabel: 'See All', onAction: onSeeAll),
        const SizedBox(height: 12),
        user.transactions.isEmpty
            ? YonoCard(child: Column(children: [
                const Text('🔍', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 10),
                Text('No transactions yet',
                    style: YonoTextStyles.body(14, color: YonoColors.textSecondary))]))
            : YonoCard(padding: EdgeInsets.zero, child: Column(
                children: user.transactions.take(3).toList().asMap().entries.map((e) =>
                  Column(children: [
                    Padding(padding: const EdgeInsets.all(16),
                        child: TxnTile(t: e.value)),
                    if (e.key < 2) const Divider(height: 1,
                        color: YonoColors.divider, indent: 16, endIndent: 16),
                  ])).toList())),
        const SizedBox(height: 24),
      ]));
  }
}

class _StatChip extends StatelessWidget {
  final String val, label; final Color color;
  const _StatChip(this.val, this.label, this.color);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(val, style: YonoTextStyles.mono(13, color: color, weight: FontWeight.w700)),
      Text(label, style: YonoTextStyles.body(10, color: Colors.white54)),
    ]));
}

class _QuickBtn extends StatelessWidget {
  final String emoji, label; final VoidCallback onTap;
  const _QuickBtn({required this.emoji, required this.label, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: () { HapticFeedback.lightImpact(); onTap(); },
    child: Column(children: [
      YonoCard(padding: const EdgeInsets.all(16), radius: 18,
        shadows: [BoxShadow(color: YonoColors.deepBlue.withValues(alpha: 0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
        child: Text(emoji, style: const TextStyle(fontSize: 26))),
      const SizedBox(height: 7),
      Text(label, style: YonoTextStyles.body(11,
          color: YonoColors.textSecondary, weight: FontWeight.w500),
          textAlign: TextAlign.center),
    ]));
}

// ---- NextGen Wealth ----
class _NextGenWealth extends StatelessWidget {
  final CustomerProfile user; const _NextGenWealth({required this.user});
  @override Widget build(BuildContext context) {
    final totalFD  = user.totalFDValue;
    final totalMat = user.activeFDs.fold<double>(0, (s, fd) => s + fd.maturityAmount);
    return SingleChildScrollView(padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('My Wealth', style: YonoTextStyles.display(26, color: YonoColors.deepBlue)),
        Text('Grow. Protect. Prosper.',
            style: YonoTextStyles.body(14, color: YonoColors.textSecondary)),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: YonoCard(padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('FD Invested', style: YonoTextStyles.body(12, color: YonoColors.textSecondary)),
              const SizedBox(height: 5),
              Text('₹${fmtShort(totalFD)}', style: YonoTextStyles.mono(22,
                  color: YonoColors.deepBlue, weight: FontWeight.w800)),
            ]))),
          const SizedBox(width: 12),
          Expanded(child: YonoCard(padding: const EdgeInsets.all(18), color: YonoColors.successBg,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Gains', style: YonoTextStyles.body(12, color: YonoColors.success)),
              const SizedBox(height: 5),
              Text('+₹${fmtShort(totalMat - totalFD)}', style: YonoTextStyles.mono(22,
                  color: YonoColors.success, weight: FontWeight.w800)),
            ]))),
        ]),
        const SizedBox(height: 22),
        GestureDetector(onTap: () { HapticFeedback.mediumImpact(); context.go('/nextgen/fd-create'); },
          child: Container(padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                    blurRadius: 20, offset: const Offset(0, 8))]),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.rocket_launch, color: Colors.white, size: 26)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Create Smart FD', style: YonoTextStyles.display(17, color: Colors.white)),
                Text('Up to 7.1% p.a.  •  Starts ₹5,000',
                    style: YonoTextStyles.body(13, color: Colors.white60)),
              ])),
              const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
            ]))),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Active Investments'),
        const SizedBox(height: 14),
        if (user.activeFDs.isEmpty)
          YonoCard(child: Column(children: [
            const Text('📈', style: TextStyle(fontSize: 48)), const SizedBox(height: 10),
            Text('No FDs yet — start growing today',
                style: YonoTextStyles.body(14, color: YonoColors.textSecondary))]))
        else ...user.activeFDs.map((fd) => Padding(padding: const EdgeInsets.only(bottom: 14),
          child: YonoCard(child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Smart FD', style: YonoTextStyles.body(15, weight: FontWeight.w700)),
                Text('${fd.months} mo  •  ${(fd.interestRate*100).toStringAsFixed(1)}% p.a. (compound quarterly)',
                    style: YonoTextStyles.body(12, color: YonoColors.textSecondary)),
                Text('Matures ${fmtDate(fd.maturityDate)}',
                    style: YonoTextStyles.body(12, color: YonoColors.textTertiary)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${fmt(fd.principal)}', style: YonoTextStyles.mono(20,
                    color: YonoColors.deepBlue, weight: FontWeight.w800)),
                const SizedBox(height: 4),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: YonoColors.successBg,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('+₹${fmt(fd.earnedInterest)}', style: YonoTextStyles.body(12,
                      color: YonoColors.success, weight: FontWeight.w700))),
              ]),
            ]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(value: 0.12,
                    backgroundColor: YonoColors.divider,
                    color: Color(0xFF4F46E5), minHeight: 5)),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Opened ${fmtDate(fd.date)}',
                  style: YonoTextStyles.body(11, color: YonoColors.textTertiary)),
              Text('Yield ₹${fmt(fd.maturityAmount)}',
                  style: YonoTextStyles.body(11, color: YonoColors.success, weight: FontWeight.w600)),
            ]),
          ])))),
        if (user.insurancePolicies.isNotEmpty) ...[
          const SizedBox(height: 22),
          const SectionHeader(title: 'Insurance'), const SizedBox(height: 14),
          ...user.insurancePolicies.map((p) => Padding(padding: const EdgeInsets.only(bottom: 12),
            child: YonoCard(child: Row(children: [
              const Text('🛡️', style: TextStyle(fontSize: 30)), const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.title, style: YonoTextStyles.body(15, weight: FontWeight.w600)),
                Text('Cover: ₹${fmt(p.coverAmount)}',
                    style: YonoTextStyles.body(13, color: YonoColors.textSecondary)),
              ])),
              Text('₹${fmt(p.premium)}/yr', style: YonoTextStyles.mono(13, color: YonoColors.error)),
            ])))),
        ],
        if (user.loans.isNotEmpty) ...[
          const SizedBox(height: 22),
          const SectionHeader(title: 'Active Loans'), const SizedBox(height: 14),
          ...user.loans.map((l) => Padding(padding: const EdgeInsets.only(bottom: 12),
            child: YonoCard(child: Row(children: [
              const Text('🏠', style: TextStyle(fontSize: 30)), const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.type, style: YonoTextStyles.body(15, weight: FontWeight.w600)),
                Text('EMI ₹${fmt(l.emi)}/mo  •  ${l.tenure} months',
                    style: YonoTextStyles.body(13, color: YonoColors.textSecondary)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: YonoColors.successBg,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(l.status, style: YonoTextStyles.body(12,
                    color: YonoColors.success, weight: FontWeight.w600))),
            ])))),
        ],
        const SizedBox(height: 20),
      ]));
  }
}

// ---- NextGen Transactions ----
class _NextGenTransactions extends StatefulWidget {
  final CustomerProfile user; const _NextGenTransactions({required this.user});
  @override State<_NextGenTransactions> createState() => _NGTxnState();
}
class _NGTxnState extends State<_NextGenTransactions> {
  String _filter = 'All';
  final _filters = ['All','Income','Food','Shopping','Entertainment','Investment','Transfer'];
  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All'
        ? widget.user.transactions
        : widget.user.transactions.where((t) => t.category == _filter).toList();
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map<Widget>((f) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _filter == f ? YonoColors.royalBlue : YonoColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _filter == f ? YonoColors.royalBlue : YonoColors.divider,
                      ),
                    ),
                    child: Text(
                      f,
                      style: YonoTextStyles.body(
                        13,
                        color: _filter == f ? Colors.white : YonoColors.textSecondary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      Expanded(
        child: filtered.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      'No $_filter transactions',
                      style: YonoTextStyles.body(16, color: YonoColors.textSecondary),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => YonoCard(child: TxnTile(t: filtered[i])),
              ),
      ),
    ]);
  }
}

// ---- NextGen Profile ----
class _NextGenProfile extends ConsumerWidget {
  final CustomerProfile user; const _NextGenProfile({required this.user});
  @override Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      const SizedBox(height: 16),
      AccessibleAvatar(emoji: user.profileEmoji,
          gradient: const [YonoColors.navyBlue, YonoColors.royalBlue]),
      const SizedBox(height: 14),
      Text(user.name, style: YonoTextStyles.display(22, color: YonoColors.deepBlue)),
      Text('IFSC: ${user.ifscCode}',
          style: YonoTextStyles.body(13, color: YonoColors.textSecondary)),
      const SizedBox(height: 22),
      YonoCard(child: Column(children: [
        profileRow('Account No.', user.accountNumber), const Divider(height: 22),
        profileRow('Mobile', user.mobileNumber),       const Divider(height: 22),
        profileRow('Email', user.email),               const Divider(height: 22),
        profileRow('Credit Score', '${user.creditScore} / 900'), const Divider(height: 22),
        profileRow('Reward Points', '${user.rewardPoints} pts'),
      ])),
      const SizedBox(height: 16),
      YonoCard(padding: EdgeInsets.zero, child: Column(children: [
        _MenuItem(emoji: '🔒', label: 'Change MPIN',
            onTap: () => context.go('/nextgen/change-mpin')),
        _Divider(),
        _MenuItem(emoji: '📊', label: 'Spend Analytics',
            onTap: () => context.go('/nextgen/analytics')),
        _Divider(),
        _MenuItem(emoji: '🎁', label: 'Rewards & Cashback',
            onTap: () => context.go('/nextgen/rewards')),
        _Divider(),
        _MenuItem(emoji: '🔔', label: 'Notifications',
            onTap: () => context.go('/nextgen/notifications')),
        _Divider(),
        _MenuItem(emoji: '📄', label: 'Download Statement',
            onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Download Statement', style: YonoTextStyles.display(18)),
              content: Text('Statement sent to ${user.email}',
                  style: YonoTextStyles.body(14)),
              actions: [TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
                ElevatedButton(onPressed: () { Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Statement requested. Check your email.')));},
                    child: const Text('Send'))],))),
        _Divider(),
        _MenuItem(emoji: '🆘', label: 'Block Card / Fraud',
            onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Block Card', style: YonoTextStyles.display(18, color: YonoColors.error)),
              content: const Text('SBI 24×7: 1800 11 2211\nCard will be instantly blocked.'),
              actions: [TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
                ElevatedButton(style: ElevatedButton.styleFrom(
                    backgroundColor: YonoColors.error),
                    onPressed: () { Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Card blocked. New card dispatched in 3 days.'),
                          backgroundColor: YonoColors.error));},
                    child: const Text('Block Card',
                        style: TextStyle(color: Colors.white)))],))),
      ])),
      const SizedBox(height: 20),
      GradientButton(label: 'Logout Securely', icon: Icons.logout,
          colors: [YonoColors.error.withValues(alpha: 0.85), YonoColors.error],
          onTap: () { ref.read(authProvider.notifier).logout(); context.go('/login'); },
          height: 52, fontSize: 16),
      const SizedBox(height: 28),
    ]));
  }
}

// ============================================================================
// NEXTGEN FEATURE SCREENS
// ============================================================================
class NextGenFDScreen extends ConsumerStatefulWidget {
  const NextGenFDScreen({super.key});
  @override ConsumerState<NextGenFDScreen> createState() => _NGFDState();
}
class _NGFDState extends ConsumerState<NextGenFDScreen> {
  double _amount = 10000; int _months = 12;
  static const _rate = 0.071;
  @override Widget build(BuildContext context) {
    final maturity = compoundMaturity(_amount, _rate, _months);
    final delta    = maturity - (_amount + _amount * _rate * (_months / 12));
    return Scaffold(backgroundColor: YonoColors.surface,
      appBar: AppBar(title: Text('Smart Fixed Deposit',
          style: YonoTextStyles.body(18, color: Colors.white, weight: FontWeight.w600)),
          backgroundColor: YonoColors.deepBlue, foregroundColor: Colors.white),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          YonoCard(color: YonoColors.successBg, child: Row(children: [
            const Text('🏦', style: TextStyle(fontSize: 24)), const SizedBox(width: 12),
            Expanded(child: Text('Quarterly compounding — '
                '₹${fmt(delta)} more than simple interest',
                style: YonoTextStyles.body(12, color: YonoColors.success,
                    weight: FontWeight.w600))),
          ])),
          const SizedBox(height: 20),
          Text('Investment Amount', style: YonoTextStyles.body(13, color: YonoColors.textSecondary)),
          const SizedBox(height: 4),
          Text('₹ ${fmt(_amount)}', style: YonoTextStyles.mono(44,
              color: YonoColors.deepBlue, weight: FontWeight.w900)),
          Slider(value: _amount, min: 5000, max: 200000,
              activeColor: const Color(0xFF4F46E5), inactiveColor: YonoColors.divider,
              onChanged: (v) => setState(() =>
                  _amount = (v / 1000).roundToDouble() * 1000)),
          const SizedBox(height: 10),
          Text('Tenure', style: YonoTextStyles.body(13, color: YonoColors.textSecondary)),
          const SizedBox(height: 4),
          Text('$_months Months', style: YonoTextStyles.mono(38,
              color: YonoColors.deepBlue, weight: FontWeight.w800)),
          Slider(value: _months.toDouble(), min: 6, max: 60, divisions: 54,
              activeColor: const Color(0xFF4F46E5), inactiveColor: YonoColors.divider,
              onChanged: (v) => setState(() => _months = v.toInt())),
          const SizedBox(height: 28),
          YonoCard(color: YonoColors.successBg, child: Column(children: [
            Text('At Maturity (Compound Quarterly)',
                style: YonoTextStyles.body(13, color: YonoColors.success)),
            const SizedBox(height: 6),
            Text('₹ ${fmt(maturity)}', style: YonoTextStyles.mono(40,
                color: YonoColors.success, weight: FontWeight.w900)),
            Text('Rate: ${(_rate * 100).toStringAsFixed(1)}% p.a.',
                style: YonoTextStyles.body(12, color: YonoColors.success)),
          ])),
          const SizedBox(height: 28),
          GradientButton(label: 'Confirm FD — ₹${fmt(_amount)}',
              colors: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              icon: Icons.lock_outline, height: 62, fontSize: 17,
              onTap: () {
                HapticFeedback.heavyImpact();
                final ok = ref.read(authProvider.notifier).createFD(_amount, _months, _rate);
                if (ok) {
                  context.go('/nextgen/success', extra: {
                  'title': 'FD Created! 🎉',
                  'subtitle': '₹${fmt(_amount)} locked for $_months months.',
                  'route': '/nextgen'});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Insufficient balance.'),
                    backgroundColor: YonoColors.error));
                }
              }),
        ])));
  }
}

class NextGenSendMoneyScreen extends ConsumerStatefulWidget {
  const NextGenSendMoneyScreen({super.key});
  @override ConsumerState<NextGenSendMoneyScreen> createState() => _SendState();
}
class _SendState extends ConsumerState<NextGenSendMoneyScreen> {
  final _upiCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  bool _loading = false;
  @override void dispose() { _upiCtrl.dispose(); _amtCtrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: YonoColors.surface,
    appBar: AppBar(title: Text('Send Money',
        style: YonoTextStyles.body(18, color: Colors.white, weight: FontWeight.w600)),
        backgroundColor: YonoColors.deepBlue, foregroundColor: Colors.white),
    body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      YonoCard(child: Column(children: [
        _InputField(ctrl: _upiCtrl, label: 'UPI ID / Mobile',
            icon: Icons.send_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _InputField(ctrl: _amtCtrl, label: 'Amount', icon: Icons.currency_rupee,
            keyboardType: TextInputType.number, prefix: '₹  '),
      ])),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 8, children: [500,1000,2000,5000].map((a) {
        final sel = _amtCtrl.text == a.toString();
        return GestureDetector(onTap: () => setState(() => _amtCtrl.text = a.toString()),
          child: AnimatedContainer(duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
                color: sel ? YonoColors.royalBlue : YonoColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: YonoColors.divider)),
            child: Text('₹$a', style: YonoTextStyles.body(14,
                color: sel ? Colors.white : YonoColors.textPrimary,
                weight: FontWeight.w600))));
      }).toList()),
      const SizedBox(height: 28),
      GradientButton(label: _loading ? 'Processing…' : 'Send Money',
          icon: Icons.send, onTap: _loading ? null : () async {
        final amt = double.tryParse(_amtCtrl.text);
        if (amt == null || amt <= 0 || _upiCtrl.text.isEmpty) return;
        setState(() => _loading = true);
        await Future.delayed(const Duration(seconds: 1));
        final ok = ref.read(authProvider.notifier).sendMoney(amt, _upiCtrl.text);
        if (!mounted) return;
        setState(() => _loading = false);
        if (ok) {
          context.go('/nextgen/success', extra: {
          'title': 'Money Sent! 💸',
          'subtitle': '₹${fmt(amt)} → ${_upiCtrl.text}', 'route': '/nextgen'});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Insufficient balance.'), backgroundColor: YonoColors.error));
        }
      }),
    ])));
}

class NextGenBillPayScreen extends ConsumerStatefulWidget {
  const NextGenBillPayScreen({super.key});
  @override ConsumerState<NextGenBillPayScreen> createState() => _BillState();
}
class _BillState extends ConsumerState<NextGenBillPayScreen> {
  final _amtCtrl = TextEditingController(); bool _loading = false;
  @override void dispose() { _amtCtrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: YonoColors.surface,
    appBar: AppBar(title: Text('Pay Bills',
        style: YonoTextStyles.body(18, color: Colors.white, weight: FontWeight.w600)),
        backgroundColor: YonoColors.deepBlue, foregroundColor: Colors.white),
    body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      YonoCard(child: _InputField(ctrl: _amtCtrl, label: 'Amount (₹)',
          icon: Icons.currency_rupee, keyboardType: TextInputType.number, prefix: '₹  ')),
      const SizedBox(height: 24),
      GradientButton(label: _loading ? 'Processing…' : 'Pay Bill',
          icon: Icons.check_circle_outline, onTap: _loading ? null : () async {
        final amt = double.tryParse(_amtCtrl.text);
        if (amt == null || amt <= 0) return;
        setState(() => _loading = true);
        await Future.delayed(const Duration(milliseconds: 900));
        final ok = ref.read(authProvider.notifier).payBill(amt, 'Utility Bill', 'Utility');
        if (!mounted) return;
        setState(() => _loading = false);
        if (ok) {
          context.go('/nextgen/success', extra: {
          'title': 'Bill Paid! ✅', 'subtitle': '₹${fmt(amt)} paid.', 'route': '/nextgen'});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Insufficient balance.'), backgroundColor: YonoColors.error));
        }
      }),
    ])));
}

class ScanPayScreen extends StatelessWidget {
  const ScanPayScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Scan & Pay', style: YonoTextStyles.body(18,
          color: Colors.white, weight: FontWeight.w600)),
      backgroundColor: YonoColors.deepBlue,
      foregroundColor: Colors.white,
    ),
    backgroundColor: YonoColors.surface,
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 220, height: 220,
          decoration: BoxDecoration(
            color: YonoColors.card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(
              color: YonoColors.deepBlue.withValues(alpha: 0.10),
              blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.qr_code_2_rounded, size: 100, color: YonoColors.royalBlue),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: YonoColors.warningBg,
                borderRadius: BorderRadius.circular(20)),
              child: Text('Demo Mode', style: YonoTextStyles.body(12,
                  color: YonoColors.warning, weight: FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(height: 32),
        Text('Scan & Pay', style: YonoTextStyles.display(24, color: YonoColors.deepBlue)),
        const SizedBox(height: 8),
        Text('UPI QR scanner would activate camera\nin a device build.',
            style: YonoTextStyles.body(15, color: YonoColors.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
        YonoCard(color: YonoColors.cyanLight, child: Row(children: [
          const Icon(Icons.info_outline, color: YonoColors.royalBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(
            'Supports all UPI QR codes — BharatPe, PhonePe, Google Pay, Paytm.',
            style: YonoTextStyles.body(13, color: YonoColors.royalBlue))),
        ])),
        const SizedBox(height: 16),
        GradientButton(
          label: 'Enter UPI ID Manually',
          icon: Icons.keyboard_alt_outlined,
          onTap: () => context.go('/nextgen/send-money'),
          height: 54, fontSize: 15,
        ),
      ]),
    ),
  );
}

class LoanCalculatorScreen extends StatefulWidget {
  const LoanCalculatorScreen({super.key});
  @override State<LoanCalculatorScreen> createState() => _LoanCalcState();
}
class _LoanCalcState extends State<LoanCalculatorScreen> {
  double _amount = 500000; int _months = 60; final _rate = 0.105;
  @override Widget build(BuildContext context) {
    final monthlyRate = _rate / 12;
    final emi = (_amount * monthlyRate * math.pow(1 + monthlyRate, _months))
        / (math.pow(1 + monthlyRate, _months) - 1);
    return Scaffold(backgroundColor: YonoColors.surface,
      appBar: AppBar(title: Text('Loan Calculator', style: YonoTextStyles.body(18,
          color: Colors.white, weight: FontWeight.w600)),
          backgroundColor: YonoColors.deepBlue, foregroundColor: Colors.white),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Loan Amount', style: YonoTextStyles.body(13, color: YonoColors.textSecondary)),
        Text('₹ ${fmt(_amount)}', style: YonoTextStyles.mono(40,
            color: YonoColors.deepBlue, weight: FontWeight.w900)),
        Slider(value: _amount, min: 100000, max: 2000000,
            activeColor: const Color(0xFF4F46E5), inactiveColor: YonoColors.divider,
            onChanged: (v) => setState(() => _amount = (v/10000).roundToDouble()*10000)),
        const SizedBox(height: 16),
        Text('Tenure', style: YonoTextStyles.body(13, color: YonoColors.textSecondary)),
        Text('$_months Months', style: YonoTextStyles.mono(36,
            color: YonoColors.deepBlue, weight: FontWeight.w800)),
        Slider(value: _months.toDouble(), min: 12, max: 240, divisions: 228,
            activeColor: const Color(0xFF4F46E5), inactiveColor: YonoColors.divider,
            onChanged: (v) => setState(() => _months = v.toInt())),
        const SizedBox(height: 24),
        YonoCard(color: YonoColors.successBg, child: Column(children: [
          Text('Monthly EMI', style: YonoTextStyles.body(14, color: YonoColors.success)),
          const SizedBox(height: 8),
          Text('₹ ${fmt(emi)}', style: YonoTextStyles.mono(44,
              color: YonoColors.success, weight: FontWeight.w900)),
          Text('Interest: ${(_rate*100).toStringAsFixed(1)}% p.a.  •  Total: ₹${fmt(emi*_months)}',
              style: YonoTextStyles.body(12, color: YonoColors.success)),
        ])),
        const SizedBox(height: 8),
        Text('* Rate subject to CIBIL score. EMI calculated on reducing balance.',
            style: YonoTextStyles.body(11, color: YonoColors.textTertiary)),
      ])));
  }
}

class SpendAnalyticsScreen extends ConsumerWidget {
  const SpendAnalyticsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider)!;
    final spend = user.spendByCategory;
    final total = spend.values.fold(0.0, (s, v) => s + v);
    return Scaffold(backgroundColor: YonoColors.surface,
      appBar: AppBar(title: Text('Spend Analytics', style: YonoTextStyles.body(18,
          color: Colors.white, weight: FontWeight.w600)),
          backgroundColor: YonoColors.deepBlue, foregroundColor: Colors.white),
      body: total == 0
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('📊', style: TextStyle(fontSize: 60)), const SizedBox(height: 16),
              Text('No spending data yet', style: YonoTextStyles.body(16,
                  color: YonoColors.textSecondary))]))
          : ListView(padding: const EdgeInsets.all(20), children: [
              YonoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('This Month', style: YonoTextStyles.display(18)),
                const SizedBox(height: 4),
                Text('Total Spent: ₹${fmt(total)}',
                    style: YonoTextStyles.body(13, color: YonoColors.textSecondary)),
              ])),
              const SizedBox(height: 16),
              ...spend.entries.map((e) {
                final pct = e.value / total;
                return Padding(padding: const EdgeInsets.only(bottom: 12),
                  child: YonoCard(child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(children: [
                        Text(txnEmoji(e.key), style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(e.key, style: YonoTextStyles.body(14, weight: FontWeight.w600)),
                      ]),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('₹${fmt(e.value)}', style: YonoTextStyles.mono(14,
                            weight: FontWeight.w700)),
                        Text('${(pct*100).toStringAsFixed(1)}%',
                            style: YonoTextStyles.body(12, color: YonoColors.textSecondary)),
                      ]),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: pct,
                            backgroundColor: YonoColors.divider,
                            color: YonoColors.royalBlue, minHeight: 5)),
                  ])));
              }),
            ]));
  }
}

class RewardsScreen extends ConsumerWidget {
  final bool isNextGen; const RewardsScreen({super.key, required this.isNextGen});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider)!;
    return Scaffold(backgroundColor: YonoColors.surface,
      appBar: AppBar(title: Text('Rewards', style: YonoTextStyles.body(18,
          color: Colors.white, weight: FontWeight.w600)),
          backgroundColor: isNextGen ? YonoColors.deepBlue : YonoColors.easeForest,
          foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(gradient: LinearGradient(colors: isNextGen
              ? [YonoColors.royalBlue, YonoColors.navyBlue]
              : [YonoColors.easeForest, const Color(0xFF14532D)]),
              borderRadius: BorderRadius.circular(24)),
          child: Column(children: [
            const Text('⭐', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('${user.rewardPoints}', style: YonoTextStyles.mono(52,
                color: Colors.white, weight: FontWeight.w900)),
            Text('Reward Points', style: YonoTextStyles.body(16, color: Colors.white70)),
            Text('≈ ₹${fmt(user.rewardPoints * 0.25)} value',
                style: YonoTextStyles.body(13, color: Colors.white54)),
          ])),
        const SizedBox(height: 20),
        YonoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('How to earn more', style: YonoTextStyles.display(16)),
          const SizedBox(height: 14),
          ...[('💸','Send Money','2 pts/txn'),('📄','Pay Bills','10 pts/txn'),
              ('🏦','Create FD','5 pts/₹1K'),('🛡️','Buy Insurance','50 pts/policy'),
          ].map((e) => Padding(padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Text(e.$1, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(child: Text(e.$2, style: YonoTextStyles.body(14))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: YonoColors.goldLight,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(e.$3, style: YonoTextStyles.body(12,
                    color: YonoColors.warning, weight: FontWeight.w700))),
            ]))),
        ])),
      ]));
  }
}

class NotificationsScreen extends ConsumerWidget {
  final bool isNextGen; const NotificationsScreen({super.key, required this.isNextGen});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider)!;
    return Scaffold(backgroundColor: YonoColors.surface,
      appBar: AppBar(
        title: Text('Notifications', style: YonoTextStyles.body(18,
            color: Colors.white, weight: FontWeight.w600)),
        backgroundColor: isNextGen ? YonoColors.deepBlue : YonoColors.easeForest,
        foregroundColor: Colors.white,
        actions: [TextButton(onPressed: () => ref.read(authProvider.notifier).markAllRead(),
            child: const Text('Mark all read',
                style: TextStyle(color: Colors.white70, fontSize: 13)))],
      ),
      body: user.notifications.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🔔', style: TextStyle(fontSize: 48)), const SizedBox(height: 12),
              Text('No notifications', style: YonoTextStyles.body(16,
                  color: YonoColors.textSecondary))]))
          : ListView.separated(padding: const EdgeInsets.all(16),
              itemCount: user.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = user.notifications[i];
                return YonoCard(child: Row(children: [
                  Container(width: 42, height: 42,
                    decoration: BoxDecoration(color: n.isRead
                        ? YonoColors.surface : YonoColors.royalBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(n.type == 'credit' ? '💰'
                        : n.type == 'offer' ? '🎁' : '🔔',
                        style: const TextStyle(fontSize: 20)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n.title, style: YonoTextStyles.body(14, weight: FontWeight.w600)),
                    Text(n.body, style: YonoTextStyles.body(12, color: YonoColors.textSecondary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text(fmtDate(n.date), style: YonoTextStyles.body(11,
                        color: YonoColors.textTertiary)),
                  ])),
                  if (!n.isRead) Container(width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: YonoColors.royalBlue, shape: BoxShape.circle)),
                ]));
              }));
  }
}

class ChangeMpinScreen extends StatefulWidget {
  const ChangeMpinScreen({super.key});
  @override State<ChangeMpinScreen> createState() => _ChangeMpinState();
}
class _ChangeMpinState extends State<ChangeMpinScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  @override void dispose() { _oldCtrl.dispose(); _newCtrl.dispose(); _confCtrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: YonoColors.surface,
    appBar: AppBar(title: Text('Change MPIN', style: YonoTextStyles.body(18,
        color: Colors.white, weight: FontWeight.w600)),
        backgroundColor: YonoColors.deepBlue, foregroundColor: Colors.white),
    body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      YonoCard(child: Column(children: [
        TextField(controller: _oldCtrl, obscureText: true, keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Current MPIN',
                prefixIcon: const Icon(Icons.lock_outline, color: YonoColors.royalBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 14),
        TextField(controller: _newCtrl, obscureText: true, keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'New MPIN',
                prefixIcon: const Icon(Icons.lock_open_outlined, color: YonoColors.royalBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 14),
        TextField(controller: _confCtrl, obscureText: true, keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Confirm New MPIN',
                prefixIcon: const Icon(Icons.check_circle_outline, color: YonoColors.royalBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      ])),
      const SizedBox(height: 24),
      GradientButton(label: 'Update MPIN', icon: Icons.security, onTap: () {
        if (_newCtrl.text == _confCtrl.text && _newCtrl.text.length >= 6) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('MPIN updated successfully!'),
              backgroundColor: YonoColors.success));
          context.go('/nextgen');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('MPINs do not match or must be 6 digits.'),
              backgroundColor: YonoColors.error));
        }
      }),
    ])));
}

// ============================================================================
// EASE SHELL
// ============================================================================
class EaseShell extends ConsumerStatefulWidget {
  const EaseShell({super.key});
  @override ConsumerState<EaseShell> createState() => _EaseShellState();
}
class _EaseShellState extends ConsumerState<EaseShell> {
  int _idx = 0;
  @override Widget build(BuildContext context) {
    final user  = ref.watch(authProvider)!;
    final pages = [_EaseHome(user: user), _EaseInvestments(user: user),
                   _EaseHistory(user: user), _EaseProfile(user: user)];
    return Scaffold(backgroundColor: YonoColors.surface,
      appBar: AppBar(backgroundColor: YonoColors.easeForest, elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: () => context.go('/portal')),
        title: Row(children: [
          const Icon(Icons.eco_outlined, color: YonoColors.easeAmber, size: 20),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('YONO Ease', style: YonoTextStyles.body(17,
                color: Colors.white, weight: FontWeight.w700)),
            Text('सरल बैंकिंग', style: YonoTextStyles.hindi(11, color: Colors.white54)),
          ]),
        ]),
        actions: [
          Stack(children: [
            IconButton(icon: const Icon(Icons.notifications_outlined,
                color: Colors.white70, size: 26),
                onPressed: () => context.go('/ease/notifications')),
            if (user.unreadCount > 0) Positioned(top: 10, right: 10,
                child: Container(width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: YonoColors.error, shape: BoxShape.circle))),
          ]),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white38, size: 20),
              onPressed: () { ref.read(authProvider.notifier).logout(); context.go('/login'); }),
        ],
      ),
      body: IndexedStack(index: _idx, children: pages),
      floatingActionButton: const Padding(
        padding: EdgeInsets.only(bottom: 8, right: 4),
        child: YonoQuickFAB(isNextGen: false)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: NavigationBar(backgroundColor: Colors.white, elevation: 0, height: 72,
        indicatorColor: YonoColors.easeForest.withValues(alpha: 0.12),
        selectedIndex: _idx,
        onDestinationSelected: (i) { HapticFeedback.selectionClick(); setState(() => _idx = i); },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: YonoColors.easeForest), label: 'होम'),
          NavigationDestination(icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings, color: YonoColors.easeForest), label: 'निवेश'),
          NavigationDestination(icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: YonoColors.easeForest), label: 'लेनदेन'),
          NavigationDestination(icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: YonoColors.easeForest), label: 'प्रोफ़ाइल'),
        ],
      ),
    );
  }
}

// ---- Ease Home ----
class _EaseHome extends ConsumerWidget {
  final CustomerProfile user; const _EaseHome({required this.user});
  @override Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('नमस्ते 🙏', style: YonoTextStyles.hindi(22,
                color: YonoColors.easeForest, weight: FontWeight.w700)),
            Text(user.name.split(' ')[0],
                style: YonoTextStyles.display(30, color: YonoColors.deepBlue)),
          ]),
          GestureDetector(onTap: () => context.go('/ease/rewards'),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: YonoColors.goldLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: YonoColors.gold.withValues(alpha: 0.4))),
              child: Row(children: [
                const Icon(Icons.star, color: YonoColors.gold, size: 14),
                const SizedBox(width: 4),
                Text('${user.rewardPoints} pts', style: YonoTextStyles.body(12,
                    color: YonoColors.warning, weight: FontWeight.w700)),
              ]))),
        ]),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [YonoColors.easeForest, Color(0xFF14532D), Color(0xFF166534)]),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: YonoColors.easeForest.withValues(alpha: 0.4),
                  blurRadius: 30, offset: const Offset(0, 12))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('बचत खाता', style: YonoTextStyles.hindi(13, color: Colors.white60)),
                Text(user.accountNumber, style: YonoTextStyles.body(12, color: Colors.white30)),
              ]),
              Row(children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(
                    color: YonoColors.success, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('सक्रिय', style: YonoTextStyles.hindi(11, color: Colors.white60)),
                const SizedBox(width: 12),
                GestureDetector(onTap: () => ref.read(authProvider.notifier).toggleBalance(),
                    child: Icon(user.balanceHidden
                        ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white54, size: 22)),
              ]),
            ]),
            const SizedBox(height: 18),
            Text('उपलब्ध राशि', style: YonoTextStyles.hindi(13, color: Colors.white38)),
            const SizedBox(height: 6),
            user.balanceHidden
                ? const AccessibleBalanceHidden()
                : Text('₹ ${fmt(user.accountBalance)}', style: YonoTextStyles.mono(42,
                    color: Colors.white, weight: FontWeight.w800)),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: YonoColors.easeAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: YonoColors.easeAmber.withValues(alpha: 0.4))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: YonoColors.easeAmber, size: 15),
                const SizedBox(width: 6),
                Text('पेंशन खाता सक्रिय', style: YonoTextStyles.hindi(12,
                    color: YonoColors.easeAmber, weight: FontWeight.w700)),
              ])),
          ])),
        const SizedBox(height: 22),
        const SectionHeader(title: 'क्या करना है?'), const SizedBox(height: 14),
        GridView.count(crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.4, mainAxisSpacing: 12, crossAxisSpacing: 12,
            children: [
              _EaseQuickBtn(emoji: '💸', label: 'पैसे भेजें', sublabel: 'Send Money',
                  color: const Color(0xFFEFF6FF),
                  onTap: () => context.go('/ease/send-money')),
              _EaseQuickBtn(emoji: '🏦', label: 'FD खोलें', sublabel: 'Fixed Deposit',
                  color: const Color(0xFFF0FDF4),
                  onTap: () => context.go('/ease/fd-create')),
              _EaseQuickBtn(emoji: '🌾', label: 'फसल बीमा', sublabel: 'Fasal Bima',
                  color: const Color(0xFFFFFBEB),
                  onTap: () => context.go('/ease/fasal-bima')),
              _EaseQuickBtn(emoji: '🏥', label: 'स्वास्थ्य बीमा', sublabel: 'Health Insurance',
                  color: const Color(0xFFFFF1F2),
                  onTap: () => context.go('/ease/health-ins')),
            ]),
        const SizedBox(height: 22),
        GestureDetector(onTap: () => context.go('/ease/fd-create'),
          child: Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(
                colors: [Color(0xFFD97706), Color(0xFFB45309)]),
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('वरिष्ठ नागरिक FD', style: YonoTextStyles.hindi(16,
                    color: Colors.white, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('7.6% ब्याज दर  •  अतिरिक्त 0.5%',
                    style: YonoTextStyles.hindi(13, color: Colors.white70)),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('अभी निवेश करें', style: YonoTextStyles.hindi(13,
                      color: const Color(0xFFB45309), weight: FontWeight.w700))),
              ])),
              const Text('🏆', style: TextStyle(fontSize: 52)),
            ]))),
        const SizedBox(height: 22),
        const SectionHeader(title: 'हाल के लेनदेन'), const SizedBox(height: 12),
        user.transactions.isEmpty
            ? YonoCard(child: Column(children: [
                const Text('🔍', style: TextStyle(fontSize: 40)), const SizedBox(height: 10),
                Text('कोई लेनदेन नहीं', style: YonoTextStyles.hindi(14,
                    color: YonoColors.textSecondary))]))
            : YonoCard(padding: EdgeInsets.zero, child: Column(
                children: user.transactions.take(3).toList().asMap().entries.map((e) =>
                  Column(children: [
                    Padding(padding: const EdgeInsets.all(16),
                        child: TxnTile(t: e.value, large: true)),
                    if (e.key < 2) const Divider(height: 1,
                        color: YonoColors.divider, indent: 16, endIndent: 16),
                  ])).toList())),
        const SizedBox(height: 24),
        YonoCard(color: YonoColors.cyanLight, child: Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: YonoColors.royalBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.headset_mic_outlined,
                  color: YonoColors.royalBlue, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('सहायता चाहिए?', style: YonoTextStyles.hindi(15,
                color: YonoColors.deepBlue, weight: FontWeight.w700)),
            Text('SBI Helpline: 1800 11 2211 (निःशुल्क)',
                style: YonoTextStyles.body(12, color: YonoColors.textSecondary)),
          ])),
          const Icon(Icons.phone_outlined, color: YonoColors.royalBlue, size: 22),
        ])),
        const SizedBox(height: 24),
      ]));
  }
}

class _EaseQuickBtn extends StatelessWidget {
  final String emoji, label, sublabel; final Color color; final VoidCallback onTap;
  const _EaseQuickBtn({required this.emoji, required this.label,
      required this.sublabel, required this.color, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: () { HapticFeedback.mediumImpact(); onTap(); },
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: YonoColors.divider)),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: YonoTextStyles.hindi(13,
              color: YonoColors.deepBlue, weight: FontWeight.w700)),
          Text(sublabel, style: YonoTextStyles.body(10, color: YonoColors.textTertiary)),
        ])),
      ])));
}

// ---- Ease Investments ----
class _EaseInvestments extends StatelessWidget {
  final CustomerProfile user; const _EaseInvestments({required this.user});
  @override Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('मेरे निवेश', style: YonoTextStyles.hindi(28,
            color: YonoColors.deepBlue, weight: FontWeight.w800)),
        Text('Grow your savings securely',
            style: YonoTextStyles.body(14, color: YonoColors.textSecondary)),
        const SizedBox(height: 20),
        GestureDetector(onTap: () => context.go('/ease/fd-create'),
          child: Container(padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(gradient: const LinearGradient(
                colors: [YonoColors.easeForest, Color(0xFF14532D)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: YonoColors.easeForest.withValues(alpha: 0.3),
                    blurRadius: 20, offset: const Offset(0, 8))]),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.lock_outline, color: Colors.white, size: 26)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('FD खोलें', style: YonoTextStyles.hindi(18,
                    color: Colors.white, weight: FontWeight.w700)),
                Text('7.6% तक ब्याज (quarterly compound)  •  ₹1,000 से शुरू',
                    style: YonoTextStyles.hindi(12, color: Colors.white60)),
              ])),
              const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
            ]))),
        const SizedBox(height: 14),
        GestureDetector(onTap: () => context.go('/ease/fasal-bima'),
          child: Container(padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(gradient: const LinearGradient(
                colors: [Color(0xFFD97706), Color(0xFFB45309)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(22)),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.agriculture_outlined, color: Colors.white, size: 26)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('फसल बीमा (PMFBY)', style: YonoTextStyles.hindi(18,
                    color: Colors.white, weight: FontWeight.w700)),
                Text('प्रधानमंत्री फसल बीमा योजना',
                    style: YonoTextStyles.hindi(13, color: Colors.white60)),
              ])),
              const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
            ]))),
        const SizedBox(height: 14),
        GestureDetector(onTap: () => context.go('/ease/health-ins'),
          child: Container(padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(22)),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_outline, color: Colors.white, size: 26)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('स्वास्थ्य बीमा', style: YonoTextStyles.hindi(18,
                    color: Colors.white, weight: FontWeight.w700)),
                Text('₹5 लाख तक का कवर', style: YonoTextStyles.hindi(13, color: Colors.white60)),
              ])),
              const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
            ]))),
        const SizedBox(height: 24),
        if (user.activeFDs.isNotEmpty) ...[
          const SectionHeader(title: 'मेरी FD'), const SizedBox(height: 14),
          ...user.activeFDs.map((fd) => Padding(padding: const EdgeInsets.only(bottom: 14),
            child: YonoCard(child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('सावधि जमा (FD)', style: YonoTextStyles.hindi(15, weight: FontWeight.w700)),
                  Text('${fd.months} माह  •  ${(fd.interestRate*100).toStringAsFixed(1)}% (quarterly)',
                      style: YonoTextStyles.hindi(12, color: YonoColors.textSecondary)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹${fmt(fd.principal)}', style: YonoTextStyles.mono(18,
                      color: YonoColors.deepBlue, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: YonoColors.successBg,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('+₹${fmt(fd.earnedInterest)}', style: YonoTextStyles.body(11,
                        color: YonoColors.success, weight: FontWeight.w700))),
                ]),
              ]),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(value: 0.12,
                      backgroundColor: YonoColors.divider,
                      color: YonoColors.easeForest, minHeight: 5)),
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('परिपक्वता: ${fmtDate(fd.maturityDate)}',
                    style: YonoTextStyles.body(11, color: YonoColors.textTertiary)),
                Text('कुल: ₹${fmt(fd.maturityAmount)}', style: YonoTextStyles.body(11,
                    color: YonoColors.success, weight: FontWeight.w600)),
              ]),
            ])))),
        ],
        const SizedBox(height: 20),
      ]));
  }
}

// ---- Ease History ----
class _EaseHistory extends StatefulWidget {
  final CustomerProfile user; const _EaseHistory({required this.user});
  @override State<_EaseHistory> createState() => _EaseHistoryState();
}
class _EaseHistoryState extends State<_EaseHistory> {
  String _filter = 'सभी';
  final _filters = ['सभी', 'Income', 'Utility', 'Health', 'Family'];
  @override Widget build(BuildContext context) {
    final filtered = _filter == 'सभी'
        ? widget.user.transactions
        : widget.user.transactions.where((t) => t.category == _filter).toList();
    return Column(children: [
      Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: Row(children: _filters.map((f) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(onTap: () => setState(() => _filter = f),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                    color: _filter == f ? YonoColors.easeForest : YonoColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _filter == f
                        ? YonoColors.easeForest : YonoColors.divider)),
                child: Text(f, style: YonoTextStyles.hindi(14,
                    color: _filter == f ? Colors.white : YonoColors.textSecondary,
                    weight: FontWeight.w600)))))).toList()))),
      Expanded(child: filtered.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🔍', style: TextStyle(fontSize: 48)), const SizedBox(height: 12),
              Text('कोई लेनदेन नहीं', style: YonoTextStyles.hindi(16,
                  color: YonoColors.textSecondary))]))
          : ListView.separated(padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => YonoCard(child: TxnTile(t: filtered[i], large: true)))),
    ]);
  }
}

// ---- Ease Profile ----
class _EaseProfile extends ConsumerWidget {
  final CustomerProfile user; const _EaseProfile({required this.user});
  @override Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      const SizedBox(height: 16),
      AccessibleAvatar(emoji: user.profileEmoji,
          gradient: const [YonoColors.easeForest, Color(0xFF14532D)], baseSize: 90),
      const SizedBox(height: 14),
      Text(user.name, style: YonoTextStyles.display(22, color: YonoColors.deepBlue)),
      Text('वरिष्ठ नागरिक खाता', style: YonoTextStyles.hindi(13,
          color: YonoColors.easeForest, weight: FontWeight.w600)),
      const SizedBox(height: 22),
      YonoCard(child: Column(children: [
        profileRow('खाता संख्या', user.accountNumber), const Divider(height: 22),
        profileRow('मोबाइल', user.mobileNumber), const Divider(height: 22),
        profileRow('IFSC कोड', user.ifscCode), const Divider(height: 22),
        profileRow('रिवॉर्ड पॉइंट', '${user.rewardPoints} pts'),
      ])),
      const SizedBox(height: 16),
      YonoCard(padding: EdgeInsets.zero, child: Column(children: [
        _MenuItem(emoji: '🔔', label: 'सूचनाएं / Notifications',
            onTap: () => context.go('/ease/notifications')),
        _Divider(),
        _MenuItem(emoji: '🎁', label: 'पुरस्कार / Rewards',
            onTap: () => context.go('/ease/rewards')),
        _Divider(),
        _MenuItem(emoji: '📄', label: 'खाता विवरण / Statement',
            onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('खाता विवरण', style: YonoTextStyles.hindi(18)),
              content: Text('विवरण ${user.email} पर भेजा जाएगा।',
                  style: YonoTextStyles.hindi(14)),
              actions: [TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('रद्द करें')),
                ElevatedButton(onPressed: () { Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('विवरण ईमेल पर भेजा गया।')));},
                    child: const Text('भेजें'))],))),
        _Divider(),
        _MenuItem(emoji: '🆘', label: 'कार्ड ब्लॉक / Block Card',
            onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('कार्ड ब्लॉक करें', style: YonoTextStyles.hindi(18,
                  color: YonoColors.error)),
              content: const Text('SBI हेल्पलाइन: 1800 11 2211\nकार्ड तुरंत ब्लॉक होगा।'),
              actions: [TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('रद्द करें')),
                ElevatedButton(style: ElevatedButton.styleFrom(
                    backgroundColor: YonoColors.error),
                    onPressed: () { Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('कार्ड ब्लॉक हो गया।'),
                          backgroundColor: YonoColors.error));},
                    child: const Text('ब्लॉक करें',
                        style: TextStyle(color: Colors.white)))],))),
      ])),
      const SizedBox(height: 20),
      GradientButton(label: 'लॉगआउट / Logout', icon: Icons.logout,
          colors: [YonoColors.error.withValues(alpha: 0.85), YonoColors.error],
          onTap: () { ref.read(authProvider.notifier).logout(); context.go('/login'); },
          height: 54, fontSize: 16),
      const SizedBox(height: 28),
    ]));
  }
}

// ============================================================================
// EASE FEATURE SCREENS
// ============================================================================
class EaseFDScreen extends ConsumerStatefulWidget {
  const EaseFDScreen({super.key});
  @override ConsumerState<EaseFDScreen> createState() => _EaseFDState();
}
class _EaseFDState extends ConsumerState<EaseFDScreen> {
  double _amount = 10000; int _months = 12;
  static const _rate = 0.076; // senior citizen rate
  @override Widget build(BuildContext context) {
    final bal     = ref.watch(authProvider)!.accountBalance;
    final maxInv  = bal > 500000 ? 500000.0 : bal;
    final maturity = compoundMaturity(_amount, _rate, _months);
    final delta    = maturity - (_amount + _amount * _rate * (_months / 12));
    return Scaffold(backgroundColor: YonoColors.surface,
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FD खोलें', style: YonoTextStyles.hindi(18,
              color: Colors.white, weight: FontWeight.w700)),
          Text('Senior Citizen Rate — Compound Quarterly',
              style: YonoTextStyles.body(11, color: Colors.white54)),
        ]),
        backgroundColor: YonoColors.easeForest, foregroundColor: Colors.white),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          YonoCard(color: YonoColors.goldLight, child: Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 28)), const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('वरिष्ठ नागरिक विशेष दर', style: YonoTextStyles.hindi(14,
                  color: YonoColors.warning, weight: FontWeight.w700)),
              Text('7.6% quarterly compound — ₹${fmt(delta)} extra vs simple interest',
                  style: YonoTextStyles.hindi(12, color: YonoColors.textSecondary)),
            ])),
          ])),
          const SizedBox(height: 24),
          Text('राशि चुनें', style: YonoTextStyles.hindi(14, color: YonoColors.textSecondary)),
          const SizedBox(height: 4),
          Text('₹ ${fmt(_amount)}', style: YonoTextStyles.mono(44,
              color: YonoColors.deepBlue, weight: FontWeight.w900)),
          Slider(value: _amount, min: 1000,
              max: maxInv > 1000 ? maxInv : 50000,
              activeColor: YonoColors.easeForest, inactiveColor: YonoColors.divider,
              onChanged: (v) => setState(() =>
                  _amount = (v / 1000).roundToDouble() * 1000)),
          Wrap(spacing: 10, runSpacing: 8, children: [10000,25000,50000,100000].map((a) {
            final sel = _amount == a.toDouble();
            return GestureDetector(onTap: () {
              if (a.toDouble() <= maxInv) setState(() => _amount = a.toDouble());
            }, child: AnimatedContainer(duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                  color: sel ? YonoColors.easeForest : YonoColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: YonoColors.divider)),
              child: Text('₹${fmtShort(a.toDouble())}', style: YonoTextStyles.body(14,
                  color: sel ? Colors.white : YonoColors.textPrimary,
                  weight: FontWeight.w600))));
          }).toList()),
          const SizedBox(height: 24),
          Text('अवधि (महीने)', style: YonoTextStyles.hindi(14, color: YonoColors.textSecondary)),
          Text('$_months महीने', style: YonoTextStyles.mono(36,
              color: YonoColors.deepBlue, weight: FontWeight.w800)),
          Slider(value: _months.toDouble(), min: 6, max: 60, divisions: 54,
              activeColor: YonoColors.easeForest, inactiveColor: YonoColors.divider,
              onChanged: (v) => setState(() => _months = v.toInt())),
          const SizedBox(height: 24),
          YonoCard(color: YonoColors.successBg, child: Column(children: [
            Text('परिपक्वता पर मिलेगा (Compound Quarterly)',
                style: YonoTextStyles.hindi(14, color: YonoColors.success)),
            const SizedBox(height: 8),
            Text('₹ ${fmt(maturity)}', style: YonoTextStyles.mono(40,
                color: YonoColors.success, weight: FontWeight.w900)),
            Text('ब्याज आय: ₹${fmt(maturity - _amount)}',
                style: YonoTextStyles.hindi(14, color: YonoColors.success)),
          ])),
          const SizedBox(height: 8),
          Text('* TDS लागू। वरिष्ठ नागरिकों को 0.5% अतिरिक्त। quarterly compound.',
              style: YonoTextStyles.body(11, color: YonoColors.textTertiary)),
          const SizedBox(height: 24),
          GradientButton(label: 'FD बनाएं — ₹${fmt(_amount)}',
              colors: const [YonoColors.easeForest, Color(0xFF14532D)],
              icon: Icons.lock_outline, height: 62, fontSize: 17, onTap: () {
            HapticFeedback.heavyImpact();
            final ok = ref.read(authProvider.notifier).createFD(_amount, _months, _rate);
            if (ok) {
              context.go('/ease/success', extra: {
              'title': 'FD बन गई! 🎉',
              'subtitle': '₹${fmt(_amount)} — $_months महीने के लिए।', 'route': '/ease'});
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('अपर्याप्त बैलेंस।'), backgroundColor: YonoColors.error));
            }
          }),
          const SizedBox(height: 24),
        ])));
  }
}

class EaseSendMoneyScreen extends ConsumerStatefulWidget {
  const EaseSendMoneyScreen({super.key});
  @override ConsumerState<EaseSendMoneyScreen> createState() => _EaseSendState();
}
class _EaseSendState extends ConsumerState<EaseSendMoneyScreen> {
  final _upiCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  bool _loading  = false;
  final _contacts = [('👨','बेटा','beta@sbi'),('👩','बेटी','beti@upi'),
                     ('🧑','पोता','pota@sbi'),('👴','भाई','bhai@ybl')];
  @override void dispose() { _upiCtrl.dispose(); _amtCtrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: YonoColors.surface,
    appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('पैसे भेजें', style: YonoTextStyles.hindi(18,
            color: Colors.white, weight: FontWeight.w700)),
        Text('Send Money via UPI',
            style: YonoTextStyles.body(11, color: Colors.white54)),
      ]),
      backgroundColor: YonoColors.easeForest, foregroundColor: Colors.white),
    body: SingleChildScrollView(padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('परिवार / पहचान के लोग', style: YonoTextStyles.hindi(15,
            color: YonoColors.textSecondary)),
        const SizedBox(height: 14),
        SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: Row(children: _contacts.map((c) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AccessibleContactChip(emoji: c.$1, label: c.$2,
                selected: _upiCtrl.text == c.$3,
                onTap: () => setState(() => _upiCtrl.text = c.$3)))).toList())),
        const SizedBox(height: 24),
        YonoCard(child: Column(children: [
          TextField(controller: _upiCtrl, style: YonoTextStyles.body(18),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'UPI ID / मोबाइल नंबर',
                labelStyle: YonoTextStyles.hindi(14, color: YonoColors.textSecondary),
                prefixIcon: const Icon(Icons.send_outlined, size: 22,
                    color: YonoColors.easeForest),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: YonoColors.divider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: YonoColors.easeForest, width: 1.5)))),
          const SizedBox(height: 16),
          TextField(controller: _amtCtrl,
              style: YonoTextStyles.mono(22, color: YonoColors.deepBlue, weight: FontWeight.w700),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'राशि (₹)',
                labelStyle: YonoTextStyles.hindi(14, color: YonoColors.textSecondary),
                prefixText: '₹  ',
                prefixIcon: const Icon(Icons.currency_rupee, size: 22,
                    color: YonoColors.easeForest),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: YonoColors.divider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: YonoColors.easeForest, width: 1.5)))),
        ])),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 8, children: [500,1000,2000,5000].map((a) {
          final sel = _amtCtrl.text == a.toString();
          return GestureDetector(onTap: () => setState(() => _amtCtrl.text = a.toString()),
            child: AnimatedContainer(duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                  color: sel ? YonoColors.easeForest : YonoColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: YonoColors.divider)),
              child: Text('₹$a', style: YonoTextStyles.body(15,
                  color: sel ? Colors.white : YonoColors.textPrimary,
                  weight: FontWeight.w600))));
        }).toList()),
        const SizedBox(height: 28),
        GradientButton(label: _loading ? 'भेजा जा रहा है…' : 'पैसे भेजें',
            icon: Icons.send,
            colors: const [YonoColors.easeForest, Color(0xFF14532D)],
            height: 62, fontSize: 18,
            onTap: _loading ? null : () async {
          final amt = double.tryParse(_amtCtrl.text);
          if (amt == null || amt <= 0 || _upiCtrl.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('सही UPI ID और राशि दर्ज करें।'),
                backgroundColor: YonoColors.error));
            return;
          }
          setState(() => _loading = true);
          await Future.delayed(const Duration(seconds: 1));
          final ok = ref.read(authProvider.notifier).sendMoney(amt, _upiCtrl.text);
          if (!mounted) return;
          setState(() => _loading = false);
          if (ok) {
            context.go('/ease/success', extra: {
            'title': 'पैसे भेज दिए! 💸',
            'subtitle': '₹${fmt(amt)} → ${_upiCtrl.text}', 'route': '/ease'});
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('अपर्याप्त बैलेंस।'), backgroundColor: YonoColors.error));
          }
        }),
        const SizedBox(height: 24),
      ])));
}

class EaseBimaScreen extends ConsumerStatefulWidget {
  const EaseBimaScreen({super.key});
  @override ConsumerState<EaseBimaScreen> createState() => _EaseBimaState();
}
class _EaseBimaState extends ConsumerState<EaseBimaScreen> {
  String? _crop; String? _season; bool _loading = false;
  final _crops = [('🌾','गेहूं'),('🌿','धान'),('🌽','मक्का'),
                  ('🥜','सोयाबीन'),('🧅','प्याज'),('🍅','टमाटर')];
  final _seasons = [('☀️','खरीफ (Kharif)','Jun–Nov',1200.0),
                    ('❄️','रबी (Rabi)',    'Nov–Apr', 900.0),
                    ('🌸','जायद (Zaid)',   'Mar–Jun', 600.0)];
  @override Widget build(BuildContext context) {
    final season = _season != null
        ? _seasons.firstWhere((s) => s.$2 == _season) : null;
    final premium  = season?.$4 ?? 0.0;
    final coverage = premium * 40;
    return Scaffold(backgroundColor: YonoColors.surface,
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('फसल बीमा', style: YonoTextStyles.hindi(18,
              color: Colors.white, weight: FontWeight.w700)),
          Text('PMFBY — Pradhan Mantri Fasal Bima Yojana',
              style: YonoTextStyles.body(11, color: Colors.white54)),
        ]),
        backgroundColor: YonoColors.easeForest, foregroundColor: Colors.white),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          YonoCard(color: const Color(0xFFF0FDF4), child: Row(children: [
            const Text('🌾', style: TextStyle(fontSize: 30)), const SizedBox(width: 12),
            Expanded(child: Text('सरकारी सहायता से फसल बीमा। प्राकृतिक आपदा से सुरक्षा।',
                style: YonoTextStyles.hindi(13, color: YonoColors.easeForest))),
          ])),
          const SizedBox(height: 24),
          Text('फसल चुनें', style: YonoTextStyles.hindi(16,
              color: YonoColors.deepBlue, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          GridView.count(crossAxisCount: 3, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.1, mainAxisSpacing: 10, crossAxisSpacing: 10,
              children: _crops.map((c) => GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() => _crop = c.$2); },
                child: AnimatedContainer(duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                      color: _crop == c.$2 ? YonoColors.easeForest : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _crop == c.$2
                          ? YonoColors.easeForest : YonoColors.divider)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(c.$1, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(c.$2, style: YonoTextStyles.hindi(12,
                        color: _crop == c.$2 ? Colors.white : YonoColors.textSecondary,
                        weight: FontWeight.w600)),
                  ])))).toList()),
          const SizedBox(height: 24),
          Text('मौसम चुनें', style: YonoTextStyles.hindi(16,
              color: YonoColors.deepBlue, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._seasons.map((s) => Padding(padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() => _season = s.$2); },
              child: AnimatedContainer(duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: _season == s.$2
                        ? YonoColors.easeForest.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _season == s.$2
                        ? YonoColors.easeForest : YonoColors.divider,
                        width: _season == s.$2 ? 1.5 : 1)),
                child: Row(children: [
                  Text(s.$1, style: const TextStyle(fontSize: 24)), const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.$2, style: YonoTextStyles.hindi(15, weight: FontWeight.w600)),
                    Text(s.$3, style: YonoTextStyles.body(12, color: YonoColors.textSecondary)),
                  ])),
                  if (_season == s.$2)
                    const Icon(Icons.check_circle, color: YonoColors.easeForest, size: 22),
                ]))))),
          if (_crop != null && _season != null) ...[
            const SizedBox(height: 20),
            YonoCard(color: const Color(0xFFF0FDF4), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('फसल', style: YonoTextStyles.hindi(13, color: YonoColors.textSecondary)),
                Text(_crop!, style: YonoTextStyles.hindi(13, weight: FontWeight.w700)),
              ]),
              const Divider(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('प्रीमियम', style: YonoTextStyles.hindi(14, color: YonoColors.textSecondary)),
                Text('₹${fmt(premium)}', style: YonoTextStyles.mono(18,
                    color: YonoColors.deepBlue, weight: FontWeight.w800)),
              ]),
              const Divider(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('बीमा राशि', style: YonoTextStyles.hindi(14, color: YonoColors.textSecondary)),
                Text('₹${fmtShort(coverage)}', style: YonoTextStyles.mono(18,
                    color: YonoColors.easeForest, weight: FontWeight.w800)),
              ]),
            ])),
            const SizedBox(height: 20),
            GradientButton(
              label: _loading ? 'प्रक्रिया हो रही है…' : 'बीमा खरीदें — ₹${fmt(premium)}',
              colors: const [YonoColors.easeForest, Color(0xFF14532D)],
              icon: Icons.agriculture_outlined, height: 60, fontSize: 16,
              onTap: _loading ? null : () async {
                setState(() => _loading = true);
                await Future.delayed(const Duration(seconds: 1));
                final ok = ref.read(authProvider.notifier)
                    .buyInsurance(premium, 'फसल बीमा — $_crop', coverage);
                if (!mounted) return;
                setState(() => _loading = false);
                if (ok) {
                  context.go('/ease/success', extra: {
                  'title': 'बीमा हो गया! 🌾',
                  'subtitle': '₹${fmtShort(coverage)} का बीमा सक्रिय हुआ।', 'route': '/ease'});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('अपर्याप्त बैलेंस।'), backgroundColor: YonoColors.error));
                }
              }),
          ],
          const SizedBox(height: 24),
        ])));
  }
}

class EaseHealthInsuranceScreen extends ConsumerStatefulWidget {
  const EaseHealthInsuranceScreen({super.key});
  @override ConsumerState<EaseHealthInsuranceScreen> createState() => _EaseHealthState();
}
class _EaseHealthState extends ConsumerState<EaseHealthInsuranceScreen> {
  String? _plan; bool _loading = false;
  final _plans = [
    ('🏥','SBI Arogya Premier','आरोग्य प्रीमियर','₹5 लाख कवर',4999.0,500000.0,
     ['अस्पताल भर्ती','OPD','दवाइयां','ICU']),
    ('💊','SBI Arogya Plus','आरोग्य प्लस','₹3 लाख कवर',2999.0,300000.0,
     ['अस्पताल भर्ती','OPD','दवाइयां']),
    ('❤️','SBI Senior Shield','वरिष्ठ सुरक्षा','₹10 लाख कवर',8999.0,1000000.0,
     ['अस्पताल','OPD','दवाइयां','ICU','कैंसर','हृदय']),
  ];
  @override Widget build(BuildContext context) {
    final sel = _plan != null ? _plans.firstWhere((p) => p.$2 == _plan) : null;
    return Scaffold(backgroundColor: YonoColors.surface,
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('स्वास्थ्य बीमा', style: YonoTextStyles.hindi(18,
              color: Colors.white, weight: FontWeight.w700)),
          Text('Health Insurance Plans',
              style: YonoTextStyles.body(11, color: Colors.white54)),
        ]),
        backgroundColor: YonoColors.easeForest, foregroundColor: Colors.white),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          YonoCard(color: const Color(0xFFFFF1F2), child: Row(children: [
            const Text('❤️', style: TextStyle(fontSize: 28)), const SizedBox(width: 12),
            Expanded(child: Text('अपने स्वास्थ्य की रक्षा करें। SBI का विश्वसनीय बीमा।',
                style: YonoTextStyles.hindi(13, color: YonoColors.error))),
          ])),
          const SizedBox(height: 22),
          Text('प्लान चुनें', style: YonoTextStyles.hindi(16,
              color: YonoColors.deepBlue, weight: FontWeight.w700)),
          const SizedBox(height: 14),
          ..._plans.map((plan) {
            final isSel = _plan == plan.$2;
            return Padding(padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() => _plan = plan.$2); },
                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFFFF1F2) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isSel ? YonoColors.error : YonoColors.divider,
                          width: isSel ? 1.5 : 1),
                      boxShadow: [BoxShadow(
                          color: YonoColors.deepBlue.withValues(alpha: 0.05),
                          blurRadius: 10, offset: const Offset(0, 3))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(plan.$1, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(plan.$3, style: YonoTextStyles.hindi(16, weight: FontWeight.w700)),
                        Text(plan.$2, style: YonoTextStyles.body(12,
                            color: YonoColors.textSecondary)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('₹${fmt(plan.$5)}/वर्ष', style: YonoTextStyles.mono(15,
                            color: YonoColors.error, weight: FontWeight.w800)),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: YonoColors.successBg,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(plan.$4, style: YonoTextStyles.body(11,
                              color: YonoColors.success, weight: FontWeight.w700))),
                      ]),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: (plan.$7)
                        .map((f) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: isSel ? YonoColors.error.withValues(alpha: 0.08)
                                  : YonoColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: YonoColors.divider)),
                          child: Text(f, style: YonoTextStyles.hindi(11,
                              color: isSel ? YonoColors.error : YonoColors.textSecondary))))
                        .toList()),
                    if (isSel) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.check_circle, color: YonoColors.error, size: 18),
                        const SizedBox(width: 6),
                        Text('यह प्लान चुना गया', style: YonoTextStyles.hindi(13,
                            color: YonoColors.error, weight: FontWeight.w600)),
                      ]),
                    ],
                  ]))));
          }),
          if (sel != null) ...[
            const SizedBox(height: 8),
            GradientButton(
              label: _loading ? 'प्रक्रिया हो रही है…'
                  : 'बीमा खरीदें — ₹${fmt(sel.$5)}/वर्ष',
              colors: [YonoColors.error.withValues(alpha: 0.9), YonoColors.error],
              icon: Icons.favorite_outline, height: 62, fontSize: 16,
              onTap: _loading ? null : () async {
                setState(() => _loading = true);
                await Future.delayed(const Duration(seconds: 1));
                final ok = ref.read(authProvider.notifier)
                    .buyInsurance(sel.$5, sel.$3, sel.$6);
                if (!mounted) return;
                setState(() => _loading = false);
                if (ok) {
                  context.go('/ease/success', extra: {
                  'title': 'बीमा सक्रिय! ❤️',
                  'subtitle': '${sel.$3} — ${sel.$4} सक्रिय हुआ।', 'route': '/ease'});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('अपर्याप्त बैलेंस।'), backgroundColor: YonoColors.error));
                }
              }),
          ],
          const SizedBox(height: 24),
        ])));
  }
}