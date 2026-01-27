import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/constants.dart';
import '../../../services/auth_service.dart';

/// 현대적인 로그인 화면
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isRegisterMode) {
        final result = await _authService.register(username, password);
        if (result['success']) {
          final loginSuccess = await _authService.login(username, password);
          if (loginSuccess) {
            HapticFeedback.mediumImpact();
            widget.onLoginSuccess();
          }
        } else {
          setState(() => _errorMessage = result['message']);
        }
      } else {
        final success = await _authService.login(username, password);
        if (success) {
          HapticFeedback.mediumImpact();
          widget.onLoginSuccess();
        } else {
          setState(() => _errorMessage = '아이디 또는 비밀번호가 올바르지 않습니다.');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = '오류가 발생했습니다. 다시 시도해주세요.');
    }

    setState(() => _isLoading = false);
  }

  void _toggleMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            padding: const EdgeInsets.all(kSpaceXXL),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: kSpace4XL),

                    // Logo & Brand
                    _buildHeader(),

                    const SizedBox(height: kSpace5XL),

                    // Form Card
                    _buildFormCard(),

                    const SizedBox(height: kSpaceXXL),

                    // Toggle Mode
                    _buildToggleMode(),

                    const SizedBox(height: kSpace4XL),

                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Animated Logo Container
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1200),
          tween: Tween(begin: 0.8, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  borderRadius: BorderRadius.circular(kRadiusXXL),
                  boxShadow: [kColoredShadow(kSecondaryColor, opacity: 0.3)],
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: kSpaceXXL),

        // App Name
        Text(
          'PetCam',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
        ),

        const SizedBox(height: kSpaceS),

        // Tagline
        Text(
          _isRegisterMode ? '새로운 여정을 시작하세요' : '반려동물과 함께하는 특별한 순간',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: kTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(kSpaceXXL),
      decoration: kCardDecoration(
        borderRadius: kRadiusXXL,
        shadows: [kShadowL],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              _isRegisterMode ? '회원가입' : '로그인',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: kSpaceXXL),

            // Username Field
            _buildTextField(
              controller: _usernameController,
              label: '아이디',
              icon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '아이디를 입력하세요';
                }
                if (value.length < 3) {
                  return '아이디는 3자 이상이어야 합니다';
                }
                return null;
              },
            ),

            const SizedBox(height: kSpaceL),

            // Password Field
            _buildTextField(
              controller: _passwordController,
              label: '비밀번호',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: kTextTertiary,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 입력하세요';
                }
                if (value.length < 6) {
                  return '비밀번호는 6자 이상이어야 합니다';
                }
                return null;
              },
            ),

            // Error Message
            AnimatedSize(
              duration: kDurationMedium,
              child: _errorMessage != null
                  ? Container(
                      margin: const EdgeInsets.only(top: kSpaceL),
                      padding: const EdgeInsets.all(kSpaceM),
                      decoration: BoxDecoration(
                        color: kErrorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(kRadiusM),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: kErrorColor,
                            size: 20,
                          ),
                          const SizedBox(width: kSpaceS),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: kErrorColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: kSpaceXXL),

            // Submit Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        suffixIcon: suffixIcon,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintText: label,
      ),
      validator: validator,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: kDurationMedium,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: kSecondaryColor,
          disabledBackgroundColor: kSecondaryColor.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusL),
          ),
          elevation: _isLoading ? 0 : 2,
          shadowColor: kSecondaryColor.withOpacity(0.4),
        ),
        child: AnimatedSwitcher(
          duration: kDurationFast,
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isRegisterMode ? '계정 만들기' : '로그인',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: kSpaceS),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildToggleMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isRegisterMode ? '이미 계정이 있나요?' : '아직 계정이 없나요?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: _toggleMode,
          child: Text(
            _isRegisterMode ? '로그인' : '회원가입',
            style: TextStyle(
              color: kSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Divider
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: kTextMuted.withOpacity(0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kSpaceL),
              child: Text(
                '또는',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: kTextMuted.withOpacity(0.3),
              ),
            ),
          ],
        ),

        const SizedBox(height: kSpaceXXL),

        // Social Login Options (placeholder)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              icon: Icons.g_mobiledata_rounded,
              color: const Color(0xFFEA4335),
              onTap: () => _showComingSoon('Google'),
            ),
            const SizedBox(width: kSpaceL),
            _buildSocialButton(
              icon: Icons.apple_rounded,
              color: kPrimaryColor,
              onTap: () => _showComingSoon('Apple'),
            ),
            const SizedBox(width: kSpaceL),
            _buildSocialButton(
              icon: Icons.chat_bubble_rounded,
              color: const Color(0xFFFEE500),
              iconColor: const Color(0xFF3C1E1E),
              onTap: () => _showComingSoon('Kakao'),
            ),
          ],
        ),

        const SizedBox(height: kSpaceXXL),

        // Terms
        Text(
          '로그인 시 이용약관 및 개인정보처리방침에 동의합니다',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(kRadiusL),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: iconColor ?? color,
          size: 28,
        ),
      ),
    );
  }

  void _showComingSoon(String provider) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider 로그인은 준비 중입니다'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusM),
        ),
      ),
    );
  }
}
