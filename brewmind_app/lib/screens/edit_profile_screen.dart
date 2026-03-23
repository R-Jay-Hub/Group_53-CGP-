import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController();

  // Allergy selections

  final Map<String, bool> _allergies = {
    'milk': false,
    'nuts': false,
    'gluten': false,
    'soy': false,
  };

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _birthdayCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameCtrl.text = data['name'] ?? '';
        _emailCtrl.text = data['email'] ?? _auth.currentUser?.email ?? '';
        _birthdayCtrl.text = data['birthday'] ?? '';
        final saved = List<String>.from(data['allergies'] ?? []);
        for (final key in _allergies.keys) {
          _allergies[key] = saved.contains(key);
        }
      } else {
        _nameCtrl.text = _auth.currentUser?.displayName ?? '';
        _emailCtrl.text = _auth.currentUser?.email ?? '';
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // Pick birthday
  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFC8965A),
            surface: Color(0xFF1A1714),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _birthdayCtrl.text =
            '${picked.year}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  // Save changes
  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name cannot be empty.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final selectedAllergies = _allergies.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      await _db.collection('users').doc(uid).update({
        'name': name,
        'birthday': _birthdayCtrl.text,
        'allergies': selectedAllergies,
      });

      await _auth.currentUser?.updateDisplayName(name);

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Profile updated successfully!'),
          backgroundColor: Color(0xFF1A1714),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF0F0D0B),
        foregroundColor: const Color(0xFFF0E8DC),
        elevation: 0,
        actions: [
          // Save button in app bar
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Color(0xFFC8965A),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFFC8965A),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC8965A)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: const Color(0xFFC8965A),
                          child: Text(
                            _nameCtrl.text.isNotEmpty
                                ? _nameCtrl.text[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Color(0xFF1A1714),
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC8965A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0F0D0B),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Color(0xFF1A1714),
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x15D4856A),
                        border: Border.all(color: const Color(0x33D4856A)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFD4856A),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFD4856A),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildLabel('Full Name *'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameCtrl,
                    hint: 'Your full name',
                    icon: Icons.person_outline,
                    onChanged: (_) => setState(() {}), // refresh avatar
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Email Address'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailCtrl,
                    hint: 'your@email.com',
                    icon: Icons.email_outlined,
                    readOnly: true,
                    hint2: 'Email cannot be changed',
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Birthday'),
                  const SizedBox(height: 8),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cake_outlined,
                            color: Color(0xFF9A8C7E),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _birthdayCtrl.text.isEmpty
                                  ? 'Select your birthday'
                                  : _birthdayCtrl.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: _birthdayCtrl.text.isEmpty
                                    ? const Color(0xFF5A504A)
                                    : const Color(0xFFF0E8DC),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF5A504A),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Text(
                    '🎂 Get +50 star points on your birthday!',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9A8C7E)),
                  ),
                  const SizedBox(height: 28),

                  _buildLabel('Food Allergies'),
                  const SizedBox(height: 4),
                  const Text(
                    'We will filter out drinks containing these ingredients.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9A8C7E)),
                  ),
                  const SizedBox(height: 14),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3.5,
                    children: [
                      _allergyChip('milk', '🥛 Milk'),
                      _allergyChip('nuts', '🥜 Nuts'),
                      _allergyChip('gluten', '🌾 Gluten'),
                      _allergyChip('soy', '🫘 Soy'),
                    ],
                  ),
                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8965A),
                        foregroundColor: const Color(0xFF1A1714),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFF1A1714),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    String? hint2,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          readOnly: readOnly,
          onChanged: onChanged,
          style: TextStyle(
            color: readOnly ? const Color(0xFF5A504A) : const Color(0xFFF0E8DC),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF5A504A)),
            prefixIcon: Icon(icon, color: const Color(0xFF9A8C7E), size: 20),
            filled: true,
            fillColor: readOnly
                ? const Color(0xFF141210)
                : const Color(0xFF1A1714),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E2820)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E2820)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC8965A)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        if (hint2 != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              hint2,
              style: const TextStyle(fontSize: 11, color: Color(0xFF5A504A)),
            ),
          ),
      ],
    );
  }

  Widget _allergyChip(String key, String label) {
    final isSelected = _allergies[key] ?? false;
    return GestureDetector(
      onTap: () => setState(() => _allergies[key] = !isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x22C8965A) : const Color(0xFF1A1714),
          border: Border.all(
            color: isSelected
                ? const Color(0x66C8965A)
                : const Color(0xFF2E2820),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected
                  ? const Color(0xFFC8965A)
                  : const Color(0xFF5A504A),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFC8965A)
                    : const Color(0xFF9A8C7E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}