import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Table;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

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

  Future<int> addProduct(String name, double saleUsd, {int qty = 0}) {
    return into(products).insert(
      ProductsCompanion.insert(
        name: name,
        qty: Value(qty),
        saleUsd: Value(saleUsd),
      ),
    );
  }

  Future<int> addInvoice(String number, double totalUsd) {
    return into(invoices).insert(
      InvoicesCompanion.insert(
        number: number,
        totalUsd: Value(totalUsd),
      ),
    );
  }

  Future<void> syncAllRecords() async {
    await (update(products)..where((t) => t.isSynced.equals(false))).write(
      const ProductsCompanion(isSynced: Value(true)),
    );
    await (update(invoices)..where((t) => t.isSynced.equals(false))).write(
      const InvoicesCompanion(isSynced: Value(true)),
    );
  }

  Stream<List<Product>> watchProducts() {
    return select(products).watch();
  }
}
