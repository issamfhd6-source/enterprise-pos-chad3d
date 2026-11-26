import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/servicesimport 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

part 'main.g.dart';

// ============================================================================
// 1. 3D THEME & INTERACTIVE CARDS
// ============================================================================

class App3DTheme {
  static const Color darkBg = Color(0xFF0A121E);
  static const Color navyHeader = Color(0xFF0F2942);
  static const Color cardDark = Color(0xFF132236);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color accentGold = Color(0xFFE59A24);
  static const Color accentCyan = Color(0xFF18B6D8);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color dangerRed = Color(0xFFDC2626);

  static ThemeData buildTheme({required bool isDark}) {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark ? darkBg : lightBg,
      primaryColor: navyHeader,
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: accentCyan,
              secondary: accentGold,
              surface: cardDark,
              error: dangerRed,
            )
          : const ColorScheme.light(
              primary: navyHeader,
              secondary: accentGold,
              surface: cardLight,
              error: dangerRed,
            ),
      useMaterial3: true,
    );
  }
}

class Interactive3DCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double borderRadius;

  const Interactive3DCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.borderRadius = 18,
  });

  @override
  State<Interactive3DCard> createState() => _Interactive3DCardState();
}

class _Interactive3DCardState extends State<Interactive3DCard> {
  double _tiltX = 0;
  double _tiltY = 0;
  bool _pressed = false;

  void _updateTilt(Offset localPos, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final dx = (localPos.dx / size.width) - 0.5;
    final dy = (localPos.dy / size.height) - 0.5;
    setState(() {
      _tiltY = dx * 0.14;
      _tiltX = -dy * 0.14;
    });
  }

  void _resetTilt() {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
      _pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        widget.color ?? (isDark ? App3DTheme.cardDark : App3DTheme.cardLight);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 300,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 120,
        );

        return GestureDetector(
          onTap: widget.onTap,
          onTapDown: (d) {
            setState(() => _pressed = true);
            _updateTilt(d.localPosition, size);
          },
          onPanUpdate: (d) => _updateTilt(d.localPosition, size),
          onPanEnd: (_) => _resetTilt(),
          onTapUp: (_) => _resetTilt(),
          onTapCancel: _resetTilt,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(_tiltX)
              ..rotateY(_tiltY)
              ..scale(_pressed ? 0.985 : 1.0),
            transformAlignment: Alignment.center,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.07),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                  offset: Offset(0, _pressed ? 3 : 8),
                  blurRadius: _pressed ? 8 : 16,
                ),
                BoxShadow(
                  color: App3DTheme.accentCyan.withValues(alpha: 0.06),
                  offset: const Offset(0, -2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// ============================================================================
// 2. EXCHANGE RATE CONTROLLER & ROLE PERMISSIONS GUARD
// ============================================================================

enum UserRole {
  manager,
  branchManager,
  cashier,
}

enum SystemPermission {
  editExchangeRate,
  manageBranchesAndStaff,
  manageInventory,
  createInvoices,
  manageCashboxAndExpenses,
  viewReportsAndExportPdf,
  manageBackupAndSync,
}

class ExchangeRateController extends ChangeNotifier {
  double _usdToNewSyp;
  double _oldToNewSypRatio;
  UserRole _currentRole;
  bool _isDarkMode;

  ExchangeRateController({
    double initialUsdToNewSyp = 135.0,
    double oldToNewSypRatio = 100.0,
    UserRole initialRole = UserRole.manager,
    bool isDarkMode = true,
  })  : _usdToNewSyp = initialUsdToNewSyp,
        _oldToNewSypRatio = oldToNewSypRatio,
        _currentRole = initialRole,
        _isDarkMode = isDarkMode;

  double get usdToNewSyp => _usdToNewSyp;
  double get oldToNewSypRatio => _oldToNewSypRatio;
  UserRole get currentRole => _currentRole;
  bool get isDarkMode => _isDarkMode;

  bool get canEditExchangeRate => _currentRole == UserRole.manager;

  double usdToNewSypValue(double usd) => usd * _usdToNewSyp;
  double usdToOldSypValue(double usd) => usd * _usdToNewSyp * _oldToNewSypRatio;

  double newSypToUsdValue(double newSyp) =>
      _usdToNewSyp <= 0 ? 0 : newSyp / _usdToNewSyp;

  double oldSypToUsdValue(double oldSyp) {
    final denom = _usdToNewSyp * _oldToNewSypRatio;
    return denom <= 0 ? 0 : oldSyp / denom;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setRole(UserRole role) {
    if (_currentRole == role) return;
    _currentRole = role;
    notifyListeners();
  }

  bool updateUsdRate(double newRate) {
    if (!canEditExchangeRate) return false;
    if (newRate <= 0 || newRate.isNaN || newRate.isInfinite) return false;
    _usdToNewSyp = newRate;
    notifyListeners();
    return true;
  }

  void updateOldToNewRatio(double ratio) {
    if (!canEditExchangeRate) return;
    if (ratio <= 0 || ratio.isNaN || ratio.isInfinite) return;
    _oldToNewSypRatio = ratio;
    notifyListeners();
  }
}

class RolePermissionsGuard {
  final ExchangeRateController rateController;

  RolePermissionsGuard({required this.rateController});

  bool hasPermission(SystemPermission permission) {
    switch (rateController.currentRole) {
      case UserRole.manager:
        return true;
      case UserRole.branchManager:
        return permission == SystemPermission.manageInventory ||
            permission == SystemPermission.createInvoices ||
            permission == SystemPermission.viewReportsAndExportPdf;
      case UserRole.cashier:
        return permission == SystemPermission.createInvoices;
    }
  }

  bool get canOnlyManagerEditExchangeRate =>
      rateController.currentRole == UserRole.manager;
}

// ============================================================================
// 3. DRIFT LOCAL DATABASE SCHEMA
// ============================================================================

class Branches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get locationType =>
      text().withDefault(const Constant('branch'))();
  TextColumn get address => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDate)();
}

class SystemUsers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fullName => text().withLength(min: 1, max: 120)();
  TextColumn get phone => text().withLength(min: 5, max: 30)();
  TextColumn get role => text().withDefault(const Constant('manager'))();
  IntColumn get branchId => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 160)();
  TextColumn get barcode => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('عام'))();
  TextColumn get unitName => text().withDefault(const Constant('قطعة'))();
  IntColumn get branchId => integer().withDefault(const Constant(1))();
  IntColumn get totalQuantity => integer().withDefault(const Constant(0))();
  IntColumn get minStockAlert => integer().withDefault(const Constant(5))();
  RealColumn get costUsd => real().withDefault(const Constant(0.0))();
  RealColumn get saleUsd => real().withDefault(const Constant(0.0))();
  RealColumn get costNewSyp => real().withDefault(const Constant(0.0))();
  RealColumn get saleNewSyp => real().withDefault(const Constant(0.0))();
  RealColumn get costOldSyp => real().withDefault(const Constant(0.0))();
  RealColumn get saleOldSyp => real().withDefault(const Constant(0.0))();
  RealColumn get profitMarginPercent => real().withDefault(const Constant(20.0))();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDate)();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get accountType => text()();
  TextColumn get phone => text().nullable()();
  RealColumn get balanceUsd => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDate)();
}

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text()();
  TextColumn get invoiceType => text()();
  IntColumn get branchId => integer().withDefault(const Constant(1))();
  IntColumn get accountId => integer().nullable()();
  IntColumn get productId => integer().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  RealColumn get subtotalUsd => real().withDefault(const Constant(0.0))();
  RealColumn get discountUsd => real().withDefault(const Constant(0.0))();
  RealColumn get totalUsd => real().withDefault(const Constant(0.0))();
  RealColumn get paidUsd => real().withDefault(const Constant(0.0))();
  RealColumn get remainingUsd => real().withDefault(const Constant(0.0))();
  RealColumn get exchangeRateUsed => real().withDefault(const Constant(135.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDate)();
}

class CashboxTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entryType => text()();
  TextColumn get category => text().withDefault(const Constant('عام'))();
  IntColumn get accountId => integer().nullable()();
  RealColumn get amountUsd => real().withDefault(const Constant(0.0))();
  RealColumn get amountNewSyp => real().withDefault(const Constant(0.0))();
  RealColumn get amountOldSyp => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDate)();
}

class SystemSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get storeName =>
      text().withDefault(const Constant('نظام المحاسبة ونقاط البيع 3D'))();
  RealColumn get usdToNewSypRate => real().withDefault(const Constant(135.0))();
  RealColumn get oldToNewSypRatio => real().withDefault(const Constant(100.0))();
  BoolColumn get autoAdjustCashboxOnPurchase =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get autoAdjustCashboxOnSale =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get autoAdjustCashboxOnExpense =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get serverSyncCursor => dateTime().withDefault(currentDate)();
}

@DriftDatabase(tables: [
  Branches,
  SystemUsers,
  Products,
  Accounts,
  Invoices,
  CashboxTransactions,
  SystemSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'enterprise_pos_chad3d.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  Future<SystemSetting> ensureInitialSeedData() async {
    final existingSettings = await select(systemSettings).get();
    SystemSetting activeSetting;
    if (existingSettings.isEmpty) {
      final id = await into(systemSettings).insert(
        SystemSettingsCompanion.insert(
          storeName: const Value('نظام المحاسبة ونقاط البيع 3D'),
          usdToNewSypRate: const Value(135.0),
          oldToNewSypRatio: const Value(100.0),
        ),
      );
      activeSetting =
          (await (select(systemSettings)..where((t) => t.id.equals(id))).get())
              .first;
    } else {
      activeSetting = existingSettings.first;
    }

    final existingBranches = await select(branches).get();
    if (existingBranches.isEmpty) {
      await into(branches).insert(
        BranchesCompanion.insert(
          name: const Value('الفرع الرئيسي'),
          locationType: const Value('branch'),
          address: const Value('المركز'),
          isSynced: const Value(true),
        ),
      );
    }

    final existingUsers = await select(systemUsers).get();
    if (existingUsers.isEmpty) {
      await into(systemUsers).insert(
        SystemUsersCompanion.insert(
          fullName: const Value('المدير العام'),
          phone: const Value('+963900000001'),
          role: const Value('manager'),
          branchId: const Value(1),
          isSynced: const Value(true),
        ),
      );
    }

    return activeSetting;
  }
}

// ============================================================================
// 4. CORE SERVICES (PRICING, INVOICES, CASHBOX, BRANCHES/USERS, SYNC, PDF)
// ============================================================================

class PricingSyncService {
  final AppDatabase db;
  final ExchangeRateController rateController;

  PricingSyncService({
    required this.db,
    required this.rateController,
  });

  Future<bool> updateExchangeRateAndRepriceAllProducts(double newUsdRate) async {
    if (!rateController.canEditExchangeRate) return false;
    final accepted = rateController.updateUsdRate(newUsdRate);
    if (!accepted) return false;

    final ratio = rateController.oldToNewSypRatio;

    await db.transaction(() async {
      await db.update(db.systemSettings).write(
            SystemSettingsCompanion(
              usdToNewSypRate: Value(newUsdRate),
              oldToNewSypRatio: Value(ratio),
            ),
          );

      final allProducts = await db.select(db.products).get();
      for (final prod in allProducts) {
        final costNew = prod.costUsd * newUsdRate;
        final saleNew = prod.saleUsd * newUsdRate;
        final costOld = costNew * ratio;
        final saleOld = saleNew * ratio;

        await (db.update(db.products)..where((t) => t.id.equals(prod.id)))
            .write(
          ProductsCompanion(
            costNewSyp: Value(costNew),
            saleNewSyp: Value(saleNew),
            costOldSyp: Value(costOld),
            saleOldSyp: Value(saleOld),
            isSynced: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });

    return true;
  }
}

class InvoiceService {
  final AppDatabase db;
  final ExchangeRateController rateController;

  InvoiceService({
    required this.db,
    required this.rateController,
  });

  Future<int> createInvoice({
    required String invoiceType,
    required int branchId,
    int? accountId,
    int? productId,
    int quantity = 0,
    required double subtotalUsd,
    required double discountUsd,
    required double paidUsd,
    String? notes,
  }) async {
    final netTotal = (subtotalUsd - discountUsd).clamp(0.0, double.infinity);
    final remaining = (netTotal - paidUsd).clamp(0.0, double.infinity);
    final rate = rateController.usdToNewSyp;
    final ratio = rateController.oldToNewSypRatio;
    final invNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

    return db.transaction(() async {
      final settingsList = await db.select(db.systemSettings).get();
      final settings = settingsList.isNotEmpty ? settingsList.first : null;

      final id = await db.into(db.invoices).insert(
            InvoicesCompanion.insert(
              invoiceNumber: invNumber,
              invoiceType: invoiceType,
              branchId: Value(branchId),
              accountId: Value(accountId),
              productId: Value(productId),
              quantity: Value(quantity),
              subtotalUsd: Value(subtotalUsd),
              discountUsd: Value(discountUsd),
              totalUsd: Value(netTotal),
              paidUsd: Value(paidUsd),
              remainingUsd: Value(remaining),
              exchangeRateUsed: Value(rate),
              notes: Value(notes),
              isSynced: const Value(false),
            ),
          );

      if (productId != null && quantity > 0) {
        final prodList = await (db.select(db.products)
              ..where((t) => t.id.equals(productId)))
            .get();
        if (prodList.isNotEmpty) {
          final prod = prodList.first;
          final delta =
              (invoiceType == 'sale' || invoiceType == 'purchaseReturn')
                  ? -quantity
                  : quantity;
          final nextQty = (prod.totalQuantity + delta).clamp(0, 1 << 30);
          await (db.updatimport 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

part 'main.g.dart';

// ============================================================================
// 1. 3D THEME & INTERACTIVE CARDS
// ============================================================================

class App3DTheme {
  static const Color darkBg = Color(0xFF0A121E);
  static const Color navyHeader = Color(0xFF0F2942);
  static const Color cardDark = Color(0xFF132236);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color accentGold = Color(0xFFE59A24);
  static const Color accentCyan = Color(0xFF18B6D8);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color dangerRed = Color(0xFFDC2626);

  static ThemeData buildTheme({required bool isDark}) {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark ? darkBg : lightBg,
      primaryColor: navyHeader,
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: accentCyan,
              secondary: accentGold,
              surface: cardDark,
              error: dangerRed,
            )
          : const ColorScheme.light(
              primary: navyHeader,
              secondary: accentGold,
              surface: cardLight,
              error: dangerRed,
            ),
      useMaterial3: true,
    );
  }
}

class Interactive3DCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double borderRadius;

  const Interactive3DCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.borderRadius = 18,
  });

  @override
  State<Interactive3DCard> createState() => _Interactive3DCardState();
}

class _Interactive3DCardState extends State<Interactive3DCard> {
  double _tiltX = 0;
  double _tiltY = 0;
  bool _pressed = false;

  void _updateTilt(Offset localPos, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final dx = (localPos.dx / size.width) - 0.5;
    final dy = (localPos.dy / size.height) - 0.5;
    setState(() {
      _tiltY = dx * 0.14;
      _tiltX = -dy * 0.14;
    });
  }

  void _resetTilt() {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
      _pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        widget.color ?? (isDark ? App3DTheme.cardDark : App3DTheme.cardLight);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 300,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 120,
        );

        return GestureDetector(
          onTap: widget.onTap,
          onTapDown: (d) {
            setState(() => _pressed = true);
            _updateTilt(d.localPosition, size);
          },
          onPanUpdate: (d) => _updateTilt(d.localPosition, size),
          onPanEnd: (_) => _resetTilt(),
          onTapUp: (_) => _resetTilt(),
          onTapCancel: _resetTilt,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(_tiltX)
              ..rotateY(_tiltY)
              ..scale(_pressed ? 0.985 : 1.0),
            transformAlignment: Alignment.center,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.07),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                  offset: Offset(0, _pressed ? 3 : 8),
                  blurRadius: _pressed ? 8 : 16,
                ),
                BoxShadow(
                  color: App3DTheme.accentCyan.withValues(alpha: 0.06),
                  offset: const Offset(0, -2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// ============================================================================
// 2. EXCHANGE RATE CONTROLLER & ROLE PERMISSIONS GUARD
// ============================================================================

enum UserRole {
  manager,
  branchManager,
  cashier,
}

enum SystemPermission {
  editExchangeRate,
  manageBranchesAndStaff,
  manageInventory,
  createInvoices,
  manageCashboxAndExpenses,
  viewReportsAndExportPdf,
  manageBackupAndSync,
}

class ExchangeRateController extends ChangeNotifier {
  double _usdToNewSyp;
  double _oldToNewSypRatio;
  UserRole _currentRole;
  bool _isDarkMode;

  ExchangeRateController({
    double initialUsdToNewSyp = 135.0,
    double oldToNewSypRatio = 100.0,
    UserRole initialRole = UserRole.manager,
    bool isDarkMode = true,
  })  : _usdToNewSyp = initialUsdToNewSyp,
        _oldToNewSypRatio = oldToNewSypRatio,
        _currentRole = initialRole,
        _isDarkMode = isDarkMode;

  double get usdToNewSyp => _usdToNewSyp;
  double get oldToNewSypRatio => _oldToNewSypRatio;
  UserRole get currentRole => _currentRole;
  bool get isDarkMode => _isDarkMode;

  bool get canEditExchangeRate => _currentRole == UserRole.manager;

  double usdToNewSypValue(double usd) => usd * _usdToNewSyp;
  double usdToOldSypValue(double usd) => usd * _usdToNewSyp * _oldToNewSypRatio;

  double newSypToUsdValue(double newSyp) =>
      _usdToNewSyp <= 0 ? 0 : newSyp / _usdToNewSyp;

  double oldSypToUsdValue(double oldSyp) {
    final denom = _usdToNewSyp * _oldToNewSypRatio;
    return denom <= 0 ? 0 : oldSyp / denom;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setRole(UserRole role) {
    if (_currentRole == role) return;
    _currentRole = role;
    notifyListeners();
  }

  bool updateUsdRate(double newRate) {
    if (!canEditExchangeRate) return false;
    if (newRate <= 0 || newRate.isNaN || newRate.isInfinite) return false;
    _usdToNewSyp = newRate;
    notifyListeners();
    return true;
  }

  void updateOldToNewRatio(double ratio) {
    if (!canEditExchangeRate) return;
    if (ratio <= 0 || ratio.isNaN || ratio.isInfinite) return;
    _oldToNewSypRatio = ratio;
    notifyListeners();
  }
}

class RolePermissionsGuard {
  final ExchangeRateController rateController;

  RolePermissionsGuard({required this.rateController});

  bool hasPermission(SystemPermission permission) {
    switch (rateController.currentRole) {
      case UserRole.manager:
        return true;
      case UserRole.branchManager:
        return permission == SystemPermission.manageInventory ||
            permission == SystemPermission.createInvoices ||
            permission == SystemPermission.viewReportsAndExportPdf;
      case UserRole.cashier:
        return permission == SystemPermission.createInvoices;
    }
  }

  bool get canOnlyManagerEditExchangeRate =>
      rateController.currentRole == UserRole.manager;
}

// ============================================================================
// 3. DRIFT LOCAL DATABASE SCHEMA
// ============================================================================

class Branches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get locationType =>
      text().withDefault(const Constant('branch'))();
  TextColumn get address => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDate)();
}

class SystemUsers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fullName => text().withLength(min: 1, max: 120)();
  TextColumn get phone => text().withLength(min: 5, max: 30)();
  TextColumn get role => text().withDefault(const Constant('manager'))();
  IntColumn get branchId => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 160)();
  TextColumn get barcode => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('عام'))();
  TextColumn get unitName => text().withDefault(const Constant('قطعة'))();
  IntColumn get branchId => integer().withDefault(const Constant(1))();
  IntColumn get totalQuantity => integer().withDefault(const Constant(0))();
  IntColumn get minStockAlert => integer().withDefault(const Constant(5))();
  RealColumn get costUsd => real().withDefault(const Constant(0.0))();
  RealColumn get saleUsd => real().withDefault(const Constant(0.0))();
  RealColumn get costNewSyp => real().withDefault(const Constant(0.0))();
  RealColumn get saleNewSyp => real().withDefault(const Constant(0.0))();
  RealColumn get costOldSyp => real().withDefault(const Constant(0.0))();
  RealColumn get saleOldSyp => real().withDefault(const Constant(0.0))();
  RealColumn get profitMarginPercent => real().withDefault(const Constant(20.0))();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDate)();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get accountType => text()();
  TextColumn get phone => text().nullable()();
  RealColumn get balanceUsd => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDate)();
}

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text()();
  TextColumn get invoiceType => text()();
  IntColumn get branchId => integer().withDefault(const Constant(1))();
  IntColumn get accountId => integer().nullable()();
  IntColumn get productId => integer().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  RealColumn get subtotalUsd => real().withDefault(const Constant(0.0))();
  RealColumn get discountUsd => real().withDefault(const Constant(0.0))();
  RealColumn get totalUsd => real().withDefault(const Constant(0.0))();
  RealColumn get paidUsd => real().withDefault(const Constant(0.0))();
  RealColumn get remainingUsd => real().withDefault(const Constant(0.0))();
  RealColumn get exchangeRateUsed => real().withDefault(const Constant(135.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDate)();
}

class CashboxTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entryType => text()();
  TextColumn get category => text().withDefault(const Constant('عام'))();
  IntColumn get accountId => integer().nullable()();
  RealColumn get amountUsd => real().withDefault(const Constant(0.0))();
  RealColumn get amountNewSyp => real().withDefault(const Constant(0.0))();
  RealColumn get amountOldSyp => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDate)();
}

class SystemSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get storeName =>
      text().withDefault(const Constant('نظام المحاسبة ونقاط البيع 3D'))();
  RealColumn get usdToNewSypRate => real().withDefault(const Constant(135.0))();
  RealColumn get oldToNewSypRatio => real().withDefault(const Constant(100.0))();
  BoolColumn get autoAdjustCashboxOnPurchase =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get autoAdjustCashboxOnSale =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get autoAdjustCashboxOnExpense =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get serverSyncCursor => dateTime().withDefault(currentDate)();
}

@DriftDatabase(tables: [
  Branches,
  SystemUsers,
  Products,
  Accounts,
  Invoices,
  CashboxTransactions,
  SystemSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'enterprise_pos_chad3d.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  Future<SystemSetting> ensureInitialSeedData() async {
    final existingSettings = await select(systemSettings).get();
    SystemSetting activeSetting;
    if (existingSettings.isEmpty) {
      final id = await into(systemSettings).insert(
        SystemSettingsCompanion.insert(
          storeName: const Value('نظام المحاسبة ونقاط البيع 3D'),
          usdToNewSypRate: const Value(135.0),
          oldToNewSypRatio: const Value(100.0),
        ),
      );
      activeSetting =
          (await (select(systemSettings)..where((t) => t.id.equals(id))).get())
              .first;
    } else {
      activeSetting = existingSettings.first;
    }

    final existingBranches = await select(branches).get();
    if (existingBranches.isEmpty) {
      await into(branches).insert(
        BranchesCompanion.insert(
          name: const Value('الفرع الرئيسي'),
          locationType: const Value('branch'),
          address: const Value('المركز'),
          isSynced: const Value(true),
        ),
      );
    }

    final existingUsers = await select(systemUsers).get();
    if (existingUsers.isEmpty) {
      await into(systemUsers).insert(
        SystemUsersCompanion.insert(
          fullName: const Value('المدير العام'),
          phone: const Value('+963900000001'),
          role: const Value('manager'),
          branchId: const Value(1),
          isSynced: const Value(true),
        ),
      );
    }

    return activeSetting;
  }
}

// ============================================================================
// 4. CORE SERVICES (PRICING, INVOICES, CASHBOX, BRANCHES/USERS, SYNC, PDF)
// ============================================================================

class PricingSyncService {
  final AppDatabase db;
  final ExchangeRateController rateController;

  PricingSyncService({
    required this.db,
    required this.rateController,
  });

  Future<bool> updateExchangeRateAndRepriceAllProducts(double newUsdRate) async {
    if (!rateController.canEditExchangeRate) return false;
    final accepted = rateController.updateUsdRate(newUsdRate);
    if (!accepted) return false;

    final ratio = rateController.oldToNewSypRatio;

    await db.transaction(() async {
      await db.update(db.systemSettings).write(
            SystemSettingsCompanion(
              usdToNewSypRate: Value(newUsdRate),
              oldToNewSypRatio: Value(ratio),
            ),
          );

      final allProducts = await db.select(db.products).get();
      for (final prod in allProducts) {
        final costNew = prod.costUsd * newUsdRate;
        final saleNew = prod.saleUsd * newUsdRate;
        final costOld = costNew * ratio;
        final saleOld = saleNew * ratio;

        await (db.update(db.products)..where((t) => t.id.equals(prod.id)))
            .write(
          ProductsCompanion(
            costNewSyp: Value(costNew),
            saleNewSyp: Value(saleNew),
            costOldSyp: Value(costOld),
            saleOldSyp: Value(saleOld),
            isSynced: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });

    return true;
  }
}

class InvoiceService {
  final AppDatabase db;
  final ExchangeRateController rateController;

  InvoiceService({
    required this.db,
    required this.rateController,
  });

  Future<int> createInvoice({
    required String invoiceType,
    required int branchId,
    int? accountId,
    int? productId,
    int quantity = 0,
    required double subtotalUsd,
    required double discountUsd,
    required double paidUsd,
    String? notes,
  }) async {
    final netTotal = (subtotalUsd - discountUsd).clamp(0.0, double.infinity);
    final remaining = (netTotal - paidUsd).clamp(0.0, double.infinity);
    final rate = rateController.usdToNewSyp;
    final ratio = rateController.oldToNewSypRatio;
    final invNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

    return db.transaction(() async {
      final settingsList = await db.select(db.systemSettings).get();
      final settings = settingsList.isNotEmpty ? settingsList.first : null;

      final id = await db.into(db.invoices).insert(
            InvoicesCompanion.insert(
              invoiceNumber: invNumber,
              invoiceType: invoiceType,
              branchId: Value(branchId),
              accountId: Value(accountId),
              productId: Value(productId),
              quantity: Value(quantity),
              subtotalUsd: Value(subtotalUsd),
              discountUsd: Value(discountUsd),
              totalUsd: Value(netTotal),
              paidUsd: Value(paidUsd),
              remainingUsd: Value(remaining),
              exchangeRateUsed: Value(rate),
              notes: Value(notes),
              isSynced: const Value(false),
            ),
          );

      if (productId != null && quantity > 0) {
        final prodList = await (db.select(db.products)
              ..where((t) => t.id.equals(productId)))
            .get();
        if (prodList.isNotEmpty) {
          final prod = prodList.first;
          final delta =
              (invoiceType == 'sale' || invoiceType == 'purchaseReturn')
                  ? -quantity
                  : quantity;
          final nextQty = (prod.totalQuantity + delta).clamp(0, 1 << 30);
          await (db.update(db.products)..where((t) => t.id.equals(prod.id)))
              .write(
            ProductsCompanion(
              totalQuantity: Value(nextQty),
              isSynced: const Value(false),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }

      if (accountId != null && remaining > 0) {
        final accList = await (db.select(db.accounts)
              ..where((t) => t.id.equals(accountId)))
            .get();
        if (accList.isNotEmpty) {
          final acc = accList.first;
          final deltaBalance =
              (invoiceType == 'sale' || invoiceType == 'purchaseReturn')
           ealColumn get costOldSyp => real().withDefault(const Constant(0.0))();
  RealColumn get saleOldSyp => real().withDefault(const Constant(0.0))();
  RealColumn get profitMarginPercent => real().withDefault(const Constant(20.0))();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDate)();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get accountType => text()(); // customer | supplier
  TextColumn get phone => text().nullable()();
  RealColumn get balanceUsd => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDate)();
}

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text()();
  TextColumn get invoiceType =>
      text()(); // sale | purchase | saleReturn | purchaseReturn
  IntColumn get branchId => integer().withDefault(const Constant(1))();
  IntColumn get accountId => integer().nullable()();
  IntColumn get productId => integer().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  RealColumn get subtotalUsd => real().withDefault(const Constant(0.0))();
  RealColumn get discountUsd => real().withDefault(const Constant(0.0))();
  RealColumn get totalUsd => real().withDefault(const Constant(0.0))();
  RealColumn get paidUsd => real().withDefault(const Constant(0.0))();
  RealColumn get remainingUsd => real().withDefault(const Constant(0.0))();
  RealColumn get exchangeRateUsed => real().withDefault(const Constant(135.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDate)();
}

class CashboxTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entryType =>
      text()(); // deposit | withdraw | expense | customer_payment | supplier_payment | external_cash
  TextColumn get category => text().withDefault(const Constant('عام'))();
  IntColumn get accountId => integer().nullable()();
  RealColumn get amountUsd => real().withDefault(const Constant(0.0))();
  RealColumn get amountNewSyp => real().withDefault(const Constant(0.0))();
  RealColumn get amountOldSyp => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDate)();
}

class SystemSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get storeName =>
      text().withDefault(const Constant('نظام المحاسبة ونقاط البيع 3D'))();
  RealColumn get usdToNewSypRate => real().withDefault(const Constant(135.0))();
  RealColumn get oldToNewSypRatio => real().withDefault(const Constant(100.0))();
  BoolColumn get autoAdjustCashboxOnPurchase =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get autoAdjustCashboxOnSale =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get autoAdjustCashboxOnExpense =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get serverSyncCursor => dateTime().withDefault(currentDate)();
}

@DriftDatabase(tables: [
  Branches,
  SystemUsers,
  Products,
  Accounts,
  Invoices,
  CashboxTransactions,
  SystemSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'enterprise_pos_chad3d.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  Future<SystemSetting> ensureInitialSeedData() async {
    final existingSettings = await select(systemSettings).get();
    SystemSetting activeSetting;
    if (existingSettings.isEmpty) {
      final id = await into(systemSettings).insert(
        SystemSettingsCompanion.insert(
          storeName: const Value('نظام المحاسبة ونقاط البيع 3D'),
          usdToNewSypRate: const Value(135.0),
          oldToNewSypRatio: const Value(100.0),
        ),
      );
      activeSetting =
          (await (select(systemSettings)..where((t) => t.id.equals(id))).get())
              .first;
    } else {
      activeSetting = existingSettings.first;
    }

    final existingBranches = await select(branches).get();
    if (existingBranches.isEmpty) {
      await into(branches).insert(
        BranchesCompanion.insert(
          name: const Value('الفرع الرئيسي'),
          locationType: const Value('branch'),
          address: const Value('المركز'),
          isSynced: const Value(true),
        ),
      );
    }

    final existingUsers = await select(systemUsers).get();
    if (existingUsers.isEmpty) {
      await into(systemUsers).insert(
        SystemUsersCompanion.insert(
          fullName: const Value('المدير العام'),
          phone: const Value('+963900000001'),
          role: const Value('manager'),
          branchId: const Value(1),
          isSynced: const Value(true),
        ),
      );
    }

    return activeSetting;
  }
}

// ============================================================================
// 4. CORE SERVICES (PRICING, INVOICES, CASHBOX, BRANCHES/USERS, SYNC, PDF)
// ============================================================================

class PricingSyncService {
  final AppDatabase db;
  final ExchangeRateController rateController;

  PricingSyncService({
    required this.db,
    required this.rateController,
  });

  Future<bool> updateExchangeRateAndRepriceAllProducts(double newUsdRate) async {
    if (!rateController.canEditExchangeRate) return false;
    final accepted = rateController.updateUsdRate(newUsdRate);
    if (!accepted) return false;

    final ratio = rateController.oldToNewSypRatio;

    await db.transaction(() async {
      await db.update(db.systemSettings).write(
            SystemSettingsCompanion(
              usdToNewSypRate: Value(newUsdRate),
              oldToNewSypRatio: Value(ratio),
            ),
          );

      final allProducts = await db.select(db.products).get();
      for (final prod in allProducts) {
        final costNew = prod.costUsd * newUsdRate;
        final saleNew = prod.saleUsd * newUsdRate;
        final costOld = costNew * ratio;
        final saleOld = saleNew * ratio;

        await (db.update(db.products)..where((t) => t.id.equals(prod.id)))
            .write(
          ProductsCompanion(
            costNewSyp: Value(costNew),
            saleNewSyp: Value(saleNew),
            costOldSyp: Value(costOld),
            saleOldSyp: Value(saleOld),
            isSynced: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });

    return true;
  }
}

class InvoiceService {
  final AppDatabase db;
  final ExchangeRateController rateController;

  InvoiceService({
    required this.db,
    required this.rateController,
  });

  Future<int> createInvoice({
    required String invoiceType, // sale | purchase | saleReturn | purchaseReturn
    required int branchId,
    int? accountId,
    int? productId,
    int quantity = 0,
    required double subtotalUsd,
    required double discountUsd,
    required double paidUsd,
    String? notes,
  }) async {
    final netTotal = (subtotalUsd - discountUsd).clamp(0.0, double.infinity);
    final remaining = (netTotal - paidUsd).clamp(0.0, double.infinity);
    final rate = rateController.usdToNewSyp;
    final ratio = rateController.oldToNewSypRatio;
    final invNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

    return db.transaction(() async {
      final settingsList = await db.select(db.systemSettings).get();
      final settings = settingsList.isNotEmpty ? settingsList.first : null;

      final id = await db.into(db.invoices).insert(
            InvoicesCompanion.insert(
              invoiceNumber: invNumber,
              invoiceType: invoiceType,
              branchId: Value(branchId),
              accountId: Value(accountId),
              productId: Value(productId),
              quantity: Value(quantity),
              subtotalUsd: Value(subtotalUsd),
              discountUsd: Value(discountUsd),
              totalUsd: Value(netTotal),
              paidUsd: Value(paidUsd),
              remainingUsd: Value(remaining),
              exchangeRateUsed: Value(rate),
              notes: Value(notes),
              isSynced: const Value(false),
            ),
          );

      if (productId != null && quantity > 0) {
        final prodList = await (db.select(db.products)
              ..where((t) => t.id.equals(productId)))
            .get();
        if (prodList.isNotEmpty) {
          final prod = prodList.first;
          final delta =
              (invoiceType == 'sale' || invoiceType == 'purchaseReturn')
                  ? -quantity
                  : quantity;
          final nextQty = (prod.totalQuantity + delta).clamp(0, 1 << 30);
          await (db.update(db.products)..where((t) => t.id.equals(prod.id)))
              .write(
            ProductsCompanion(
              totalQuantity: Value(nextQty),
              isSynced: const Value(false),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }

      if (accountId != null && remaining > 0) {
        final accList =ant(0.0))();
  RealColumn get saleUsd => real().withDefault(const Constant(0.0))();
  RealColumn get costNewSyp => real().withDefault(const Constant(0.0))();
  RealColumn get saleNewSyp => real().withDefault(const Constant(0.0))();
  RealColumn get costOldSyp => real().withDefault(const Constant(0.0))();
  RealColumn get saleOldSyp => real().withDefault(const Constant(0.0))();
  RealColumn get profitMarginPercent => real().withDefault(const Constant(20.0))();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDate)();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get accountType => text()(); // customer | supplier
  TextColumn get phone => text().nullable()();
  RealColumn get balanceUsd => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDate)();
}

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text()();
  TextColumn get invoiceType =>
      text()(); // sale | purchase | saleReturn | purchaseReturn
  IntColumn get branchId => integer().withDefault(const Constant(1))();
  IntColumn get accountId => integer().nullable()();
  IntColumn get productId => integer().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  RealColumn get subtotalUsd => real().withDefault(const Constant(0.0))();
  RealColumn get discountUsd => real().withDefault(const Constant(0.0))();
  RealColumn get totalUsd => real().withDefault(const Constant(0.0))();
  RealColumn get paidUsd => real().withDefault(const Constant(0.0))();
  RealColumn get remainingUsd => real().withDefault(const Constant(0.0))();
  RealColumn get exchangeRateUsed => real().withDefault(const Constant(135.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDate)();
}

class CashboxTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entryType =>
      text()(); // deposit | withdraw | expense | customer_payment | supplier_payment | external_cash
  TextColumn get category => text().withDefault(const Constant('عام'))();
  IntColumn get accountId => integer().nullable()();
  RealColumn get amountUsd => real().withDefault(const Constant(0.0))();
  RealColumn get amountNewSyp => real().withDefault(const Constant(0.0))();
  RealColumn get amountOldSyp => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDate)();
}

class SystemSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get storeName =>
      text().withDefault(const Constant('نظام المحاسبة ونقاط البيع 3D'))();
  RealColumn get usdToNewSypRate => real().withDefault(const Constant(135.0))();
  RealColumn get oldToNewSypRatio => real().withDefault(const Constant(100.0))();
  BoolColumn get autoAdjustCashboxOnPurchase =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get autoAdjustCashboxOnSale =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get autoAdjustCashboxOnExpense =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get serverSyncCursor => dateTime().withDefault(currentDate)();
}

@DriftDatabase(tables: [
  Branches,
  SystemUsers,
  Products,
  Accounts,
  Invoices,
  CashboxTransactions,
  SystemSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'enterprise_pos_3d.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  Future<SystemSetting> ensureInitialSeedData() async {
    final existingSettings = await select(systemSettings).get();
    SystemSetting activeSetting;
    if (existingSettings.isEmpty) {
      final id = await into(systemSettings).insert(
        SystemSettingsCompanion.insert(
          storeName: const Value('نظام المحاسبة ونقاط البيع 3D'),
          usdToNewSypRate: const Value(135.0),
          oldToNewSypRatio: const Value(100.0),
        ),
      );
      activeSetting =
          (await (select(systemSettings)..where((t) => t.id.equals(id))).get())
              .first;
    } else {
      activeSetting = existingSettings.first;
    }

    final existingBranches = await select(branches).get();
    if (existingBranches.isEmpty) {
      await into(branches).insert(
        BranchesCompanion.insert(
          name: const Value('الفرع الرئيسي'),
          locationType: const Value('branch'),
          address: const Value('المركز'),
          isSynced: const Value(true),
        ),
      );
    }

    final existingUsers = await select(systemUsers).get();
    if (existingUsers.isEmpty) {
      await into(systemUsers).insert(
        SystemUsersCompanion.insert(
          fullName: const Value('المدير العام'),
          phone: const Value('+963900000001'),
          role: const Value('manager'),
          branchId: const Value(1),
          isSynced: const Value(true),
        ),
      );
    }

    return activeSetting;
  }
}

// ============================================================================
// 4. CORE SERVICES (PRICING, INVOICES, CASHBOX, BRANCHES/USERS, SYNC, PDF)
// ============================================================================

class PricingSyncService {
  final AppDatabase db;
  final ExchangeRateController rateController;

  PricingSyncService({
    required this.db,
    required this.rateController,
  });

  Future<bool> updateExchangeRateAndRepriceAllProducts(double newUsdRate) async {
    if (!rateController.canEditExchangeRate) return false;
    final accepted = rateController.updateUsdRate(newUsdRate);
    if (!accepted) return false;

    final ratio = rateController.oldToNewSypRatio;

    await db.transaction(() async {
      await db.update(db.systemSettings).write(
            SystemSettingsCompanion(
              usdToNewSypRate: Value(newUsdRate),
              oldToNewSypRatio: Value(ratio),
            ),
          );

      final allProducts = await db.select(db.products).get();
      for (final prod in allProducts) {
        final costNew = prod.costUsd * newUsdRate;
        final saleNew = prod.saleUsd * newUsdRate;
        final costOld = costNew * ratio;
        final saleOld = saleNew * ratio;

        await (db.update(db.products)..where((t) => t.id.equals(prod.id)))
            .write(
          ProductsCompanion(
            costNewSyp: Value(costNew),
            saleNewSyp: Value(saleNew),
            costOldSyp: Value(costOld),
            saleOldSyp: Value(saleOld),
            isSynced: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });

    return true;
  }
}

class InvoiceService {
  final AppDatabase db;
  final ExchangeRateController rateController;

  InvoiceService({
    required this.db,
    required this.rateController,
  });

  Future<int> createInvoice({
    required String invoiceType, // sale | purchase | saleReturn | purchaseReturn
    required int branchId,
    int? accountId,
    int? productId,
    int quantity = 0,
    required double subtotalUsd,
    required double discountUsd,
    required double paidUsd,
    String? notes,
  }) async {
    final netTotal = (subtotalUsd - discountUsd).clamp(0.0, double.infinity);
    final remaining = (netTotal - paidUsd).clamp(0.0, double.infinity);
    final rate = rateController.usdToNewSyp;
    final ratio = rateController.oldToNewSypRatio;
    final invNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

    return db.transaction(() async {
      final settingsList = await db.select(db.systemSettings).get();
      final settings = settingsList.isNotEmpty ? settingsList.first : null;

      final id = await db.into(db.invoices).insert(
            InvoicesCompanion.insert(
              invoiceNumber: invNumber,
              invoiceType: invoiceType,
              branchId: Value(branchId),
              accountId: Value(accountId),
              productId: Value(productId),
              quantity: Value(quantity),
              subtotalUsd: Value(subtotalUsd),
              discountUsd: Value(discountUsd),
              totalUsd: Value(netTotal),
              paidUsd: Value(paidUsd),
              remainingUsd: Value(remaining),
              exchangeRateUsed: Value(rate),
              notes: Value(notes),
              isSynced: const Value(false),
            ),
          );

      // ربط حركة المخزون حسب نوع الفاتورة
      if (productId != null && quantity > 0) {
        final prodList = await (db.select(db.products)
              ..where((t) => t.id.equals(productId)))
            .get();
        if (prodList.isNotEmpty) {
          final prod = prodList.first;
          final delta =
              (invoiceType == 'sale' || invoiceType == 'purchaseReturn')
                  ? -quantity
                  : quantity;
          final nextQty = (prod.totalQuantity + delta).clamp(0, 1 << 30);
          await (db.update(db.products)..where((t) => t.id.equals(prod.id)))
              .write(
            
