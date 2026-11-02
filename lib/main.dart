import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'navigation/app_navigation.dart';
import 'providers/expense_provider.dart';
import 'providers/theme_provider.dart';
import 'services/database_service.dart';
import 'utils/app_constants.dart';
import 'utils/app_theme.dart';

/// SpendWise – Personal Expense Manager entry point.
///
/// Bootstraps:
///  • ThemeProvider with the persisted appearance choice
///  • The single ExpenseProvider (ChangeNotifier) sharing all app state
///  • The app shell with Material 3 light/dark themes
Future<void> main() async {
  // Surface uncaught framework errors in logs instead of crashing visuals.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  WidgetsFlutterBinding.ensureInitialized();
  final ThemeProvider themeProvider = ThemeProvider();
  await themeProvider.load();
  // Warm up the database before first paint so the dashboard reaches its
  // data state as fast as possible. Failures surface as the error state.
  await DatabaseService.instance.open();

  runApp(SpendWiseApp(themeProvider: themeProvider));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        // Theme state is created eagerly and shared with every screen.
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        // Single source of truth for all transaction data.
        ChangeNotifierProvider<ExpenseProvider>(
          create: (_) => ExpenseProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (BuildContext context, ThemeProvider theme, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: theme.themeMode,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}
