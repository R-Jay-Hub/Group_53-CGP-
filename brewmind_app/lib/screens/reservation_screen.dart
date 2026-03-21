import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/reservation_service.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});
  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  DateTime? _selectedDate;
  String? _selectedTime;
  int _selectedTable = 1;
  int _partySize = 2;
  bool _loading = false;

  final _reservationService = ReservationService();

  final List<String> _timeSlots = [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFFC8965A)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _confirmReservation() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);
    try {
      await _reservationService.createReservation(
        userId: uid,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        time: _selectedTime!,
        tableNumber: _selectedTable,
        partySize: _partySize,
      );

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1714),
          title: const Text(
            'Reservation Confirmed! 🎉',
            style: TextStyle(
              color: Color(0xFFF0E8DC),
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          content: Text(
            'Table $_selectedTable on ${DateFormat('d MMM').format(_selectedDate!)} at $_selectedTime.\n\n+5 ⭐ Star Points awarded!',
            style: const TextStyle(color: Color(0xFF9A8C7E)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Great!',
                style: TextStyle(color: Color(0xFFC8965A)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Reserve a Table',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF0E8DC),
                ),
              ),
              const Text(
                'Book your perfect café spot',
                style: TextStyle(fontSize: 13, color: Color(0xFF9A8C7E)),
              ),
              const SizedBox(height: 32),

              // Date picker
              _sectionLabel('Select Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1714),
                    border: Border.all(
                      color: _selectedDate != null
                          ? const Color(0xff55c8965a)
                          : const Color(0xFF2E2820),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Color(0xFFC8965A),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? 'Tap to select a date'
                            : DateFormat(
                                'EEEE, d MMMM yyyy',
                              ).format(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate == null
                              ? const Color(0xFF5A504A)
                              : const Color(0xFFF0E8DC),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time slots
              _sectionLabel('Select Time'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((time) {
                  final isSelected = _selectedTime == time;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTime = time),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0x22C8965A)
                            : const Color(0xFF1A1714),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xff55c8965a)
                              : const Color(0xFF2E2820),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFFC8965A)
                              : const Color(0xFF9A8C7E),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Table number
              _sectionLabel('Table Number (1-10)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(10, (i) {
                  final table = i + 1;
                  final isSelected = _selectedTable == table;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTable = table),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0x22C8965A)
                            : const Color(0xFF1A1714),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xff55c8965a)
                              : const Color(0xFF2E2820),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '$table',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFFC8965A)
                                : const Color(0xFF9A8C7E),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Party size
              _sectionLabel('Party Size'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1714),
                  border: Border.all(color: const Color(0xFF2E2820)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Number of guests',
                      style: TextStyle(color: Color(0xFF9A8C7E), fontSize: 14),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove,
                            color: Color(0xFF9A8C7E),
                            size: 20,
                          ),
                          onPressed: () {
                            if (_partySize > 1) setState(() => _partySize--);
                          },
                        ),
                        Text(
                          '$_partySize',
                          style: const TextStyle(
                            color: Color(0xFFF0E8DC),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add,
                            color: Color(0xFFC8965A),
                            size: 20,
                          ),
                          onPressed: () {
                            if (_partySize < 8) setState(() => _partySize++);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _confirmReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8965A),
                    foregroundColor: const Color(0xFF1A1714),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Color(0xFF1A1714),
                        )
                      : const Text(
                          'Confirm Reservation (+5 pts)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Color(0xFF5A504A),
        letterSpacing: 2,
      ),
    );
  }
}
