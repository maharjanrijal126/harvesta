import 'package:flutter/foundation.dart';

import '../core/utils.dart';
import '../models/models.dart';

class CartLine {
  CartLine(this.product, this.qty);
  final Product product;
  double qty;
  double get total => product.price * qty;
}

class CartState extends ChangeNotifier {
  final List<CartLine> lines = [];
  DateTime deliveryDate = dayOnly(DateTime.now()).add(const Duration(days: 1));
  String window = deliveryWindows[1];
  bool repeat = false;
  List<int> repeatDays = [1, 4];
  String repeatTitle = 'Weekly kitchen pack';

  bool get isEmpty => lines.isEmpty;
  int get count => lines.length;
  String get supplierId => lines.isEmpty ? '' : lines.first.product.supplierId;
  String get supplierName =>
      lines.isEmpty ? '' : lines.first.product.supplierName;
  double get subtotal => lines.fold(0.0, (a, b) => a + b.total);
  double get fees => lines.isEmpty ? 0 : deliveryFee + serviceFee;
  double get total => subtotal + fees;

  /// Orders go to one supplier at a time.
  bool canAdd(Product p) => lines.isEmpty || supplierId == p.supplierId;

  void add(Product p, double qty) {
    final i = lines.indexWhere((l) => l.product.id == p.id);
    if (i >= 0) {
      lines[i].qty = (lines[i].qty + qty)
          .clamp(1, p.qtyKg > 0 ? p.qtyKg : 100000)
          .toDouble();
    } else {
      lines.add(CartLine(p, qty));
    }
    notifyListeners();
  }

  void setQty(int i, double q) {
    lines[i].qty = q < 1 ? 1 : q;
    notifyListeners();
  }

  void removeAt(int i) {
    lines.removeAt(i);
    notifyListeners();
  }

  void update({
    DateTime? date,
    String? win,
    bool? rep,
    List<int>? days,
    String? title,
  }) {
    if (date != null) deliveryDate = date;
    if (win != null) window = win;
    if (rep != null) repeat = rep;
    if (days != null) repeatDays = days;
    if (title != null) repeatTitle = title;
    notifyListeners();
  }

  void clear() {
    lines.clear();
    repeat = false;
    repeatDays = [1, 4];
    notifyListeners();
  }
}
