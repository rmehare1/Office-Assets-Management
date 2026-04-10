import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/providers/asset_provider.dart';
import 'package:office_assets_app/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load assets when home screen first mounts (admin only)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().isAdmin) {
        context.read<AssetProvider>().loadAssets();
      }
    });
  }

  int _currentIndex(BuildContext context, bool isAdmin) {
    final location = GoRouterState.of(context).matchedLocation;
    if (isAdmin) {
      if (location.startsWith('/assets')) return 1;
      if (location == '/profile') return 2;
      if (location.startsWith('/users')) return 3;
      return 0; // /dashboard
    } else {
      if (location.startsWith('/tickets')) return 1;
      if (location == '/profile') return 2;
      return 0; // /my-assets
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context, isAdmin),
        onTap: (index) {
          if (isAdmin) {
            switch (index) {
              case 0: context.go('/dashboard');
              case 1: context.go('/assets');
              case 2: context.go('/profile');
              case 3: context.go('/users');
            }
          } else {
            switch (index) {
              case 0: context.go('/my-assets');
              case 1: context.go('/tickets');
              case 2: context.go('/profile');
            }
          }
        },
        items: isAdmin
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2),
                  label: 'Assets',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Users',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2),
                  label: 'My Assets',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.confirmation_number_outlined),
                  activeIcon: Icon(Icons.confirmation_number),
                  label: 'Tickets',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
      ),
    );
  }
}
