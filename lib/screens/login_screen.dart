import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../api/client.dart';
import '../theme/app_theme.dart';

/// Auth-only accent (mock used blue; app uses yellow here without changing global admin theme).
const Color _authYellow = Color(0xFFE5B800);
const Color _authYellowPressed = Color(0xFFC9A200);
const Color _authBgGray = Color(0xFFE8EAED);
const Color _authTitle = Color(0xFF1A1D21);
const Color _authMuted = Color(0xFF6B7280);
const String _kAppIconAsset = 'assets/icons/app_icon.png';

enum _AuthView { signIn, signUp, signUpAgent, signUpDealer, forgot }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _agentFormKey = GlobalKey<FormState>();
  final _dealerFormKey = GlobalKey<FormState>();
  final _forgotFormKey = GlobalKey<FormState>();

  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();

  final _agentNameController = TextEditingController();
  final _agentEmailController = TextEditingController();
  final _agentPhoneController = TextEditingController();
  final _agentPasswordController = TextEditingController();

  final _dealerBusinessController = TextEditingController();
  final _dealerContactController = TextEditingController();
  final _dealerEmailController = TextEditingController();
  final _dealerPhoneController = TextEditingController();
  final _dealerPasswordController = TextEditingController();

  final _forgotEmailController = TextEditingController();

  _AuthView _view = _AuthView.signIn;
  bool _loading = false;
  String? _error;
  bool _obscureSignInPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureAgentPassword = true;
  bool _obscureDealerPassword = true;

  Future<void> _submitSignIn() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await login(_signInEmailController.text.trim(), _signInPasswordController.text);
      if (!mounted) return;
      final user = await getStoredUser();
      if (!mounted) return;
      final role = user?['role'] as String?;
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      } else if (role == 'agent') {
        Navigator.pushReplacementNamed(context, '/agent/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _agentNameController.dispose();
    _agentEmailController.dispose();
    _agentPhoneController.dispose();
    _agentPasswordController.dispose();
    _dealerBusinessController.dispose();
    _dealerContactController.dispose();
    _dealerEmailController.dispose();
    _dealerPhoneController.dispose();
    _dealerPasswordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    const borderRadius = BorderRadius.all(Radius.circular(12));
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: const OutlineInputBorder(borderRadius: borderRadius),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: _authYellow, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.red.shade600, width: 2),
      ),
    );
  }

  Widget _heroImage() {
    return Image.asset(
      _kAppIconAsset,
      height: 140,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.broken_image_outlined, size: 80, color: Colors.grey.shade400),
    );
  }

  Widget _linkButton({required String text, required VoidCallback onTap}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _authYellow,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _primaryButton({required String label, required VoidCallback? onPressed}) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _authYellow,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _authYellow.withValues(alpha: 0.5),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return _authYellowPressed;
          return null;
        }),
      ),
      child: _loading && _view == _AuthView.signIn
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label),
    );
  }

  Widget _legalBlurb() {
    return Text.rich(
      TextSpan(
        style: TextStyle(color: _authMuted, fontSize: 12, height: 1.4),
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => _snack('Terms open in browser is not wired yet.'),
              child: const Text(
                'Terms & Conditions',
                style: TextStyle(color: _authYellow, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ),
          const TextSpan(text: ' and '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => _snack('Privacy policy is not wired yet.'),
              child: const Text(
                'Privacy Policy',
                style: TextStyle(color: _authYellow, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _signupModeLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Other signup',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _authMuted,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _view = _AuthView.signUpAgent),
                icon: Icon(Icons.support_agent_rounded, size: 18, color: _authYellow),
                label: const Text('Agent'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _authTitle,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _view = _AuthView.signUpDealer),
                icon: Icon(Icons.storefront_outlined, size: 18, color: _authYellow),
                label: const Text('Dealer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _authTitle,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _signInBody() {
    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign In',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _authTitle,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter valid email and password to continue',
            style: TextStyle(color: _authMuted, fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, style: errorStyle()),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _signInEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _fieldDecoration(
              hint: 'Email address',
              prefixIcon: const Icon(Icons.person_outline, size: 22, color: _authMuted),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _signInPasswordController,
            obscureText: _obscureSignInPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (_signInFormKey.currentState!.validate()) _submitSignIn();
            },
            decoration: _fieldDecoration(
              hint: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 22, color: _authMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignInPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: _authMuted,
                ),
                onPressed: () => setState(() => _obscureSignInPassword = !_obscureSignInPassword),
              ),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _linkButton(
              text: 'Forget password',
              onTap: () => setState(() {
                _view = _AuthView.forgot;
                _error = null;
              }),
            ),
          ),
          const SizedBox(height: 8),
          _primaryButton(
            label: 'Login',
            onPressed: _loading
                ? null
                : () {
                    if (_signInFormKey.currentState!.validate()) _submitSignIn();
                  },
          ),
        ],
      ),
    );
  }

  Widget _signUpBody() {
    return Form(
      key: _signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Customer sign up',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _authTitle,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a customer account with your details',
            style: TextStyle(color: _authMuted, fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _signUpNameController,
            textInputAction: TextInputAction.next,
            decoration: _fieldDecoration(
              hint: 'Full name',
              prefixIcon: const Icon(Icons.badge_outlined, size: 22, color: _authMuted),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _signUpEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _fieldDecoration(
              hint: 'Email address',
              prefixIcon: const Icon(Icons.email_outlined, size: 22, color: _authMuted),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _signUpPasswordController,
            obscureText: _obscureSignUpPassword,
            textInputAction: TextInputAction.done,
            decoration: _fieldDecoration(
              hint: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 22, color: _authMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignUpPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: _authMuted,
                ),
                onPressed: () => setState(() => _obscureSignUpPassword = !_obscureSignUpPassword),
              ),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              style: TextStyle(color: _authMuted, fontSize: 12, height: 1.4),
              children: [
                const TextSpan(text: 'By signing up, you agree to our '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () => _snack('Terms open in browser is not wired yet.'),
                    child: const Text(
                      'Terms & Conditions',
                      style: TextStyle(color: _authYellow, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
                const TextSpan(text: ' and '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () => _snack('Privacy policy is not wired yet.'),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(color: _authYellow, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _primaryButton(
            label: 'Create Account',
            onPressed: () {
              if (!_signUpFormKey.currentState!.validate()) return;
              _snack('Account creation is not available in the app yet. Use Sign in if you have access.');
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account? ', style: TextStyle(color: _authMuted, fontSize: 14)),
              _linkButton(
                text: 'Sign in',
                onTap: () => setState(() => _view = _AuthView.signIn),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _agentOrDealerSignUpPlaceholder() {
    final isAgent = _view == _AuthView.signUpAgent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isAgent ? 'Agent sign up' : 'Dealer sign up',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: _authTitle,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Registration through the app is not available yet. If your administrator created an account for you, use Sign in.',
          style: TextStyle(color: _authMuted, fontSize: 14, height: 1.35),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _linkButton(
              text: 'Back to sign in',
              onTap: () => setState(() {
                _view = _AuthView.signIn;
                _error = null;
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _forgotBody() {
    return Form(
      key: _forgotFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Forget Password',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _authTitle,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            "Don't worry, it happens. Please enter the address associated with your account.",
            style: TextStyle(color: _authMuted, fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _forgotEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: _fieldDecoration(
              hint: 'Email address',
              prefixIcon: const Icon(Icons.mail_outline, size: 22, color: _authMuted),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
          ),
          const SizedBox(height: 20),
          _primaryButton(
            label: 'Send OTP',
            onPressed: () {
              if (!_forgotFormKey.currentState!.validate()) return;
              _snack('Password reset from the app is not available yet. Contact your administrator.');
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You remember your password? ', style: TextStyle(color: _authMuted, fontSize: 14)),
              _linkButton(
                text: 'Sign in',
                onTap: () => setState(() => _view = _AuthView.signIn),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_view) {
      case _AuthView.signIn:
        body = _signInBody();
        break;
      case _AuthView.signUp:
        body = _signUpBody();
        break;
      case _AuthView.signUpAgent:
      case _AuthView.signUpDealer:
        body = _agentOrDealerSignUpPlaceholder();
        break;
      case _AuthView.forgot:
        body = _forgotBody();
        break;
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: _authBgGray,
          ),
          Positioned(
            top: -40,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: IgnorePointer(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _heroImage(),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: body,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
