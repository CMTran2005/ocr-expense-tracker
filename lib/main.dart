import 'package:flutter/material.dart';

import 'core/database/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'features/analytics_charts/presentation/dashboard_screen.dart';
import 'features/camera_scanner/presentation/camera_screen.dart';
import 'features/expense_tracker/presentation/expenses_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database & seed demo data if first install
  try {
    await DatabaseHelper.instance.seedInitialDataIfEmpty();
  } catch (e) {
    debugPrint('Database initialization notice: $e');
  }

  runApp(const OcrExpenseTrackerApp());
}

class OcrExpenseTrackerApp extends StatelessWidget {
  const OcrExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();
  final GlobalKey<ExpensesListScreenState> _expensesKey =
      GlobalKey<ExpensesListScreenState>();

  void _onScanReceipt() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (context) => const CameraScreen()));

    if (result == true) {
      _dashboardKey.currentState?.refreshData();
      _expensesKey.currentState?.refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(
            key: _dashboardKey,
            onNavigateToTransactions: () {
              setState(() => _currentIndex = 1);
            },
          ),
          ExpensesListScreen(key: _expensesKey),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onScanReceipt,
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: const Color(0xFF1E293B),
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                tooltip: 'Dashboard',
                icon: Icon(
                  _currentIndex == 0
                      ? Icons.pie_chart_rounded
                      : Icons.pie_chart_outline_rounded,
                  color: _currentIndex == 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFF94A3B8),
                  size: 26,
                ),
                onPressed: () => setState(() => _currentIndex = 0),
              ),
              const SizedBox(width: 40), // Spacer for notched FAB
              IconButton(
                tooltip: 'Lịch sử giao dịch',
                icon: Icon(
                  _currentIndex == 1
                      ? Icons.receipt_long_rounded
                      : Icons.receipt_long_outlined,
                  color: _currentIndex == 1
                      ? const Color(0xFF10B981)
                      : const Color(0xFF94A3B8),
                  size: 26,
                ),
                onPressed: () => setState(() => _currentIndex = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
