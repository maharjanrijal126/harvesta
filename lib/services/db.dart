import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils.dart';
import '../models/models.dart';
import '../models/sample_data.dart';

/// All Firestore access in one place. Queries use a single `where` and sort on the device,
/// so no composite indexes are needed.
class Db {
  static final _f = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> _c(String n) =>
      _f.collection(n);

  // ---------- users ----------
  static Stream<AppUser?> watchUser(String uid) =>
      _c('users')
          .doc(uid)
          .snapshots()
          .map((d) => d.exists ? AppUser.fromDoc(d) : null);

  static Stream<List<AppUser>> watchUsers() =>
      _c('users').snapshots().map((s) => s.docs.map(AppUser.fromDoc).toList());

  static Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _c('users').doc(uid).update(data);

  static Future<void> setVerification(String uid, String status) =>
      _c('users').doc(uid).update({'verificationStatus': status});

  // ---------- harvest batches / catalogue ----------
  /// Published farmer batches + sample products, so the catalogue is never empty in demos.
  static Stream<List<Product>> watchProducts() =>
      _c('harvests')
          .where('status', isEqualTo: 'published')
          .snapshots()
          .map(
            (s) => [
              ...s.docs
                  .map((d) => Product.fromMap(d.id, d.data()))
                  .where((p) => p.qtyKg > 0),
              ...sampleProducts(),
            ],
          );

  static Stream<List<Product>> watchAllHarvests() => _c('harvests')
      .snapshots()
      .map((s) => s.docs.map((d) => Product.fromMap(d.id, d.data())).toList());

  static Stream<List<Product>> watchHarvests(String farmerId) => _c('harvests')
      .where('supplierId', isEqualTo: farmerId)
      .snapshots()
      .map((s) {
        final l = s.docs.map((d) => Product.fromMap(d.id, d.data())).toList();
        l.sort((a, b) => b.harvestDate.compareTo(a.harvestDate));
        return l;
      });

  static Future<void> saveHarvest(Product p) async {
    if (p.id.isEmpty) {
      await _c('harvests').add(p.toMap());
    } else {
      await _c('harvests').doc(p.id).set(p.toMap());
    }
  }

  static Future<void> setHarvestStatus(String id, String status) =>
      _c('harvests').doc(id).update({'status': status});
  static Future<void> deleteHarvest(String id) =>
      _c('harvests').doc(id).delete();

  // ---------- orders ----------
  static List<HOrder> _orders(QuerySnapshot<Map<String, dynamic>> s) {
    final l = s.docs.map(HOrder.fromDoc).toList();
    l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  static Future<void> placeOrder(HOrder o) => _c('orders').add(o.toMap());
  static Stream<List<HOrder>> watchBusinessOrders(String uid) =>
      _c('orders').where('businessId', isEqualTo: uid).snapshots().map(_orders);
  static Stream<List<HOrder>> watchSupplierOrders(String uid) =>
      _c('orders').where('supplierId', isEqualTo: uid).snapshots().map(_orders);
  static Stream<List<HOrder>> watchAllOrders() =>
      _c('orders').snapshots().map(_orders);
  static Stream<HOrder?> watchOrder(String id) =>
      _c('orders')
          .doc(id)
          .snapshots()
          .map((d) => d.exists ? HOrder.fromMap(d.id, d.data()!) : null);
  static Future<void> setOrderStatus(String id, String status) =>
      _c('orders').doc(id).update({'status': status});

  // ---------- recurring schedules ----------
  static Stream<List<Schedule>> watchSchedules(String uid) =>
      _c('schedules')
          .where('businessId', isEqualTo: uid)
          .snapshots()
          .map((s) => s.docs.map(Schedule.fromDoc).toList());
  static Future<void> addSchedule(Schedule s) => _c('schedules').add(s.toMap());
  static Future<void> saveSchedule(Schedule s) =>
      _c('schedules').doc(s.id).set(s.toMap());
  static Future<void> deleteSchedule(String id) =>
      _c('schedules').doc(id).delete();

  // ---------- market price guidance ----------
  static Stream<Map<String, List<double>>> watchPrices() =>
      _c('settings').doc('market_prices').snapshots().map((d) {
        final m = <String, List<double>>{
          for (final e in defaultPrices.entries) e.key: [...e.value],
        };
        d.data()?.forEach((k, v) {
          if (v is List && v.length == 2) m[k] = [toD(v[0]), toD(v[1])];
        });
        return m;
      });

  static Future<void> setPrice(String name, double lo, double hi) =>
      _c('settings').doc('market_prices').set({
        name: [lo, hi],
      }, SetOptions(merge: true));

  // ---------- platform settings (admin) ----------
  static const defaultPlatform = <String, dynamic>{
    'identityRequired': true,
    'groupRequired': true,
    'locationReview': true,
    'reviewTarget': '2 business days',
  };

  static Stream<Map<String, dynamic>> watchPlatform() =>
      _c('settings')
          .doc('platform')
          .snapshots()
          .map((d) => {...defaultPlatform, ...?d.data()});

  static Future<void> savePlatform(Map<String, dynamic> m) =>
      _c('settings').doc('platform').set(m, SetOptions(merge: true));

  // ---------- payouts ----------
  static Future<void> requestPayout(String farmerId, double amount) =>
      _c('payout_requests').add({
        'farmerId': farmerId,
        'amount': amount,
        'status': 'requested',
        'createdAt': FieldValue.serverTimestamp(),
      });
}
