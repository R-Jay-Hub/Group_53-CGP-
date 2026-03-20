import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _obscurePass = true;
  String? _errorMsg;

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _errorMsg = 'Please fill in all fields.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      await _authService.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text('☕', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 16),
              const Text(
                'BrewMind',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF0E8DC),
                ),
              ),
              const Text(
                'Your mood-based café companion',
                style: TextStyle(fontSize: 14, color: Color(0xFF9A8C7E)),
              ),
              const SizedBox(height: 52),
              _buildLabel('Email Address'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _emailCtrl,
                hint: 'you@email.com',
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _buildLabel('Password'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _passCtrl,
                hint: '••••••••',
                obscure: _obscurePass,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF5A504A),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showForgotPassword(context),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Color(0xFFC8965A), fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x15D4856A),
                    border: Border.all(color: const Color(0x33D4856A)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(
                      color: Color(0xFFD4856A),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8965A),
                    foregroundColor: const Color(0xFF1A1714),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF1A1714),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Color(0xFF9A8C7E), fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Color(0xFFC8965A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Color(0xFF9A8C7E),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Color(0xFFF0E8DC), fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF5A504A)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1A1714),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2E2820)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2E2820)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC8965A)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1714),
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: Color(0xFFF0E8DC),
            fontFamily: 'PlayfairDisplay',
          ),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Color(0xFFF0E8DC)),
          decoration: const InputDecoration(
            hintText: 'Enter your email',
            hintStyle: TextStyle(color: Color(0xFF5A504A)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9A8C7E)),
            ),
          ),
          TextButton(
            onPressed: () async {
              await AuthService().resetPassword(ctrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset email sent!')),
              );
            },
            child: const Text(
              'Send',
              style: TextStyle(color: Color(0xFFC8965A)),
            ),
          ),
        ],
      ),
    );
  }
}
