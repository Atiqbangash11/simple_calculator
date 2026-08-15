import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/product_model.dart';
import 'providers/stock_provider.dart';
import 'providers/voice_notes_provider.dart';
import 'screens/voice_notes_screen.dart';

void main() async {
  // SQLite Database ke liye yeh line lazmi hai
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        // App khulte hi database se stock load karne ke liye ..loadProducts()
        ChangeNotifierProvider(create: (context) => StockProvider()..loadProducts()),
        ChangeNotifierProvider(create: (context) => VoiceNotesProvider()..loadNotes()),
      ],
      child: const ShopApp(),
    ),
  );
}

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trackly',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.orangeAccent,
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// ==================== MAIN UI VIEW SCREEN ====================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<StockProvider>(context, listen: false);

    final List<Widget> screens = [
      DashboardScreen(
        onNewSaleClick: () => _openNewSaleSheet(context),
        onAddProductClick: () => _openAddProductDialog(context),
      ),
      const InventoryScreen(),
      const SalesScreen(),
      const VoiceNotesScreen(),
      const CreditsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.storefront, color: Colors.blueAccent, size: 28),
            SizedBox(width: 12),
            Text('Shop Record Keeper', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
      ),
      body: screens[_currentTabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) => setState(() => _currentTabIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Sales Logs'),
          NavigationDestination(icon: Icon(Icons.mic), label: 'Voice Notes'),
          NavigationDestination(icon: Icon(Icons.request_quote), label: 'Credit Book'),
        ],
      ),
      floatingActionButton: _buildFab(context, shopProvider),
    );
  }

  Widget? _buildFab(BuildContext context, StockProvider provider) {
    if (_currentTabIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: () => _openAddProductDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Product', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (_currentTabIndex == 0) {
      return FloatingActionButton.extended(
        onPressed: () => _openNewSaleSheet(context),
        icon: const Icon(Icons.point_of_sale),
        label: const Text('New Sale', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (_currentTabIndex == 3) {
      return FloatingActionButton.extended(
        onPressed: () => _openRecordVoiceNoteSheet(context),
        icon: const Icon(Icons.mic),
        label: const Text('New Voice Note', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return null;
  }

  void _openAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddEditProductDialog(),
    );
  }

  void _openNewSaleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const NewSaleBottomSheet(),
    );
  }

  void _openRecordVoiceNoteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const RecordVoiceNoteSheet(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNewSaleClick;
  final VoidCallback onAddProductClick;

  const DashboardScreen({
    super.key,
    required this.onNewSaleClick,
    required this.onAddProductClick,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<StockProvider>(
      builder: (context, shop, child) {
        // Format current date as "13 August 2026"
        final now = DateTime.now();
        final months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        final formattedDate = '${now.day} ${months[now.month - 1]} ${now.year}';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.blueAccent.withAlpha(38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Daily Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          const SizedBox(height: 4),
                          const Text('Track your sales, profit, and customer credits.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withAlpha(60),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '📅 $formattedDate',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.analytics, size: 48, color: Colors.blueAccent),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard('Today\'s Sales', 'Rs.${shop.todaySales.toStringAsFixed(2)}', Icons.monetization_on, Colors.blueAccent),
                _buildStatCard('Today\'s Profit', 'Rs.${shop.todayProfit.toStringAsFixed(2)}', Icons.trending_up, Colors.green),
                _buildStatCard('Monthly Sales', 'Rs.${shop.monthlySales.toStringAsFixed(2)}', Icons.calendar_month, Colors.lightBlueAccent),
                _buildStatCard('Monthly Profit', 'Rs.${shop.monthlyProfit.toStringAsFixed(2)}', Icons.query_stats, Colors.tealAccent),
                _buildStatCard('Unpaid Udhar', 'Rs.${shop.totalDebts.toStringAsFixed(2)}', Icons.request_quote, Colors.redAccent),
                _buildStatCard('Low Stock Items', '${shop.lowStockCount}', Icons.warning, shop.lowStockCount > 0 ? Colors.orange : Colors.grey),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Low Stock Warnings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (shop.lowStockProducts.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Text('All inventory levels are safe!', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            else
              ...shop.lowStockProducts.map((p) => _buildLowStockCard(context, p)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockCard(BuildContext context, Product p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.orangeAccent),
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Stock: ${p.stockQuantity} (Threshold: ${p.lowStockThreshold})'),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withAlpha(51)),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AddEditProductDialog(product: p),
            );
          },
          child: const Text('Restock', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
        ),
      ),
    );
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String selectedCategory = 'All';
  final categories = ["All", "Grocery", "Beverages", "Snacks", "Electronics", "Clothing", "Cosmetics", "Other"];

  @override
  Widget build(BuildContext context) {
    return Consumer<StockProvider>(
      builder: (context, shop, child) {
        final filteredList = selectedCategory == 'All'
            ? shop.products
            : shop.products.where((p) => p.category == selectedCategory).toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                onChanged: (val) => shop.searchQuery = val,
                decoration: InputDecoration(
                  labelText: 'Search product...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: shop.searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () => shop.searchQuery = '')
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: selectedCategory == cat,
                        onSelected: (selected) => setState(() => selectedCategory = cat),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No products found.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final p = filteredList[index];
                          return Card(
                            child: ListTile(
                              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Category: ${p.category} | SKU: ${p.sku}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Buy: Rs.${p.costPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                  Text('Qty: ${p.stockQuantity}', style: TextStyle(color: p.stockQuantity <= p.lowStockThreshold ? Colors.orange : Colors.green)),
                                ],
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AddEditProductDialog(product: p),
                                );
                              },
                            ),
                          );
                        },
                      ),
              )
            ],
          ),
        );
      },
    );
  }
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  bool _filterByDay = true; // true = Day filter, false = Month filter
  late DateTime _selectedDate;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedMonth = DateTime.now();
  }

  List<SaleTransaction> _getFilteredTransactions(List<SaleTransaction> allTransactions) {
    if (_filterByDay) {
      // Filter by exact date
      return allTransactions.where((tx) {
        return tx.timestamp.year == _selectedDate.year &&
            tx.timestamp.month == _selectedDate.month &&
            tx.timestamp.day == _selectedDate.day;
      }).toList();
    } else {
      // Filter by month and year
      return allTransactions.where((tx) {
        return tx.timestamp.year == _selectedMonth.year &&
            tx.timestamp.month == _selectedMonth.month;
      }).toList();
    }
  }

  String _formatDateDisplay(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatMonthDisplay(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _openMonthPicker() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Month & Year'),
        content: SizedBox(
          width: 300,
          height: 250,
          child: Column(
            children: [
              const Text('Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final months = [
                      'January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December'
                    ];
                    final isSelected = _selectedMonth.month == index + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMonth = DateTime(_selectedMonth.year, index + 1);
                        });
                      },
                      child: Container(
                        color: isSelected ? Colors.blueAccent.withAlpha(80) : Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Text(
                          months[index],
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Text('Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final year = DateTime.now().year - 2 + index;
                    final isSelected = _selectedMonth.year == year;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMonth = DateTime(year, _selectedMonth.month);
                        });
                      },
                      child: Container(
                        color: isSelected ? Colors.blueAccent.withAlpha(80) : Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Text(
                          '$year',
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = Provider.of<StockProvider>(context);
    final filteredTransactions = _getFilteredTransactions(shop.transactions);
    final totalSales = filteredTransactions.fold<double>(0.0, (sum, tx) => sum + tx.totalAmount);
    final totalBuyCost = filteredTransactions.fold<double>(0.0, (sum, tx) => sum + tx.totalBuyCost);
    final totalProfit = filteredTransactions.fold<double>(0.0, (sum, tx) => sum + tx.profit);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filter tabs
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Day'),
                  selected: _filterByDay,
                  onSelected: (selected) {
                    if (selected) setState(() => _filterByDay = true);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Month'),
                  selected: !_filterByDay,
                  onSelected: (selected) {
                    if (selected) setState(() => _filterByDay = false);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date/Month selector
          if (_filterByDay)
            Card(
              color: Colors.blueAccent.withAlpha(35),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatDateDisplay(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openDatePicker,
                      icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                      label: const Text('Change', style: TextStyle(fontSize: 12, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              color: Colors.blueAccent.withAlpha(35),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatMonthDisplay(_selectedMonth),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openMonthPicker,
                      icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                      label: const Text('Change', style: TextStyle(fontSize: 12, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Total sales / buy cost / profit for the selected period
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withAlpha(80)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Sales:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      'Rs. ${totalSales.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Buy Cost:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      'Rs. ${totalBuyCost.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      totalProfit >= 0 ? 'Total Profit:' : 'Total Loss:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: totalProfit >= 0 ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    Text(
                      'Rs. ${totalProfit.abs().toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: totalProfit >= 0 ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Transactions list
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 56, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No sales found for this period.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTransactions[index];
                      return _buildTransactionCard(tx);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ==================== Customer Transaction Card (redesigned) ====================
  // Matches the screenshot reference: name + status badge, time, divider,
  // Total/Paid two-column row, divider, highlighted Balance Due box (only
  // when there's an outstanding balance), divider, Buy Cost/Profit row.
  // Every value below is pulled straight from the given SaleTransaction -
  // nothing here is hard-coded.
  Widget _buildTransactionCard(SaleTransaction tx) {
    final bool isDue = tx.debt > 0.01;
    // Dynamic status colour: red for an outstanding balance, green when fully
    // paid. If more status types are added later, extend this mapping.
    final Color statusColor = isDue ? Colors.redAccent : Colors.greenAccent;
    final String statusLabel = isDue ? 'DUE' : 'PAID';
    final String displayName = tx.customerName.trim().isEmpty ? 'Walk-in Customer' : tx.customerName;
    final bool isProfit = tx.profit >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2029),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: customer name + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Time (existing dynamic timestamp, just formatted for display)
            Text(
              _formatTxTimestamp(tx.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Colors.white12),
            const SizedBox(height: 10),
            // Total / Paid two-column row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        'Rs. ${tx.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Paid', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${tx.amountPaid.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
            // Highlighted Balance Due box - only rendered when a balance is
            // actually outstanding for this transaction.
            if (isDue) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: Colors.white12),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Colors.redAccent),
                        SizedBox(width: 6),
                        Text(
                          'Balance due',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    Text(
                      'Rs. ${tx.debt.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1, color: Colors.white12),
            const SizedBox(height: 8),
            // Buy Cost / Profit bottom row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Buy Cost: Rs. ${tx.totalBuyCost.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '${isProfit ? "Profit" : "Loss"}: Rs. ${tx.profit.abs().toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isProfit ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTxTimestamp(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour12:$minute $period';
    if (isToday) {
      return 'Today, $timeStr';
    }
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $timeStr';
  }
}

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = Provider.of<StockProvider>(context);
    final debtTxList = shop.transactions.where((t) => t.debt > 0.01).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: debtTxList.isEmpty
          ? const Center(child: Text('No unpaid balances inside Credit Book!', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: debtTxList.length,
              itemBuilder: (context, index) {
                final tx = debtTxList[index];
                return Card(
                  child: ListTile(
                    title: Text(tx.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Phone: ${tx.customerPhone}\nRemaining: Rs.${tx.debt.toStringAsFixed(2)}'),
                    trailing: ElevatedButton(
                      onPressed: () => _openRecordPaymentDialog(context, tx),
                      child: const Text('Pay'),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _openRecordPaymentDialog(BuildContext context, SaleTransaction tx) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Payment for ${tx.customerName}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount Paid (Rs.)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0.0;
              if (val > 0) {
                Provider.of<StockProvider>(context, listen: false).recordPayment(tx.id, val);
              }
              Navigator.pop(context);
            },
            child: const Text('Record'),
          )
        ],
      ),
    );
  }
}

class AddEditProductDialog extends StatefulWidget {
  final Product? product;
  const AddEditProductDialog({super.key, this.product});

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late String name, category;
  late int stock, threshold;
  late double cost;
  late TextEditingController _stockController;
  late TextEditingController _thresholdController;
  late TextEditingController _costController;

  final categories = ["Grocery", "Beverages", "Snacks", "Electronics", "Clothing", "Cosmetics", "Other"];

  @override
  void initState() {
    super.initState();
    name = widget.product?.name ?? '';
    category = widget.product?.category ?? 'Grocery';
    stock = widget.product?.stockQuantity ?? 0;
    threshold = widget.product?.lowStockThreshold ?? 5;
    cost = widget.product?.costPrice ?? 0.0;
    _stockController = TextEditingController(text: stock.toString());
    _thresholdController = TextEditingController(text: threshold.toString());
    _costController = TextEditingController(text: cost.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _stockController.dispose();
    _thresholdController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _updateStock(int delta) {
    setState(() {
      stock = (stock + delta).clamp(0, 9999);
      _stockController.text = stock.toString();
    });
  }

  InputDecoration _fieldDecoration({required String label, String? hint, Widget? suffix, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: const Color(0xFF232A33),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      buttonPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      backgroundColor: const Color(0xFF2C323B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              widget.product == null ? 'Add New Item' : 'Edit Item',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          if (widget.product != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                Provider.of<StockProvider>(context, listen: false).deleteProduct(widget.product!);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: name,
                  decoration: _fieldDecoration(label: 'Item Name', hint: 'Saman ka naam'),
                  style: const TextStyle(color: Colors.white),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  onChanged: (val) => name = val,
                  onSaved: (val) => name = val!.trim(),
                ),
                const SizedBox(height: 10),
                const Text('Category', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        dropdownColor: const Color(0xFF2C323B),
                        decoration: _fieldDecoration(label: 'Category'),
                        items: categories
                            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(color: Colors.white))))
                            .toList(),
                        onChanged: (val) => setState(() => category = val ?? category),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                        child: const Text('Add New Category'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Quantity', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF232A33),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, color: Colors.white70),
                                  onPressed: () => _updateStock(-1),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _stockController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Kitna hai', hintStyle: TextStyle(color: Colors.white38)),
                                    onChanged: (val) {
                                      setState(() {
                                        stock = int.tryParse(val) ?? stock;
                                      });
                                    },
                                    onSaved: (val) => stock = int.tryParse(val ?? '0') ?? 0,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.white70),
                                  onPressed: () => _updateStock(1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text('Kitna hai', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Alert Limit', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _thresholdController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _fieldDecoration(label: 'Alert Limit', hint: 'Kam ka warning'),
                            onSaved: (val) => threshold = int.tryParse(val ?? '5') ?? 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    label: 'Buy Price',
                    hint: 'Kharid rate (price paid to supplier)',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Text('Rs.', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      cost = double.tryParse(val) ?? 0.0;
                    });
                  },
                  onSaved: (val) => cost = double.tryParse(val ?? '0.0') ?? 0.0,
                ),
                const SizedBox(height: 6),
                const Text(
                  'The actual sale price is entered when you make a sale, not here.',
                  style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E242B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    'Total Kharid: Rs.${(stock * cost).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final provider = Provider.of<StockProvider>(context, listen: false);
              if (widget.product == null) {
                provider.addProduct(name, '', category, stock, cost, threshold);
              } else {
                provider.updateProduct(widget.product!.copyWith(
                  name: name,
                  category: category,
                  stockQuantity: stock,
                  costPrice: cost,
                  lowStockThreshold: threshold,
                ));
              }
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.save, size: 18, color: Colors.white),
          label: const Text('Save', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
        ),
      ],
    );
  }
}
class NewSaleBottomSheet extends StatefulWidget {
  const NewSaleBottomSheet({super.key});

  @override
  State<NewSaleBottomSheet> createState() => _NewSaleBottomSheetState();
}

class _NewSaleBottomSheetState extends State<NewSaleBottomSheet> {
  final Map<Product, int> cart = {};
  int _currentStep = 0; // 0 = Quick Cart, 1 = Checkout
  String searchQuery = '';
  double paidAmount = 0.0;
  String customerName = '';
  String customerPhone = '';

  // Actual Sale Price entered PER ITEM for each product in the cart, keyed by
  // product id. This is what the customer is actually being charged - it is
  // independent of the product's stored Buy Price.
  final Map<String, double> salePrices = {};
  final Map<String, TextEditingController> _salePriceControllers = {};

  @override
  void dispose() {
    for (final c in _salePriceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

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

  int _quantity(Product product) => cart[product] ?? 0;

  void _addToCart(Product product) {
    final current = _quantity(product);
    if (current >= product.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name}: stock limit reached')),
      );
      return;
    }
    setState(() => cart[product] = current + 1);
  }

  void _removeFromCart(Product product) {
    final current = _quantity(product);
    if (current <= 1) {
      setState(() => cart.remove(product));
    } else {
      setState(() => cart[product] = current - 1);
    }
  }

  void _setPaidAmount(double amount) {
    setState(() => paidAmount = amount);
  }

  @override
  Widget build(BuildContext context) {
    final shop = Provider.of<StockProvider>(context);
    final filteredProducts = shop.products.where((p) {
      final query = searchQuery.trim().toLowerCase();
      return query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query);
    }).toList();

    final totalCartItems = cart.values.fold<int>(0, (sum, qty) => sum + qty);
    final grandTotal = cart.entries.fold<double>(
      0.0,
      (sum, entry) => sum + ((salePrices[entry.key.id] ?? 0.0) * entry.value),
    );

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: EdgeInsets.only(
          top: 12,
          left: 14,
          right: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _currentStep == 0
            ? _buildQuickCartGrid(shop, filteredProducts, totalCartItems, grandTotal)
            : _buildCheckoutSummary(shop, grandTotal),
      ),
    );
  }

  Widget _buildQuickCartGrid(
    StockProvider shop,
    List<Product> products,
    int totalCartItems,
    double grandTotal,
  ) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'New Sale',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            if (totalCartItems > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withAlpha(35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalCartItems items',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          autofocus: false,
          onChanged: (val) => setState(() => searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search product, category or SKU...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => searchQuery = ''),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            filled: true,
            fillColor: const Color(0xFF2C323B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.touch_app, size: 16, color: Colors.orangeAccent),
            const SizedBox(width: 6),
            Text(
              '${products.length} products available',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Spacer(),
            if (cart.isNotEmpty)
              TextButton.icon(
                onPressed: () => setState(() => cart.clear()),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear cart'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: products.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No products found', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.76,
                  ),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final qty = _quantity(p);
                    final stockEmpty = p.stockQuantity <= 0;

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C323B),
                        borderRadius: BorderRadius.circular(12),
                        border: qty > 0
                            ? Border.all(color: Colors.blueAccent, width: 1.5)
                            : Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              onTap: stockEmpty ? null : () => _addToCart(p),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(6, 8, 6, 2),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Icon(
                                          _getCategoryIcon(p),
                                          size: 30,
                                          color: stockEmpty ? Colors.grey : Colors.orangeAccent,
                                        ),
                                        if (qty > 0)
                                          Positioned(
                                            right: -12,
                                            top: -10,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.blueAccent,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                'x$qty',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      p.name,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Buy: Rs. ${p.costPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      stockEmpty ? 'Out of stock' : 'Stock: ${p.stockQuantity - qty}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: stockEmpty
                                            ? Colors.redAccent
                                            : (p.stockQuantity - qty <= p.lowStockThreshold
                                                ? Colors.orangeAccent
                                                : Colors.greenAccent),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            height: 38,
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.white10)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.remove, size: 18, color: Colors.redAccent),
                                    onPressed: qty == 0 ? null : () => _removeFromCart(p),
                                  ),
                                ),
                                Text(
                                  '$qty',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.add, size: 18, color: Colors.greenAccent),
                                    onPressed: stockEmpty || qty >= p.stockQuantity ? null : () => _addToCart(p),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF252A31),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cart Total (set price at checkout)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    Text(
                      'Rs. ${grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.greenAccent),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: cart.isEmpty ? null : () => setState(() => _currentStep = 1),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutSummary(StockProvider shop, double grandTotal) {
    final change = paidAmount > grandTotal ? paidAmount - grandTotal : 0.0;
    final debt = grandTotal > paidAmount ? grandTotal - paidAmount : 0.0;
    final isPaid = paidAmount >= grandTotal;
    final totalBuyCost = cart.entries.fold<double>(
      0.0,
      (sum, entry) => sum + (entry.key.costPrice * entry.value),
    );
    final estimatedProfit = grandTotal - totalBuyCost;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _currentStep = 0),
            ),
            const Expanded(
              child: Text(
                'Checkout',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '${cart.values.fold<int>(0, (sum, qty) => sum + qty)} items',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const Divider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              ...cart.entries.map(
                (entry) {
                  final product = entry.key;
                  final qty = entry.value;
                  final controller = _salePriceControllers.putIfAbsent(
                    product.id,
                    () => TextEditingController(
                      text: salePrices[product.id] != null && salePrices[product.id]! > 0
                          ? salePrices[product.id]!.toStringAsFixed(0)
                          : '',
                    ),
                  );
                  final salePrice = salePrices[product.id] ?? 0.0;
                  final lineTotal = salePrice * qty;
                  final lineBuyCost = product.costPrice * qty;
                  final lineProfit = lineTotal - lineBuyCost;
                  final priceEntered = salePrice > 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blueAccent.withAlpha(35),
                                child: Icon(_getCategoryIcon(product), size: 16, color: Colors.orangeAccent),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      'Buy: Rs. ${product.costPrice.toStringAsFixed(0)} each',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                onPressed: () => _removeFromCart(product),
                              ),
                              Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
                                onPressed: qty >= product.stockQuantity ? null : () => _addToCart(product),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    labelText: 'Sale Price / item (Rs.)',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      salePrices[product.id] = double.tryParse(val) ?? 0.0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rs. ${lineTotal.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (priceEntered)
                                    Text(
                                      lineProfit >= 0
                                          ? '+Rs. ${lineProfit.toStringAsFixed(0)}'
                                          : 'LOSS Rs. ${lineProfit.abs().toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: lineProfit >= 0 ? Colors.greenAccent : Colors.redAccent,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF252A31),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Buy Cost', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          'Rs. ${totalBuyCost.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total', style: TextStyle(fontSize: 15, color: Colors.grey)),
                        Text(
                          'Rs. ${grandTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.greenAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          estimatedProfit >= 0 ? 'Estimated Profit' : 'Estimated LOSS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: estimatedProfit >= 0 ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                        Text(
                          'Rs. ${estimatedProfit.abs().toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: estimatedProfit >= 0 ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) => setState(() => paidAmount = double.tryParse(val) ?? 0.0),
                      decoration: const InputDecoration(
                        labelText: 'Cash Received (Rs.)',
                        prefixIcon: Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _cashButton('Exact', grandTotal),
                        _cashButton('500', 500),
                        _cashButton('1000', 1000),
                        _cashButton('2000', 2000),
                        _cashButton('Clear', 0),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green.withAlpha(20) : Colors.redAccent.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPaid ? Colors.green.withAlpha(80) : Colors.redAccent.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isPaid ? 'Change' : 'Remaining Udhar',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Rs. ${(isPaid ? change : debt).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isPaid ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPaid) ...[
                const SizedBox(height: 10),
                const Text(
                  'Customer details for Udhar',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => customerName = val,
                ),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Customer Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => customerPhone = val,
                ),
              ],
            ],
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: isPaid ? Colors.green : Colors.orangeAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            final missingPrice = cart.keys.any((p) => (salePrices[p.id] ?? 0.0) <= 0);
            if (missingPrice) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter the Sale Price for every item')),
              );
              return;
            }
            if (grandTotal <= 0) return;
            if (!isPaid && customerName.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Udhar ke liye customer name zaroor enter karein')),
              );
              return;
            }
            final saleItems = cart.entries.map((entry) {
              final product = entry.key;
              final qty = entry.value;
              return SaleItem(
                productId: product.id,
                productName: product.name,
                quantity: qty,
                buyPriceAtSale: product.costPrice,
                salePriceAtSale: salePrices[product.id] ?? 0.0,
              );
            }).toList();
            shop.recordSale(
              items: saleItems,
              amountPaid: paidAmount,
              customerName: customerName.trim(),
              customerPhone: customerPhone.trim(),
              notes: '',
            );
            Navigator.pop(context);
          },
          icon: Icon(isPaid ? Icons.check_circle : Icons.request_quote),
          label: Text(
            isPaid ? 'CONFIRM SALE' : 'SAVE SALE + UDHAR',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _cashButton(String label, double amount) {
    return OutlinedButton(
      onPressed: () => _setPaidAmount(amount),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withAlpha(35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}
