import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../models/emergency_profile_model.dart';
import '../utils/constants.dart';
import '../widgets/immersive_ui.dart';

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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final auth = context.read<AuthService>();
      final userService = context.read<UserService>();
      final uid = await auth.signInWithEmail(
          _emailCtrl.text.trim(), _passCtrl.text.trim());
      if (uid != null) {
        await userService.loadCurrentUser(uid);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } catch (e, stack) {
      debugPrint('LoginScreen: _signIn error caught: $e\nStacktrace: $stack');
      setState(() {
        _errorMsg = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final auth = context.read<AuthService>();
      final userService = context.read<UserService>();
      final uid = await auth.signUpWithEmail(
          _emailCtrl.text.trim(), _passCtrl.text.trim());
      if (uid != null) {
        final user = UserModel(
          userId: uid,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          emergencyProfile: const EmergencyProfileModel(bloodType: 'O+'),
          createdAt: DateTime.now(),
        );
        await userService.createUser(user);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } catch (e, stack) {
      debugPrint('LoginScreen: _signUp error caught: $e\nStacktrace: $stack');
      setState(() {
        _errorMsg = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AmbientBackground(dark: false),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: GlassPanel(
                borderRadius: 28,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                color: Colors.white.withValues(alpha: 0.72),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Logo + title
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    AppColors.primary.withValues(alpha: 0.15),
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4),
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
                                color: AppColors.textPrimary,
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
                          labelColor: Colors
                              .white, // White on red primary tab indicator
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
                            color: AppColors.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.4)),
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
                                      color: Colors.white,
                                      strokeWidth:
                                          2.5), // White on primary button
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
        ],
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
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
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
      style: const TextStyle(color: AppColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
