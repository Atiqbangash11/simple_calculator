from pathlib import Path

path = Path(r'e:\new and new\simple_calculator\lib\main.dart')
text = path.read_text(encoding='utf-8')
old = """class NewSaleBottomSheet extends StatefulWidget {
  const NewSaleBottomSheet({super.key});

  @override
  State<NewSaleBottomSheet> createState() => _NewSaleBottomSheetState();
}

class _NewSaleBottomSheetState extends State<NewSaleBottomSheet> {
  final Map<Product, int> cart = {};
  double paidAmount = 0.0;
  String customerName = '';
  String customerPhone = '';

  @override
  Widget build(BuildContext context) {
    final shop = Provider.of<StockProvider>(context);
    double totalCart = cart.entries.fold(0.0, (sum, entry) => sum + (entry.key.sellingPrice * entry.value));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const Text('New Sale / Cart', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            const Text('Available Products (Tap to Add):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: shop.products.length,
                itemBuilder: (context, index) {
                  final p = shop.products[index];
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ActionChip(
                      label: Text('${p.name} (Rs.${p.sellingPrice.toStringAsFixed(2)})'),
                      onPressed: () {
                        setState(() {
                          cart[p] = (cart[p] ?? 0) + 1;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  ...cart.entries.map((entry) => ListTile(
                        title: Text(entry.key.name),
                        subtitle: Text('Price: Rs.${entry.key.sellingPrice.toStringAsFixed(2)} x ${entry.value}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  if (cart[entry.key]! > 1) {
                                    cart[entry.key] = cart[entry.key]! - 1;
                                  } else {
                                    cart.remove(entry.key);
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  cart[entry.key] = cart[entry.key]! + 1;
                                });
                              },
                            ),
                          ],
                        ),
                      )),
                  if (cart.isNotEmpty) ...[
                    const Divider(),
                    Text('Grand Total: Rs.${totalCart.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Amount Paid (Rs.)', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) => paidAmount = double.tryParse(val) ?? 0.0,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Customer Name (Optional)', border: OutlineInputBorder()),
                      onChanged: (val) => customerName = val,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Customer Phone (Optional)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      onChanged: (val) => customerPhone = val,
                    ),
                  ]
                ],
              ),
            ),
            if (cart.isNotEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.green),
                onPressed: () {
                  shop.recordSale(
                    cartItems: cart.entries.toList(),
                    amountPaid: paidAmount,
                    customerName: customerName,
                    customerPhone: customerPhone,
                    notes: '',
                  );
                  Navigator.pop(context);
                },
                child: const Text('Confirm Order', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
"""
new = """class NewSaleBottomSheet extends StatefulWidget {
  const NewSaleBottomSheet({super.key});

  @override
  State<NewSaleBottomSheet> createState() => _NewSaleBottomSheetState();
}

class _NewSaleBottomSheetState extends State<NewSaleBottomSheet> {
  final Map<Product, int> cart = {};
  int _currentStep = 0; // 0 = Quick Cart Grid, 1 = Final Checkout
  String searchQuery = '';
  double paidAmount = 0.0;
  String customerName = '';
  String customerPhone = '';

  IconData _getCategoryIcon(Product p) {
    final name = p.name.toLowerCase();
    final cat = p.category.toLowerCase();
    if (name.contains('milk') || name.contains('water') || cat.contains('bev')) {
      return Icons.local_drink;
    }
    if (name.contains('sugar') || name.contains('tea') || cat.contains('groc')) {
      return Icons.kitchen;
    }
    if (cat.contains('snack')) return Icons.fastfood;
    if (cat.contains('elect')) return Icons.devices;
    if (cat.contains('cloth')) return Icons.checkroom;
    return Icons.shopping_bag;
  }

  @override
  Widget build(BuildContext context) {
    final shop = Provider.of<StockProvider>(context);
    final filteredProducts = shop.products
        .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    int totalCartItems = cart.values.fold(0, (sum, qty) => sum + qty);
    double grandTotal = cart.entries.fold(
        0.0, (sum, entry) => sum + (entry.key.sellingPrice * entry.value));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _currentStep == 0
          ? _buildQuickCartGrid(shop, filteredProducts, totalCartItems)
          : _buildCheckoutSummary(shop, grandTotal),
    );
  }

  // STEP 1: Quick Cart Grid Selection View
  Widget _buildQuickCartGrid(
      StockProvider shop, List<Product> products, int totalCartItems) {
    return Column(
      children: [
        const Text(
          'Quick Cart - Today',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (val) => setState(() => searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search Products...',
            prefixIcon: const Icon(Icons.search, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            filled: true,
            fillColor: const Color(0xFF2C323B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Available Products (Tappable):',
            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('No products found', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final inCartQty = cart[p] ?? 0;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          cart[p] = inCartQty + 1;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C323B),
                          borderRadius: BorderRadius.circular(12),
                          border: inCartQty > 0
                              ? Border.all(color: Colors.blueAccent, width: 1.5)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: inCartQty > 0 ? Colors.blueAccent : Colors.grey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  inCartQty > 0 ? 'x$inCartQty' : '+ Add',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_getCategoryIcon(p), size: 32, color: Colors.orangeAccent),
                                  const SizedBox(height: 6),
                                  Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rs. ${p.sellingPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Items In Cart: $totalCartItems',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: cart.isEmpty
                  ? null
                  : () {
                      setState(() => _currentStep = 1);
                    },
              child: const Text('Continue to Total'),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 2: Checkout & Payment Summary View
  Widget _buildCheckoutSummary(StockProvider shop, double grandTotal) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _currentStep = 0),
            ),
            const Text(
              'Checkout Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Divider(),
        Expanded(
          child: ListView(
            children: [
              ...cart.entries.map(
                (entry) => ListTile(
                  title: Text(entry.key.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Rs. ${entry.key.sellingPrice.toStringAsFixed(0)} x ${entry.value}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            if (cart[entry.key]! > 1) {
                              cart[entry.key] = cart[entry.key]! - 1;
                            } else {
                              cart.remove(entry.key);
                            }
                          });
                        },
                      ),
                      Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                        onPressed: () {
                          setState(() {
                            cart[entry.key] = cart[entry.key]! + 1;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Text(
                'Grand Total: Rs. ${grandTotal.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount Paid (Rs.)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => paidAmount = double.tryParse(val) ?? 0.0,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Customer Name (Optional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => customerName = val,
              ),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Customer Phone (Optional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => customerPhone = val,
              ),
            ],
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            shop.recordSale(
              cartItems: cart.entries.toList(),
              amountPaid: paidAmount,
              customerName: customerName,
              customerPhone: customerPhone,
              notes: '',
            );
            Navigator.pop(context);
          },
          child: const Text('Confirm Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }
}
"""

if old not in text:
    raise SystemExit('Old block not found')

path.write_text(text.replace(old, new), encoding='utf-8')
"

with open('e:\new and new\simple_calculator\replace_newsale.py', 'w', encoding='utf-8') as f:
    f.write($script)
