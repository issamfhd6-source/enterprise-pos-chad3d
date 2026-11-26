import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Table;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'main.g.dart';

enum UserRole { manager, branchManager, cashier }

class ExchangeRateController extends ChangeNotifier {
  double _usdToNewSyp = 135.0;
  final double oldToNewSypRatio = 100.0;
  UserRole _role = UserRole.manager;
  bool _dark = true;

  double get usdToNewSyp => _usdToNewSyp;
  UserRole get role => _role;
  bool get isDark => _dark;
  bool get canEditRate => _role == UserRole.manager;

  void setRole(UserRole r) {
    if (_role == r) return;
    _role = r;
    notifyListeners();
  }

  void toggleDark() {
    _dark = !_dark;
    notifyListeners();
  }

  bool updateRate(double val) {
    if (!canEditRate || val.isNaN || val.isInfinite || val <= 0) return false;
    _usdToNewSyp = val;
    notifyListeners();
    return true;
  }
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get qty => integer().withDefault(const Constant(0))();
  RealColumn get saleUsd => real().withDefault(const Constant(0.0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get number => text()();
  RealColumn get totalUsd => real().withDefault(const Constant(0.0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Products, Invoices])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _open() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'enterprise_pos_chad3d.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}

class Card3D extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const Card3D({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF132236),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class RateBanner extends StatelessWidget {
  final ExchangeRateController ctrl;
  final VoidCallback onChanged;

  const RateBanner({super.key, required this.ctrl, required this.onChanged});

  Future<void> _editRateDialog(BuildContext context) async {
    final c = TextEditingController(text: ctrl.usdToNewSyp.toString());
    final res = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سعر الصرف (المدير فقط)'),
        content: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'سعر 1 دولار بالليرة الجديدة',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(c.text.trim())),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    c.dispose();

    if (res != null && ctrl.updateRate(res)) {
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rate = ctrl.usdToNewSyp;
    final oldRate = rate * ctrl.oldToNewSypRatio;
    return Card3D(
      onTap: ctrl.canEditRate ? () => _editRateDialog(context) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '1\$ = ${rate.toStringAsFixed(2)} جديدة | ${oldRate.toStringAsFixed(0)} قديمة',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(ctrl.canEditRate ? 'تعديل' : 'عرض فقط'),
        ],
      ),
    );
  }
}

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

    await widget.db.into(widget.db.products).insert(
          ProductsCompanion.insert(
            name: name,
            saleUsd: Value(price),
          ),
        );
    _prodName.clear();
    if (!mounted) return;
    setState(() => _status = 'تمت إضافة مادة: $name');
  }

  Future<void> _addInvoice() async {
    await widget.db.into(widget.db.invoices).insert(
          InvoicesCompanion.insert(
            number: 'INV-${DateTime.now().millisecondsSinceEpoch}',
            totalUsd: const Value(25.0),
          ),
        );
    if (!mounted) return;
    setState(() => _status = 'تم إنشاء فاتورة بقيمة \$25.00');
  }

  Future<void> _syncAll() async {
    await widget.db
        .update(widget.db.products)
        .write(const ProductsCompanion(isSynced: Value(true)));
    await widget.db
        .update(widget.db.invoices)
        .write(const InvoicesCompanion(isSynced: Value(true)));
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
            stream: widget.db.select(widget.db.products).watch(),
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
                                '\$${item.saleUsd.toStringAsFixed(2)} | ${(item.saleUsd * widget.ctrl.usdToNewSyp).toStringAsFixed(1)} جديدة',
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final ctrl = ExchangeRateController();
  runApp(EnterprisePosApp(db: db, ctrl: ctrl));
}

class EnterprisePosApp extends StatelessWidget {
  final AppDatabase db;
  final ExchangeRateController ctrl;

  const EnterprisePosApp({super.key, required this.db, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: ctrl.isDark ? Brightness.dark : Brightness.light,
            useMaterial3: true,
          ),
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
          home: HomeScreen(db: db, ctrl: ctrl),
        );
      },
    );
  }
}
Binding.ensureInitialized();
  final db = AppDatabase();
  final ctrl = ExchangeRateController();
  runApp(EnterprisePosApp(db: db, ctrl: ctrl));
}

class EnterprisePosApp extends StatelessWidget {
  final AppDatabase db;
  final ExchangeRateController ctrl;
  const EnterprisePosApp({super.key, required this.db, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: ctrl.isDark ? Brightness.dark : Brightness.light,
            useMaterial3: true,
          ),
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
          home: HomeScreen(db: db, ctrl: ctrl),
        );
      },
    );
  }
}
rBinding.ensureInitialized();
  final db = AppDatabase();
  final ctrl = ExchangeRateController();
  runApp(EnterprisePosApp(db: db, ctrl: ctrl));
}

class EnterprisePosApp extends StatelessWidget {
  final AppDatabase db;
  final ExchangeRateController ctrl;
  const EnterprisePosApp({super.key, required this.db, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: ctrl.isDark ? Brightness.dark : Brightness.light,
            useMaterial3: true,
          ),
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
          home: HomeScreen(db: db, ctrl: ctrl),
        );
      },
    );
  }
}
