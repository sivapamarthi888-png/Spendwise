import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../screens/add_expense_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/statistics_screen.dart';

/// Route names and the navigation shell (bottom navigation + FAB host).
class AppRoutes {
  static const String home = '/';
  static const String addExpense = '/add-expense';

  /// Push pages (no bottom nav) map to builders directly.
  static Route<void> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case addExpense:
        final Object? args = settings.arguments;
        final Expense? editTarget = args is Expense ? args : null;
        return MaterialPageRoute<void>(
          builder: (_) => AddExpenseScreen(editTarget: editTarget),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const _MainShell(),
          settings: settings,
        );
    }
  }
}

/// Screen index of the bottom navigation tabs.
enum TabItem { home, statistics, profile, settings }

/// Top-level shell hosting the three main tabs and the dashboard FAB.
class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  TabItem _current = TabItem.home;

  static const String _addHeroTag = 'add-expense-fab';

  @override
  Widget build(BuildContext context) {
    final bool showFab = _current == TabItem.home;
    return Scaffold(
      body: IndexedStack(
        index: TabItem.values.indexOf(_current),
        children: const <Widget>[
          DashboardScreen(),
          StatisticsScreen(),
          ProfileScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              heroTag: _addHeroTag,
              tooltip: 'Add Expense',
              onPressed: () => _openAddExpense(context),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: TabItem.values.indexOf(_current),
        onDestinationSelected: (int index) {
          setState(() => _current = TabItem.values[index]);
        },
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _openAddExpense(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.addExpense);
  }
}
