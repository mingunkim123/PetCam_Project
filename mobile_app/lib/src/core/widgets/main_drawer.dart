import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../constants/constants.dart';
import '../../routing/app_router.dart';
import '../../services/auth_service.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Drawer(
      backgroundColor: kCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(kRadiusXXL)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: kSpaceL),
              children: [
                _buildSectionTitle(context, '메뉴'),
                _buildMenuItem(
                  context,
                  icon: Icons.home_rounded,
                  title: '홈',
                  route: '/',
                  color: kSecondaryColor,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.photo_library_rounded,
                  title: '갤러리',
                  route: '/gallery',
                  color: kAccentPurple,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.map_rounded,
                  title: '산책 지도',
                  route: '/map',
                  color: kAccentGreen,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.storefront_rounded,
                  title: '펫 스토어',
                  route: '/store',
                  color: kAccentOrange,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: kSpaceXXL, vertical: kSpaceM),
                  child: Divider(),
                ),

                _buildSectionTitle(context, '설정'),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: '설정',
                  route: null,
                  color: kTextSecondary,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: '도움말',
                  route: null,
                  color: kTextSecondary,
                ),
              ],
            ),
          ),

          // Footer with Logout
          _buildFooter(context, authService),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        kSpaceXXL,
        MediaQuery.of(context).padding.top + kSpaceXXL,
        kSpaceXXL,
        kSpaceXXL,
      ),
      decoration: const BoxDecoration(
        gradient: kPrimaryGradient,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(kRadius3XL),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Avatar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.pets_rounded,
                color: kSecondaryColor,
                size: 36,
              ),
            ),
          ),

          const SizedBox(height: kSpaceL),

          // User Info
          const Text(
            'PetCam User',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: kSpaceXXS),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: kSuccessColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kSuccessColor.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kSpaceS),
              Text(
                '로그인됨',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSpaceXXL, kSpaceS, kSpaceXXL, kSpaceS),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: kTextTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String? route,
    required Color color,
  }) {
    final isCurrentRoute = route != null && GoRouterState.of(context).uri.path == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpaceL, vertical: kSpaceXXS),
      child: Material(
        color: isCurrentRoute ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(kRadiusM),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
            if (route != null && !isCurrentRoute) {
              context.go(route);
            }
          },
          borderRadius: BorderRadius.circular(kRadiusM),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kSpaceL,
              vertical: kSpaceM,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(kSpaceS),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isCurrentRoute ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(kRadiusS),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: kSpaceM),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isCurrentRoute ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 15,
                      color: isCurrentRoute ? color : kTextPrimary,
                    ),
                  ),
                ),
                if (isCurrentRoute)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AuthService authService) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        kSpaceL,
        kSpaceL,
        kSpaceL,
        MediaQuery.of(context).padding.bottom + kSpaceL,
      ),
      decoration: BoxDecoration(
        color: kSurfaceElevated,
        border: Border(
          top: BorderSide(
            color: kTextMuted.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // App Version
          Text(
            'PetCam v1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: kTextTertiary,
            ),
          ),
          const SizedBox(height: kSpaceM),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);

                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('정말 로그아웃 하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccentColor,
                        ),
                        child: const Text('로그아웃'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  await authService.logout();
                  authNotifier.setLoggedIn(false);
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('로그아웃'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kAccentColor,
                side: BorderSide(color: kAccentColor.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: kSpaceM),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
