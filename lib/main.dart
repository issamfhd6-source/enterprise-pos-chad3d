import 'package:flutter/material.dart';
import 'src/app_database.dart';
import 'src/exchange_rate_controller.dart';
import 'src/home_screen.dart';

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
