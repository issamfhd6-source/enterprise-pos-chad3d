import 'package:flutter/material.dart';
import 'app_database.dart';
import 'card_3d.dart';
import 'exchange_rate_controller.dart';
import 'rate_banner.dart';

class HomeScreen extends StatefulWidget {
  final AppDatabase db;
  final ExchangeRateController ctrl;

  const HomeScreen({super.key, required this.db, required this.ctrl});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _prodName = TextEditingController();
  final _prodPrice = TextEditingController(text: '10');
  String _status = 'جاهز (أوفلاين أولاً)';

  @override
  void dispose() {
    _prodName.dispose();
    _prodPrice.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    final name = _prodName.text.trim();
    final price = double.tryParse(_prodPrice.text.trim()) ?? 0;
    if (name.isEmpty || price <= 0) return;

    await widget.db.addProduct(name, price);
    _prodName.clear();
    if (!mounted) return;
    setState(() => _status = 'تمت إضافة مادة: $name');
  }

  Future<void> _addInvoice() async {
    final invNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    await widget.db.addInvoice(invNumber, 25.0);
    if (!mounted) return;
    setState(() => _status = 'تم إنشاء فاتورة بقيمة \$25.00');
  }

  Future<void> _syncAll() async {
    await widget.db.syncAllRecords();
    if (!mounted) return;
    setState(() => _status = 'تمت مزامنة السجلات المحلية');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise POS Chad 3D'),
        actions: [
          IconButton(
            icon: Icon(
              widget.ctrl.isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              widget.ctrl.toggleDark();
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card3D(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الصلاحية:'),
                DropdownButton<UserRole>(
                  value: widget.ctrl.role,
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.manager,
                      child: Text('المدير'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.branchManager,
                      child: Text('مدير فرع'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.cashier,
                      child: Text('محاسب'),
                    ),
                  ],
                  onChanged: (r) {
                    if (r != null) {
                      widget.ctrl.setRole(r);
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          RateBanner(ctrl: widget.ctrl, onChanged: () => setState(() {})),
          const SizedBox(height: 10),
          Card3D(
            child: Column(
              children: [
                TextField(
                  controller: _prodName,
                  decoration: const InputDecoration(labelText: 'اسم المادة'),
                ),
                TextField(
                  controller: _prodPrice,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'السعر (\$)'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addProduct,
                        child: const Text('إضافة مادة'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addInvoice,
                        child: const Text('فاتورة سريعة'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: _syncAll,
                  child: const Text('مزامنة السجلات'),
                ),
                const SizedBox(height: 4),
                Text(_status),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Product>>(
            stream: widget.db.watchProducts(),
            builder: (context, snap) {
              final list = snap.data ?? const [];
              return Column(
                children: list
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card3D(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.name),
                              Text(
                                '\$${item.saleUsd.toStringAsFixed(2)} | ${widget.ctrl.toNewSyp(item.saleUsd).toStringAsFixed(1)} جديدة',
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
