import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils.dart';

DateTime _dt(dynamic v, [DateTime? fallback]) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return fallback ?? DateTime.now();
}

const defaultPrefs = <String, dynamic>{
  'notifyOrders': true,
  'notifySchedule': true,
  'language': 'en',
  'saveDrafts': true,
  'wifiOnly': true,
};

/// roles: business | farmer | admin
/// verificationStatus (farmers): pending | verified | rejected
class AppUser {
  AppUser({
    required this.uid,
    required this.role,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.businessName = '',
    this.city = '',
    this.farmName = '',
    this.location = '',
    this.farmInfo = '',
    this.verificationStatus = 'none',
    this.address = '',
    this.prefs = const {},
  });

  final String uid,
      role,
      name,
      email,
      phone,
      businessName,
      city,
      farmName,
      location,
      farmInfo,
      verificationStatus,
      address;
  final Map<String, dynamic> prefs;

  bool get isVerified => verificationStatus == 'verified';

  String get displayName {
    if (role == 'business')
      return businessName.isNotEmpty ? businessName : name;
    if (role == 'farmer') return farmName.isNotEmpty ? farmName : name;
    return name.isNotEmpty ? name : email;
  }

  String get initials {
    final parts = (name.isNotEmpty ? name : displayName).trim().split(
      RegExp(r'\s+'),
    );
    final s = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return s.isEmpty ? 'H' : s;
  }

  bool pref(String key) => (prefs[key] ?? defaultPrefs[key]) == true;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return AppUser(
      uid: d.id,
      role: (m['role'] ?? 'business') as String,
      name: (m['name'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      phone: (m['phone'] ?? '') as String,
      businessName: (m['businessName'] ?? '') as String,
      city: (m['city'] ?? '') as String,
      farmName: (m['farmName'] ?? '') as String,
      location: (m['location'] ?? '') as String,
      farmInfo: (m['farmInfo'] ?? '') as String,
      verificationStatus: (m['verificationStatus'] ?? 'none') as String,
      address: (m['address'] ?? '') as String,
      prefs: Map<String, dynamic>.from((m['prefs'] ?? {}) as Map),
    );
  }

  Map<String, dynamic> toMap() => {
    'role': role,
    'name': name,
    'email': email,
    'phone': phone,
    'businessName': businessName,
    'city': city,
    'farmName': farmName,
    'location': location,
    'farmInfo': farmInfo,
    'verificationStatus': verificationStatus,
    'address': address,
    'prefs': defaultPrefs,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

/// A harvest batch. Stored in `harvests` (status: draft | published). Sample products are never stored.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.grade,
    required this.category,
    required this.price,
    required this.qtyKg,
    required this.supplierId,
    required this.supplierName,
    required this.location,
    required this.harvestDate,
    this.collectionDate,
    this.verified = true,
    this.status = 'published',
    this.sample = false,
  });

  final String id,
      name,
      grade,
      category,
      supplierId,
      supplierName,
      location,
      status;
  final double price, qtyKg;
  final DateTime harvestDate;
  final DateTime? collectionDate;
  final bool verified, sample;

  factory Product.fromMap(String id, Map<String, dynamic> m) => Product(
    id: id,
    name: (m['name'] ?? '') as String,
    grade: (m['grade'] ?? 'A') as String,
    category: (m['category'] ?? 'Fresh') as String,
    price: toD(m['price']),
    qtyKg: toD(m['qtyKg']),
    supplierId: (m['supplierId'] ?? '') as String,
    supplierName: (m['supplierName'] ?? '') as String,
    location: (m['location'] ?? '') as String,
    harvestDate: _dt(m['harvestDate']),
    collectionDate: m['collectionDate'] == null
        ? null
        : _dt(m['collectionDate']),
    verified: (m['verified'] ?? false) == true,
    status: (m['status'] ?? 'draft') as String,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'grade': grade,
    'category': category,
    'price': price,
    'qtyKg': qtyKg,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'location': location,
    'harvestDate': Timestamp.fromDate(harvestDate),
    if (collectionDate != null)
      'collectionDate': Timestamp.fromDate(collectionDate!),
    'verified': verified,
    'status': status,
  };
}

class SupplierInfo {
  const SupplierInfo({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.onTime,
    required this.completed,
    required this.produce,
  });
  final String id, name, location;
  final double rating;
  final int onTime, completed;
  final List<String> produce;
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.grade,
    required this.price,
    required this.qtyKg,
  });
  final String productId, name, grade;
  final double price, qtyKg;
  double get total => price * qtyKg;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    productId: (m['productId'] ?? '') as String,
    name: (m['name'] ?? '') as String,
    grade: (m['grade'] ?? 'A') as String,
    price: toD(m['price']),
    qtyKg: toD(m['qtyKg']),
  );

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'grade': grade,
    'price': price,
    'qtyKg': qtyKg,
  };
}

/// status: pending | confirmed | collected | delivered | declined | cancelled
class HOrder {
  HOrder({
    this.id = '',
    required this.number,
    required this.businessId,
    required this.businessName,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.subtotal,
    required this.fees,
    required this.total,
    required this.deliveryDate,
    required this.window,
    required this.address,
    required this.payment,
    this.status = 'pending',
    this.recurring = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id,
      number,
      businessId,
      businessName,
      supplierId,
      supplierName,
      window,
      address,
      payment,
      status;
  final List<OrderItem> items;
  final double subtotal, fees, total;
  final DateTime deliveryDate, createdAt;
  final bool recurring;

  bool get isActive =>
      status == 'pending' || status == 'confirmed' || status == 'collected';
  double get totalKg => items.fold(0.0, (a, b) => a + b.qtyKg);

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'collected':
        return 'In transit';
      case 'delivered':
        return 'Delivered';
      case 'declined':
        return 'Declined';
      default:
        return 'Cancelled';
    }
  }

  factory HOrder.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
      HOrder.fromMap(d.id, d.data());

  factory HOrder.fromMap(String id, Map<String, dynamic> m) => HOrder(
    id: id,
    number: (m['number'] ?? '') as String,
    businessId: (m['businessId'] ?? '') as String,
    businessName: (m['businessName'] ?? '') as String,
    supplierId: (m['supplierId'] ?? '') as String,
    supplierName: (m['supplierName'] ?? '') as String,
    items: ((m['items'] ?? []) as List)
        .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
    subtotal: toD(m['subtotal']),
    fees: toD(m['fees']),
    total: toD(m['total']),
    deliveryDate: _dt(m['deliveryDate']),
    window: (m['window'] ?? '') as String,
    address: (m['address'] ?? '') as String,
    payment: (m['payment'] ?? 'Cash on delivery') as String,
    status: (m['status'] ?? 'pending') as String,
    recurring: (m['recurring'] ?? false) == true,
    createdAt: _dt(m['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'number': number,
    'businessId': businessId,
    'businessName': businessName,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'items': items.map((e) => e.toMap()).toList(),
    'subtotal': subtotal,
    'fees': fees,
    'total': total,
    'deliveryDate': Timestamp.fromDate(deliveryDate),
    'window': window,
    'address': address,
    'payment': payment,
    'status': status,
    'recurring': recurring,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class ScheduleLine {
  ScheduleLine({
    required this.name,
    required this.grade,
    required this.price,
    required this.qtyKg,
  });
  final String name, grade;
  final double price;
  double qtyKg;

  factory ScheduleLine.fromMap(Map<String, dynamic> m) => ScheduleLine(
    name: (m['name'] ?? '') as String,
    grade: (m['grade'] ?? 'A') as String,
    price: toD(m['price']),
    qtyKg: toD(m['qtyKg']),
  );
  Map<String, dynamic> toMap() => {
    'name': name,
    'grade': grade,
    'price': price,
    'qtyKg': qtyKg,
  };
}

/// Recurring order template. weekdays use DateTime.weekday numbers (Mon = 1 ... Sun = 7).
class Schedule {
  Schedule({
    this.id = '',
    required this.businessId,
    required this.title,
    required this.supplierId,
    required this.supplierName,
    required this.lines,
    required this.weekdays,
    required this.window,
    required this.startDate,
    this.paused = false,
  });

  final String id, businessId, supplierId, supplierName;
  String title, window;
  final List<ScheduleLine> lines;
  List<int> weekdays;
  DateTime startDate;
  bool paused;

  double get perDelivery => lines.fold(0.0, (a, b) => a + b.price * b.qtyKg);

  DateTime? get nextDelivery {
    final today = dayOnly(DateTime.now());
    final from = startDate.isAfter(today) ? dayOnly(startDate) : today;
    for (var i = 0; i < 8; i++) {
      final c = from.add(Duration(days: i));
      if (weekdays.contains(c.weekday)) return c;
    }
    return null;
  }

  String get weekdayText =>
      ([...weekdays]..sort()).map((d) => weekdayLong[d - 1]).join(' • ');

  factory Schedule.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return Schedule(
      id: d.id,
      businessId: (m['businessId'] ?? '') as String,
      title: (m['title'] ?? 'Weekly pack') as String,
      supplierId: (m['supplierId'] ?? '') as String,
      supplierName: (m['supplierName'] ?? '') as String,
      lines: ((m['lines'] ?? []) as List)
          .map((e) => ScheduleLine.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      weekdays: ((m['weekdays'] ?? []) as List)
          .map((e) => (e as num).toInt())
          .toList(),
      window: (m['window'] ?? deliveryWindows[1]) as String,
      startDate: _dt(m['startDate']),
      paused: (m['paused'] ?? false) == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'businessId': businessId,
    'title': title,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'lines': lines.map((e) => e.toMap()).toList(),
    'weekdays': weekdays,
    'window': window,
    'startDate': Timestamp.fromDate(startDate),
    'paused': paused,
  };
}
