import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/constants.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/gallery/presentation/gallery_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/store/presentation/store_screen.dart';
import '../services/auth_service.dart';

/// 인증 상태 변경 시 라우터 갱신을 위한 Listenable
class AuthNotifier extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  Future<void> checkAuth() async {
    _isLoggedIn = await _authService.isLoggedIn();
    notifyListeners();
  }

  void setLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }
}

final authNotifier = AuthNotifier();

// Shell route key for bottom navigation
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  refreshListenable: authNotifier,
  redirect: (context, state) async {
    final isLoggedIn = authNotifier.isLoggedIn;
    final isLoggingIn = state.matchedLocation == '/login';

    // 로그인 안 됐으면 로그인 페이지로
    if (!isLoggedIn && !isLoggingIn) {
      return '/login';
    }
    // 로그인 됐는데 로그인 페이지면 홈으로
    if (isLoggedIn && isLoggingIn) {
      return '/';
    }
    return null;
  },
  routes: [
    // Login (Full screen - no bottom nav)
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(
        onLoginSuccess: () {
          authNotifier.setLoggedIn(true);
        },
      ),
    ),

    // Main app with bottom navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Home Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Gallery Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/gallery',
              builder: (context, state) => const GalleryScreen(),
            ),
          ],
        ),
        // Map Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapScreen(),
            ),
          ],
        ),
        // Store Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/store',
              builder: (context, state) => const StoreScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Main scaffold with bottom navigation
class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: _ModernBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Modern Bottom Navigation Bar
class _ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ModernBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBackground,
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: kSpaceL, vertical: kSpaceS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.map_rounded,
                label: 'Walk',
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.storefront_rounded,
                label: 'Store',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual navigation item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: kDurationMedium,
        curve: kCurveEaseOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? kSpaceL : kSpaceM,
          vertical: kSpaceS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? kSecondaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(kRadiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: kDurationMedium,
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? kSecondaryColor : kTextTertiary,
              ),
            ),
            AnimatedSize(
              duration: kDurationMedium,
              curve: kCurveEaseOut,
              child: SizedBox(
                width: isSelected ? kSpaceS : 0,
              ),
            ),
            AnimatedSize(
              duration: kDurationMedium,
              curve: kCurveEaseOut,
              child: isSelected
                  ? Text(
                      label,
                      style: TextStyle(
                        color: kSecondaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
