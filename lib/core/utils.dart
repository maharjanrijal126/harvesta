import 'package:intl/intl.dart';

const deliveryFee = 250.0;
const serviceFee = 120.0;
const platformFeeRate = 0.03;
const deliveryWindows = ['6–8 AM', '7–9 AM', '9–11 AM', '2–4 PM'];
const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const weekdayLong = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const productCategories = ['Fresh', 'Root', 'Leafy', 'Fruit', 'Herbs'];
const produceNames = [
  'Tomato',
  'Potato',
  'Cauliflower',
  'Carrot',
  'Cucumber',
  'Spinach',
];

double toD(dynamic v) => v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);
String npr(num v) => 'NPR ${NumberFormat('#,##0').format(v.round())}';
String kgText(num v) => '${NumberFormat('#,##0.##').format(v)} kg';
String dShort(DateTime d) => DateFormat('EEE d MMM').format(d);
String dLong(DateTime d) => DateFormat('EEE d MMM y').format(d);
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String greeting() {
  final h = DateTime.now().hour;
  return h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening');
}

String emojiFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('tomato')) return '🍅';
  if (n.contains('potato')) return '🥔';
  if (n.contains('cauli') || n.contains('broccoli')) return '🥦';
  if (n.contains('carrot')) return '🥕';
  if (n.contains('cucumber')) return '🥒';
  if (n.contains('spinach') || n.contains('leaf')) return '🥬';
  if (n.contains('onion')) return '🧅';
  if (n.contains('chili') || n.contains('pepper')) return '🌶️';
  if (n.contains('apple') || n.contains('fruit')) return '🍎';
  return '🌱';
}

String categoryFor(String produce) {
  switch (produce) {
    case 'Potato':
    case 'Carrot':
      return 'Root';
    case 'Spinach':
      return 'Leafy';
    default:
      return 'Fresh';
  }
}

String? reqV(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
String? emailV(String? v) {
  if (v == null || v.trim().isEmpty) return 'Required';
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
      ? null
      : 'Enter a valid email';
}

String? phoneV(String? v) {
  if (v == null || v.trim().isEmpty) return 'Required';
  final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.length >= 9 ? null : 'Enter a valid phone number';
}

String? passV(String? v) =>
    (v == null || v.length < 6) ? 'At least 6 characters' : null;
