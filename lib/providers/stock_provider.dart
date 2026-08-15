import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/db_helper.dart';

class StockProvider extends ChangeNotifier {
  final List<Product> _products = [];
  final List<SaleTransaction> _transactions = [];
  String _searchQuery = '';

  List<Product> get products {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.sku.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<SaleTransaction> get transactions => _transactions;
  String get searchQuery => _searchQuery;

  set searchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  double get todaySales => _transactions.fold(0.0, (sum, t) => sum + t.totalAmount);

  // Profit is always derived from the frozen Buy Price / Sale Price snapshot
  // stored on each SaleItem at the time of sale - never from the product's
  // current (possibly later-edited) costPrice.
  double get todayProfit => _transactions.fold(0.0, (sum, t) => sum + t.profit);

  double get monthlySales {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.timestamp.month == now.month && t.timestamp.year == now.year)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  double get monthlyProfit {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.timestamp.month == now.month && t.timestamp.year == now.year)
        .fold(0.0, (sum, t) => sum + t.profit);
  }

  double get totalDebts => _transactions.fold(0.0, (sum, t) => sum + t.debt);

  int get lowStockCount => _products.where((p) => p.stockQuantity <= p.lowStockThreshold).length;

  List<Product> get lowStockProducts =>
      _products.where((p) => p.stockQuantity <= p.lowStockThreshold).toList();

  Future<void> loadProducts() async {
    final fetched = await DBHelper.instance.fetchProducts();
    _products
      ..clear()
      ..addAll(fetched);
    notifyListeners();
  }

  Future<void> addProduct(
    String name,
    String sku,
    String category,
    int stock,
    double cost,
    int threshold,
  ) async {
    final newProduct = Product(
      id: DateTime.now().toString(),
      name: name,
      sku: sku,
      category: category,
      stockQuantity: stock,
      costPrice: cost,
      // sellingPrice is deprecated and no longer collected from the user -
      // see the note on Product.sellingPrice.
      sellingPrice: 0.0,
      lowStockThreshold: threshold,
    );

    await DBHelper.instance.insertProduct(newProduct);
    _products.add(newProduct);
    notifyListeners();
  }

  Future<void> updateProduct(Product updatedProduct) async {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index == -1) return;

    _products[index] = updatedProduct;
    await DBHelper.instance.updateProduct(updatedProduct);
    notifyListeners();
  }

  Future<void> deleteProduct(Product product) async {
    await DBHelper.instance.deleteProduct(product.id);
    _products.removeWhere((p) => p.id == product.id);
    notifyListeners();
  }

  /// Records a completed sale.
  ///
  /// [items] must already contain the frozen Buy Price and Actual Sale Price
  /// per item (see SaleItem) - this is what makes historical profit/loss
  /// immune to later edits of a product's inventory Buy Price.
  Future<void> recordSale({
    required List<SaleItem> items,
    required double amountPaid,
    required String customerName,
    required String customerPhone,
    required String notes,
  }) async {
    final total = items.fold(0.0, (sum, item) => sum + item.totalSaleAmount);

    for (var item in items) {
      final prodIndex = _products.indexWhere((p) => p.id == item.productId);
      if (prodIndex == -1) continue;
      final prod = _products[prodIndex];
      // Never allow selling more than what's in stock.
      final qtyToDeduct = item.quantity > prod.stockQuantity ? prod.stockQuantity : item.quantity;
      prod.stockQuantity -= qtyToDeduct;
      await DBHelper.instance.updateProduct(prod);
    }

    _transactions.add(SaleTransaction(
      id: DateTime.now().toString(),
      items: items,
      totalAmount: total,
      amountPaid: amountPaid,
      customerName: customerName,
      customerPhone: customerPhone,
      notes: notes,
      timestamp: DateTime.now(),
    ));

    notifyListeners();
  }

  void recordPayment(String transactionId, double amount) {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index == -1) return;
    _transactions[index].amountPaid += amount;
    notifyListeners();
  }
}
