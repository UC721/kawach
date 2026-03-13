import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../models/emergency_profile_model.dart';
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    debugPrint('LoginScreen: _signIn triggered');
    if (!_formKey.currentState!.validate()) {
      debugPrint('LoginScreen: Form validation failed');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final auth = context.read<AuthService>();
      debugPrint('LoginScreen: Calling signInWithEmail');
      final uid = await auth.signInWithEmail(
          _emailCtrl.text.trim(), _passCtrl.text.trim());
      debugPrint('LoginScreen: signInWithEmail returned $uid');
      if (uid != null && mounted) {
        debugPrint('LoginScreen: Loading user data');
        await context.read<UserService>().loadCurrentUser(uid);
        // debugPrint('LoginScreen: Saving FCM token'); // removed FCM
        // await context.read<NotificationService>().saveFcmToken(uid); // removed FCM
        debugPrint('LoginScreen: Navigating to Dashboard');
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        debugPrint('LoginScreen: uid was null or widget not mounted');
      }
    } catch (e, stack) {
      debugPrint('LoginScreen: _signIn error caught: $e\nStacktrace: $stack');
      setState(() { _errorMsg = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _signUp() async {
    debugPrint('LoginScreen: _signUp triggered');
    if (!_formKey.currentState!.validate()) {
      debugPrint('LoginScreen: Form validation failed');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final auth = context.read<AuthService>();
      debugPrint('LoginScreen: Calling signUpWithEmail');
      final uid = await auth.signUpWithEmail(
          _emailCtrl.text.trim(), _passCtrl.text.trim());
      debugPrint('LoginScreen: signUpWithEmail returned $uid');
      if (uid != null && mounted) {
        final user = UserModel(
          userId: uid,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          emergencyProfile: const EmergencyProfileModel(bloodType: 'O+'),
          createdAt: DateTime.now(),
        );
        debugPrint('LoginScreen: Creating User in DB');
        await context.read<UserService>().createUser(user);
        // debugPrint('LoginScreen: Saving FCM Token');
        // await context.read<NotificationService>().saveFcmToken(user.userId);
        debugPrint('LoginScreen: Navigating to Dashboard');
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        debugPrint('LoginScreen: uid was null or widget not mounted');
      }
    } catch (e, stack) {
      debugPrint('LoginScreen: _signUp error caught: $e\nStacktrace: $stack');
      setState(() { _errorMsg = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0808), Color(0xFF0D0D0D)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  // Logo + title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.15),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.4),
                                width: 2),
                          ),
                          child: const Icon(Icons.security_rounded,
                              size: 52, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'KAWACH',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Your Shield. Always.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Tab bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Sign In'),
                        Tab(text: 'Sign Up'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Tab content
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSignInFields(),
                        _buildSignUpFields(),
                      ],
                    ),
                  ),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.danger.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMsg!,
                              style: const TextStyle(
                                  color: AppColors.danger, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () {
                              if (_tabController.index == 0) {
                                _signIn();
                              } else {
                                _signUp();
                              }
                            },
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              _tabController.index == 0
                                  ? 'Sign In'
                                  : 'Create Account',
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _emailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Enter email' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passCtrl,
          label: 'Password',
          icon: Icons.lock_outline,
          obscure: _obscurePass,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePass
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: () =>
                setState(() => _obscurePass = !_obscurePass),
          ),
          validator: (v) =>
              (v == null || v.trim().length < 6) ? 'Min 6 characters' : null,
        ),
      ],
    );
  }

  Widget _buildSignUpFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameCtrl,
          label: 'Full Name',
          icon: Icons.person_outline,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Enter your name' : null,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _phoneCtrl,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) =>
              (v == null || v.trim().length < 10) ? 'Enter valid phone' : null,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _emailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Enter email' : null,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passCtrl,
          label: 'Password',
          icon: Icons.lock_outline,
          obscure: _obscurePass,
          validator: (v) =>
              (v == null || v.trim().length < 6) ? 'Min 6 characters' : null,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
