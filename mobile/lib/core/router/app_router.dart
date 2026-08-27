import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:campusmart_mobile/features/auth/presentation/pages/register_page.dart';
import 'package:campusmart_mobile/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:campusmart_mobile/features/auth/presentation/pages/email_verification_page.dart';
import 'package:campusmart_mobile/features/auth/presentation/pages/profile_page.dart';
import 'package:campusmart_mobile/features/chat/presentation/pages/chat_list_page.dart';
import 'package:campusmart_mobile/features/chat/presentation/pages/chat_page.dart';
import 'package:campusmart_mobile/features/home/presentation/pages/home_page.dart';
import 'package:campusmart_mobile/features/listings/presentation/pages/create_listing_page.dart';
import 'package:campusmart_mobile/features/listings/presentation/pages/edit_listing_page.dart';
import 'package:campusmart_mobile/features/listings/presentation/pages/listing_detail_page.dart';
import 'package:campusmart_mobile/features/listings/presentation/pages/listings_page.dart';
import 'package:campusmart_mobile/features/listings/presentation/pages/my_listings_page.dart';
import 'package:campusmart_mobile/features/listings/presentation/pages/favorites_page.dart';
import 'package:campusmart_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:campusmart_mobile/main.dart' show navigatorKey;

// Placeholder pages - not implemented yet
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Dashboard')),
    body: const Center(child: Text('Coming Soon')),
  );
}

class AdminListingsPage extends StatelessWidget {
  const AdminListingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Listings')),
    body: const Center(child: Text('Coming Soon')),
  );
}

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Users')),
    body: const Center(child: Text('Coming Soon')),
  );
}

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Reports')),
    body: const Center(child: Text('Coming Soon')),
  );
}

class _MainShell extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  const _MainShell({required this.child, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/listings');
              break;
            case 2:
              context.go('/sell');
              break;
            case 3:
              context.go('/chat');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Sell',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      // Handle loading state - don't redirect while auth is initializing
      if (authState.isLoading) {
        return null;
      }

      final isAuthenticated = authState.hasValue && authState.value != null;
      final user = authState.value;
      final isVerified = user?.isVerified ?? false;
      final location = state.matchedLocation;
      final isAuthRoute =
          location.startsWith('/login') ||
          location.startsWith('/register') ||
          location.startsWith('/forgot-password');

      // Not authenticated: allow auth routes, redirect others to login
      if (!isAuthenticated) {
        if (!isAuthRoute && location != '/') {
          return '/login';
        }
        return null;
      }

      // Authenticated: redirect away from auth routes to main app
      if (isAuthRoute) {
        return '/';
      }

      // Authenticated but email not verified: redirect to verify-email (unless already there)
      if (!isVerified && !location.startsWith('/verify-email')) {
        return '/verify-email';
      }

      return null;
    },
    routes: [
      // Auth routes (no bottom nav)
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const EmailVerificationPage(),
      ),
      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          int currentIndex = 0;
          final location = state.matchedLocation;
          if (location.startsWith('/listings')) {
            currentIndex = 1;
          } else if (location.startsWith('/sell')) {
            currentIndex = 2;
          } else if (location.startsWith('/chat')) {
            currentIndex = 3;
          } else if (location.startsWith('/profile') ||
              location.startsWith('/my-listings') ||
              location.startsWith('/favorites')) {
            currentIndex = 4;
          }
          return _MainShell(currentIndex: currentIndex, child: child);
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/listings',
            builder: (context, state) => ListingsPage(
              initialCategory: state.uri.queryParameters['category'],
            ),
          ),
          GoRoute(
            path: '/listings/:id',
            builder: (context, state) =>
                ListingDetailPage(productId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/listings/:id/edit',
            builder: (context, state) =>
                EditListingPage(productId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/sell',
            builder: (context, state) => const CreateListingPage(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatListPage(),
          ),
          GoRoute(
            path: '/chat/:chatId',
            builder: (context, state) =>
                ChatPage(chatId: state.pathParameters['chatId']!),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/my-listings',
            builder: (context, state) => const MyListingsPage(),
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesPage(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
        ],
      ),
      // Admin routes
      GoRoute(path: '/admin', redirect: (context, state) => '/admin/dashboard'),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/admin/listings',
        builder: (context, state) => const AdminListingsPage(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const AdminReportsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Page not found', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(state.error.toString(), style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    ),
  );
});
