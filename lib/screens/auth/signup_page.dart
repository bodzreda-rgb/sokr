import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

// da el Sign Up screen (kol account gedid byb2a patient)
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // hena bn3ml signup f Supabase Auth
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final loggedIn = await AuthService.instance.signUp(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
      );
      if (!mounted) return;
      if (loggedIn) {
        // el AuthGate hy-route el user lw7do, fa bnrg3 lel awel
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        showSnack(context, 'Account created! Check your email to confirm, then login.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(),
      body: SoftBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppLogo(height: 90),
                      const SizedBox(height: 16),
                      const Text('Create Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text('Join us for a better and healthier you',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            hintText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) =>
                            (v == null || v.trim().length < 3) ? 'Enter your full name' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            hintText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            hintText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined)),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Password must be at least 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _hidePassword,
                        decoration: const InputDecoration(
                            hintText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline)),
                        validator: (v) =>
                            v != _passwordController.text ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loading ? null : _signUp,
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Create Account'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Already have an account? Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
