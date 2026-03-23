import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chatbot_service.dart';
import '../services/reservation_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _chatbotService = ChatbotService();
  final _reservationService = ReservationService();

  final List<_ChatMsg> _messages = [
    _ChatMsg(
      text:
          'Hello! I\'m Brew ☕\nHow are you feeling today?\n\nYou can also type "book a table" to make a reservation!',
      isBot: true,
    ),
  ];
  final List<ChatMessage> _history = [];
  bool _typing = false;

  _ReservationStep _resStep = _ReservationStep.none;
  String? _resDate;
  String? _resTime;
  int? _resTable;
  int? _resPartySize;

  // Detect book a table

  bool _isBookingIntent(String text) {
    final lower = text.toLowerCase();
    return lower.contains('book') ||
        lower.contains('reserve') ||
        lower.contains('reservation') ||
        lower.contains('table') ||
        lower.contains('seat') ||
        lower.contains('booking');
  }

  // message handle

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMsg(text: text, isBot: false));
      _typing = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    String reply;

    if (_resStep != _ReservationStep.none) {
      reply = await _handleReservationStep(text);
    }
    // start booking
    else if (_isBookingIntent(text)) {
      _resStep = _ReservationStep.askDate;
      reply =
          '🗓 Sure! Let\'s book a table for you.\n\nWhat date would you like? Please type in this format:\nYYYY-MM-DD\n\nExample: 2026-03-25';
    } else {
      _history.add(ChatMessage(role: 'user', content: text));
      reply = await _chatbotService.sendMessage(
        history: _history,
        userMessage: text,
      );
      _history.add(ChatMessage(role: 'assistant', content: reply));
    }

    setState(() {
      _messages.add(_ChatMsg(text: reply, isBot: true));
      _typing = false;
    });
    _scrollToBottom();
  }

  // handle reservation

  Future<String> _handleReservationStep(String input) async {
    switch (_resStep) {
      case _ReservationStep.askDate:
        final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
        if (!dateRegex.hasMatch(input)) {
          return '⚠️ Please use the correct format: YYYY-MM-DD\nExample: 2026-03-25';
        }

        final date = DateTime.tryParse(input);
        if (date == null ||
            date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
          return '⚠️ Please choose a future date.\nExample: 2026-03-25';
        }
        _resDate = input;
        _resStep = _ReservationStep.askTime;
        return '⏰ What time would you like?\n\nAvailable times:\n9:00 AM  •  9:30 AM  •  10:00 AM\n10:30 AM  •  11:00 AM  •  11:30 AM\n12:00 PM  •  12:30 PM  •  1:00 PM\n1:30 PM  •  2:00 PM  •  2:30 PM\n3:00 PM  •  3:30 PM  •  4:00 PM\n\nType the time (e.g. 10:00 or 14:00)';

      case _ReservationStep.askTime:
        final timeRegex = RegExp(r'^\d{1,2}:\d{2}$');
        if (!timeRegex.hasMatch(input)) {
          return '⚠️ Please type time like: 10:00 or 14:30';
        }
        _resTime = input;
        _resStep = _ReservationStep.askTable;
        return '🪑 Which table number would you like?\n\nWe have Tables 1 to 10.\nType a number (1-10):';

      case _ReservationStep.askTable:
        final tableNum = int.tryParse(input.trim());
        if (tableNum == null || tableNum < 1 || tableNum > 10) {
          return '⚠️ Please type a table number between 1 and 10.';
        }
        _resTable = tableNum;
        _resStep = _ReservationStep.askPartySize;
        return '👥 How many guests? (1 to 8)\nType the number of people:';

      case _ReservationStep.askPartySize:
        final party = int.tryParse(input.trim());
        if (party == null || party < 1 || party > 8) {
          return '⚠️ Please type a number between 1 and 8 guests.';
        }
        _resPartySize = party;
        _resStep = _ReservationStep.confirm;
        return '✅ Please confirm your reservation:\n\n'
            '📅 Date:   $_resDate\n'
            '⏰ Time:   $_resTime\n'
            '🪑 Table:  Table $_resTable\n'
            '👥 Guests: $_resPartySize\n\n'
            'Type YES to confirm or NO to cancel.';

      // Confirm firebase save

      case _ReservationStep.confirm:
        if (input.toLowerCase() == 'yes' || input.toLowerCase() == 'y') {
          return await _saveReservation();
        } else {
          _resetReservation();
          return '❌ Reservation cancelled.\n\nNo problem! Type "book a table" anytime to start again. ☕';
        }

      default:
        _resetReservation();
        return 'Something went wrong. Please try again.';
    }
  }

  Future<String> _saveReservation() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _resetReservation();
        return '⚠️ You need to be logged in to make a reservation.';
      }

      // Check availability
      final reservationId = await _reservationService.createReservation(
        userId: uid,
        date: _resDate!,
        time: _resTime!,
        tableNumber: _resTable!,
        partySize: _resPartySize!,
      );

      _resetReservation();

      return '🎉 Reservation confirmed!\n\n'
          '📅 Date:   $_resDate\n'
          '⏰ Time:   $_resTime\n'
          '🪑 Table:  Table $_resTable\n'
          '👥 Guests: $_resPartySize\n\n'
          '⭐ +5 Star Points awarded!\n'
          'Booking ID: ${reservationId.substring(0, 8)}…\n\n'
          'See you at BrewMind Café! ☕';
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _resetReservation();
      return '❌ $msg\n\nType "book a table" to try a different table.';
    }
  }

  // Reset reservation state
  void _resetReservation() {
    _resStep = _ReservationStep.none;
    _resDate = null;
    _resTime = null;
    _resTable = null;
    _resPartySize = null;
  }

  // Test Gemini connection
  Future<void> _testConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: Color(0xFF1A1714),
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFFC8965A)),
            SizedBox(width: 16),
            Text(
              'Testing Gemini...',
              style: TextStyle(color: Color(0xFFF0E8DC)),
            ),
          ],
        ),
      ),
    );

    final result = await _chatbotService.sendMessage(
      history: [],
      userMessage: 'Say: Gemini connected!',
    );
    Navigator.pop(context);

    final success = !result.startsWith('❌');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1714),
        title: Text(
          success ? '✅ Gemini Working!' : '❌ Gemini Failed',
          style: TextStyle(
            color: success ? const Color(0xFF7EB8A4) : const Color(0xFFD4856A),
            fontFamily: 'PlayfairDisplay',
            fontSize: 16,
          ),
        ),
        content: Text(
          result,
          style: const TextStyle(color: Color(0xFFF0E8DC), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFFC8965A))),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🤖 ', style: TextStyle(fontSize: 22)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Brew',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'AI Barista + Reservation Assistant',
                  style: TextStyle(fontSize: 10, color: Color(0xFF9A8C7E)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _testConnection,
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Test Gemini',
            color: const Color(0xFF9A8C7E),
          ),
        ],
        backgroundColor: const Color(0xFF1A1714),
        foregroundColor: const Color(0xFFF0E8DC),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF1A1714),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickBtn(
                    label: '🪑 Book a Table',
                    onTap: () {
                      _msgCtrl.text = 'book a table';
                      _sendMessage();
                    },
                  ),
                  _QuickBtn(
                    label: '☕ Show Menu',
                    onTap: () {
                      _msgCtrl.text = 'show me the menu';
                      _sendMessage();
                    },
                  ),
                  _QuickBtn(
                    label: '😊 I\'m Happy',
                    onTap: () {
                      _msgCtrl.text = 'I\'m feeling happy';
                      _sendMessage();
                    },
                  ),
                  _QuickBtn(
                    label: '😴 I\'m Tired',
                    onTap: () {
                      _msgCtrl.text = 'I\'m feeling tired';
                      _sendMessage();
                    },
                  ),
                  _QuickBtn(
                    label: '⭐ My Points',
                    onTap: () {
                      _msgCtrl.text = 'how do loyalty points work';
                      _sendMessage();
                    },
                  ),
                ],
              ),
            ),
          ),

          if (_resStep != _ReservationStep.none)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0x22C8965A),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_seat_outlined,
                    color: Color(0xFFC8965A),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Booking in progress — Step ${_resStep.index} of 5',
                    style: const TextStyle(
                      color: Color(0xFFC8965A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _resetReservation();
                        _messages.add(
                          _ChatMsg(
                            text:
                                '❌ Reservation cancelled. How can I help you?',
                            isBot: true,
                          ),
                        );
                      });
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFFD4856A),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFD4856A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (_typing && i == _messages.length) {
                  return const _TypingIndicator();
                }
                return _ChatBubble(msg: _messages[i]);
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1714),
              border: Border(top: BorderSide(color: Color(0xFF2E2820))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(
                      color: Color(0xFFF0E8DC),
                      fontSize: 14,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: _resStep == _ReservationStep.none
                          ? 'Ask me anything or type "book a table"...'
                          : 'Type your answer...',
                      hintStyle: const TextStyle(color: Color(0xFF5A504A)),
                      filled: true,
                      fillColor: const Color(0xFF231F1B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8965A),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF1A1714),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Reservation step tracker
enum _ReservationStep {
  none,
  askDate,
  askTime,
  askTable,
  askPartySize,
  confirm,
}

// Quick action button widget
class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF231F1B),
          border: Border.all(color: const Color(0xFF2E2820)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9A8C7E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Chat bubble
class _ChatMsg {
  final String text;
  final bool isBot;
  _ChatMsg({required this.text, required this.isBot});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: msg.isBot ? const Color(0xFF1A1714) : const Color(0x22C8965A),
          border: Border.all(
            color: msg.isBot
                ? const Color(0xFF2E2820)
                : const Color(0x44C8965A),
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(msg.isBot ? 4 : 14),
            bottomRight: Radius.circular(msg.isBot ? 14 : 4),
          ),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFFF0E8DC),
          ),
        ),
      ),
    );
  }
}

// Typing indicator

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text(
          'Brew is typing... ☕',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF9A8C7E),
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}