import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/asset_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/category_provider.dart';
import 'providers/department_provider.dart';
import 'providers/location_provider.dart';
import 'providers/status_provider.dart';
import 'providers/ticket_provider.dart';
import 'providers/alert_provider.dart';
import 'package:office_assets_app/router/app_router.dart';
import 'package:office_assets_app/screens/shared/splash_screen.dart';

void main() {
  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider(create: (_) => AssetProvider(apiService)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider(apiService)),
        ChangeNotifierProvider(create: (_) => CategoryProvider(apiService)),
        ChangeNotifierProvider(create: (_) => LocationProvider(apiService)),
        ChangeNotifierProvider(create: (_) => DepartmentProvider(apiService)),
        ChangeNotifierProvider(create: (_) => StatusProvider(apiService)),
        ChangeNotifierProvider(create: (_) => TicketProvider(apiService)),
        ChangeNotifierProvider(create: (_) => AlertProvider(apiService)),
      ],
      child: const OfficeAssetsApp(),
    ),
  );
}

class OfficeAssetsApp extends StatefulWidget {
  const OfficeAssetsApp({super.key});

  @override
  State<OfficeAssetsApp> createState() => _OfficeAssetsAppState();
}

class _OfficeAssetsAppState extends State<OfficeAssetsApp> {
  bool _showSplash = true;
  late final GoRouter _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_showSplash) return;
    // Router will be created once splash completes
  }

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
      _router = appRouter(context.read<AuthProvider>());
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    if (_showSplash) {
      return MaterialApp(
        title: 'Office Assets',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,
        home: SplashScreen(onComplete: _onSplashComplete),
      );
    }

    return MaterialApp.router(
      title: 'Office Assets',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
    );
  }
}
