import 'models.dart';

/// Sample catalogue shown alongside live farmer batches (the design uses sample data).
class SupplierMeta {
  const SupplierMeta(this.rating, this.onTime, this.completed);
  final double rating;
  final int onTime, completed;
}

const sampleSupplierMeta = <String, SupplierMeta>{
  's_green': SupplierMeta(4.9, 98, 42),
  's_valley': SupplierMeta(4.8, 95, 31),
  's_kavre': SupplierMeta(4.7, 96, 27),
};

SupplierMeta metaFor(String supplierId) =>
    sampleSupplierMeta[supplierId] ?? const SupplierMeta(4.5, 94, 0);

List<Product> sampleProducts() {
  final today = DateTime.now();
  final h = DateTime(
    today.year,
    today.month,
    today.day,
  ).add(const Duration(days: 1));
  Product p(
    String id,
    String name,
    String cat,
    double price,
    double qty,
    String sid,
    String sname,
    String loc,
  ) => Product(
    id: id,
    name: name,
    grade: 'A',
    category: cat,
    price: price,
    qtyKg: qty,
    supplierId: sid,
    supplierName: sname,
    location: loc,
    harvestDate: h,
    collectionDate: h,
    sample: true,
  );
  return [
    p(
      'sample_1',
      'Tomato',
      'Fresh',
      95,
      120,
      's_green',
      'Green Valley Farmer Group',
      'Kavre',
    ),
    p(
      'sample_2',
      'Potato',
      'Root',
      72,
      500,
      's_green',
      'Green Valley Farmer Group',
      'Kavre',
    ),
    p(
      'sample_3',
      'Cauliflower',
      'Fresh',
      110,
      80,
      's_green',
      'Green Valley Farmer Group',
      'Kavre',
    ),
    p(
      'sample_4',
      'Carrot',
      'Root',
      68,
      60,
      's_green',
      'Green Valley Farmer Group',
      'Kavre',
    ),
    p(
      'sample_5',
      'Tomato',
      'Fresh',
      98,
      200,
      's_valley',
      'ValleyFreshProduce',
      'Bhaktapur',
    ),
    p(
      'sample_6',
      'Spinach',
      'Leafy',
      60,
      90,
      's_valley',
      'ValleyFreshProduce',
      'Bhaktapur',
    ),
    p(
      'sample_7',
      'Potato',
      'Root',
      72,
      400,
      's_kavre',
      'Kavre Fresh Co-op',
      'Kavre',
    ),
    p(
      'sample_8',
      'Cauliflower',
      'Fresh',
      108,
      150,
      's_kavre',
      'Kavre Fresh Co-op',
      'Kavre',
    ),
  ];
}

/// Build the supplier directory from the products currently on offer.
List<SupplierInfo> suppliersFrom(List<Product> products) {
  final ids = <String>[];
  for (final p in products) {
    if (!ids.contains(p.supplierId)) ids.add(p.supplierId);
  }
  return ids.map((id) {
    final mine = products.where((p) => p.supplierId == id).toList();
    final m = metaFor(id);
    final names = <String>[];
    for (final p in mine) {
      if (!names.contains(p.name)) names.add(p.name);
    }
    return SupplierInfo(
      id: id,
      name: mine.first.supplierName,
      location: mine.first.location,
      rating: m.rating,
      onTime: m.onTime,
      completed: m.completed,
      produce: names,
    );
  }).toList()..sort((a, b) => b.rating.compareTo(a.rating));
}

/// Market price guidance (NPR per kg) - admins can override in Firestore (settings/market_prices).
final Map<String, List<double>> defaultPrices = {
  'Tomato': [90, 105],
  'Potato': [65, 78],
  'Cauliflower': [100, 120],
  'Cucumber': [75, 90],
  'Carrot': [60, 75],
  'Spinach': [50, 70],
  'Mixed': [85, 110],
};
