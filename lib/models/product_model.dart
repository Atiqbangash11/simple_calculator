class Product {
  final String id;
  final String name;
  final String sku;
  final String category;
  int stockQuantity;
  final double costPrice; // Buy Price: what the shopkeeper paid the supplier

  // DEPRECATED (kept for DB backward-compatibility only).
  // The app used to store a fixed "Sell Price" on every product. That field
  // is no longer shown or edited in the UI and is no longer used anywhere to
  // calculate sales or profit - the actual price charged to the customer is
  // now entered per item at the moment of each sale (see SaleItem.salePriceAtSale
  // below). This field is retained only because the existing SQLite `products`
  // table has a NOT NULL `sellingPrice` column and old rows already contain a
  // value for it; removing it would require a destructive column migration.
  // New/edited products always persist this as 0.0.
  final double sellingPrice;

  final int lowStockThreshold;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.stockQuantity,
    required this.costPrice,
    this.sellingPrice = 0.0,
    required this.lowStockThreshold,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'stockQuantity': stockQuantity,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'lowStockThreshold': lowStockThreshold,
    };
  }

  // Hardened fromMap method to prevent type runtime casting crashes
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      sku: map['sku'] as String,
      category: map['category'] as String,
      stockQuantity: (map['stockQuantity'] as num).toInt(),
      costPrice: (map['costPrice'] as num).toDouble(),
      // Tolerate old/new rows either way - never crash on this legacy column.
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      lowStockThreshold: (map['lowStockThreshold'] as num).toInt(),
    );
  }

  Product copyWith({
    String? name,
    String? sku,
    String? category,
    int? stockQuantity,
    double? costPrice,
    double? sellingPrice,
    int? lowStockThreshold,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }
}

/// A single product line within a completed sale.
///
/// This captures a FROZEN snapshot of both the Buy Price and the Actual Sale
/// Price at the exact moment the sale was made. Editing a product's Buy Price
/// later must never change the numbers on a past sale - so past transactions
/// never read Product.costPrice again, they read these stored values instead.
class SaleItem {
  final String productId;
  final String productName;
  final int quantity;

  /// Product.costPrice at the time of sale (per item).
  final double buyPriceAtSale;

  /// Actual price charged to the customer for this item (per item, NOT total).
  final double salePriceAtSale;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.buyPriceAtSale,
    required this.salePriceAtSale,
  });

  double get totalBuyCost => buyPriceAtSale * quantity;
  double get totalSaleAmount => salePriceAtSale * quantity;

  /// Positive = profit, negative = loss.
  double get profit => totalSaleAmount - totalBuyCost;
}

class SaleTransaction {
  final String id;
  final List<SaleItem> items;

  /// Total amount charged to the customer for this sale, frozen at sale time
  /// (sum of each item's Actual Sale Price x quantity).
  final double totalAmount;
  double amountPaid;
  final String customerName;
  final String customerPhone;
  final String notes;
  final DateTime timestamp;

  SaleTransaction({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.amountPaid,
    required this.customerName,
    required this.customerPhone,
    required this.notes,
    required this.timestamp,
  });

  double get debt => totalAmount - amountPaid;

  /// Total of what the shopkeeper paid the supplier for everything in this sale.
  double get totalBuyCost => items.fold(0.0, (sum, i) => sum + i.totalBuyCost);

  /// Positive = profit, negative = loss. Always derived from the frozen
  /// per-item snapshots, so it never changes if inventory Buy Price changes later.
  double get profit => totalAmount - totalBuyCost;
}
