import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  String? _errorMsg;

  // Allergy selections
  final Map<String, bool> _allergies = {
    'milk': false,
    'nuts': false,
    'gluten': false,
    'soy': false,
  };

  Future<void> _register() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty) {
      setState(() => _errorMsg = 'Please fill in all required fields.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final selectedAllergies = _allergies.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      await _authService.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        birthday: _birthdayCtrl.text,
        allergies: selectedAllergies,
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFFC8965A)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _birthdayCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF0F0D0B),
        foregroundColor: const Color(0xFFF0E8DC),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Join BrewMind',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF0E8DC),
              ),
            ),
            const Text(
              'Get mood-based drink recommendations',
              style: TextStyle(fontSize: 13, color: Color(0xFF9A8C7E)),
            ),
            const SizedBox(height: 32),

            _buildField('Full Name *', _nameCtrl, 'Aisha Rahman'),
            const SizedBox(height: 16),
            _buildField(
              'Email Address *',
              _emailCtrl,
              'you@email.com',
              keyboard: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildField(
              'Password *',
              _passCtrl,
              'Min. 6 characters',
              obscure: true,
            ),
            const SizedBox(height: 16),

            // Birthday picker
            _buildLabel('Birthday (for bonus points)'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickBirthday,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1714),
                  border: Border.all(color: const Color(0xFF2E2820)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _birthdayCtrl.text.isEmpty
                            ? 'Select your birthday'
                            : _birthdayCtrl.text,
                        style: TextStyle(
                          color: _birthdayCtrl.text.isEmpty
                              ? const Color(0xFF5A504A)
                              : const Color(0xFFF0E8DC),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.cake_outlined,
                      color: Color(0xFF9A8C7E),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Allergies
            _buildLabel('Food Allergies (select all that apply)'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allergies.entries.map((entry) {
                final labels = {
                  'milk': '🥛 Milk',
                  'nuts': '🥜 Nuts',
                  'gluten': '🌾 Gluten',
                  'soy': '🫘 Soy',
                };
                return FilterChip(
                  label: Text(
                    labels[entry.key]!,
                    style: TextStyle(
                      fontSize: 13,
                      color: entry.value
                          ? const Color(0xFF1A1714)
                          : const Color(0xFF9A8C7E),
                    ),
                  ),
                  selected: entry.value,
                  onSelected: (val) =>
                      setState(() => _allergies[entry.key] = val),
                  selectedColor: const Color(0xFFC8965A),
                  backgroundColor: const Color(0xFF1A1714),
                  side: BorderSide(
                    color: entry.value
                        ? const Color(0xFFC8965A)
                        : const Color(0xFF2E2820),
                  ),
                  checkmarkColor: const Color(0xFF1A1714),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

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
                onPressed: _loading ? null : _register,
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
                        'Create Account',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
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

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboard,
          style: const TextStyle(color: Color(0xFFF0E8DC), fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF5A504A)),
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
        ),
      ],
    );
  }
}
