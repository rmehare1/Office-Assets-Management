import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:office_assets_app/providers/auth_provider.dart';
import 'package:office_assets_app/screens/shared/login_screen.dart';
import 'package:office_assets_app/screens/shared/home_screen.dart';
import 'package:office_assets_app/screens/admin/dashboard_screen.dart';
import 'package:office_assets_app/screens/admin/assets_list_screen.dart';
import 'package:office_assets_app/screens/admin/asset_detail_screen.dart';
import 'package:office_assets_app/screens/admin/asset_form_screen.dart';
import 'package:office_assets_app/screens/shared/profile_screen.dart';
import 'package:office_assets_app/screens/admin/masters/category_list_screen.dart';
import 'package:office_assets_app/screens/admin/masters/department_list_screen.dart';
import 'package:office_assets_app/screens/admin/masters/location_list_screen.dart';
import 'package:office_assets_app/screens/admin/masters/status_list_screen.dart';
import 'package:office_assets_app/screens/admin/users/users_list_screen.dart';
import 'package:office_assets_app/screens/user/my_assets_screen.dart';
import 'package:office_assets_app/screens/user/tickets_screen.dart';
import 'package:office_assets_app/screens/admin/admin_tickets_screen.dart';
import 'package:office_assets_app/screens/shared/signup_screen.dart';
import 'package:office_assets_app/screens/shared/forgot_password_screen.dart';
import 'package:office_assets_app/screens/shared/reset_password_screen.dart';

CustomTransitionPage<void> _fadeSlideTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      );
      final slideIn = Tween<Offset>(
        begin: const Offset(0.05, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );
      return FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(position: slideIn, child: child),
      );
    },
  );
}

CustomTransitionPage<void> _slideUpTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideIn = Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );
      final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      );
      return FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(position: slideIn, child: child),
      );
    },
  );
}

GoRouter appRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final path = state.uri.path;
      final isPublicRoute = path == '/login' ||
          path == '/signup' ||
          path == '/forgot-password' ||
          path == '/reset-password';

      if (!isAuthenticated && !isPublicRoute) return '/login';
      if (isAuthenticated && isPublicRoute) {
        return authProvider.isAdmin ? '/dashboard' : '/my-assets';
      }

      // Block non-admin from admin-only routes
      if (isAuthenticated && !authProvider.isAdmin) {
        final loc = state.matchedLocation;
        if (loc == '/dashboard' ||
            loc == '/assets' ||
            loc == '/assets/new' ||
            loc.endsWith('/edit') ||
            loc.startsWith('/users')) {
          return '/my-assets';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SignupScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _fadeSlideTransition(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) {
          final email = state.extra as String? ?? '';
          return _fadeSlideTransition(state, ResetPasswordScreen(email: email));
        },
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const DashboardScreen()),
          ),
          GoRoute(
            path: '/assets',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const AssetsListScreen()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _slideUpTransition(state, const AssetFormScreen()),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _fadeSlideTransition(
                      state, AssetDetailScreen(assetId: id));
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return _slideUpTransition(
                          state, AssetFormScreen(assetId: id));
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const ProfileScreen()),
          ),
          GoRoute(
            path: '/categories',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const CategoryListScreen()),
          ),
          GoRoute(
            path: '/statuses',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const StatusListScreen()),
          ),
          GoRoute(
            path: '/locations',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const LocationListScreen()),
          ),
          GoRoute(
            path: '/departments',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const DepartmentListScreen()),
          ),
          GoRoute(
            path: '/users',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const UsersListScreen()),
          ),
          GoRoute(
            path: '/admin/tickets',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const AdminTicketsScreen()),
          ),
          GoRoute(
            path: '/my-assets',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const MyAssetsScreen()),
          ),
          GoRoute(
            path: '/tickets',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const TicketsScreen()),
          ),
        ],
      ),
    ],
  );
}
