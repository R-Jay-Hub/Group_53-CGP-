import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String role;
  final String content;
  ChatMessage({required this.role, required this.content});
}

class ChatbotService {
  static const bool _useGemini = true;

  // GEMINI settings
  static const String _geminiKey = '';
  static const String _geminiModel = 'gemini-2.5-flash';
  static String get _geminiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiKey';

  // DIALOGFLOW settings
  static const String _dfProjectId = 'YOUR_DIALOGFLOW_PROJECT_ID';
  static const String _dfApiKey = 'YOUR_GOOGLE_CLOUD_API_KEY';

  static final String _dfSessionId = 'session-${Random().nextInt(999999)}';
  static String get _dfUrl =>
      'https://dialogflow.googleapis.com/v2/projects/$_dfProjectId/agent/sessions/$_dfSessionId:detectIntent?key=$_dfApiKey';

  static const String _systemPrompt = '''
You are Brew, a friendly barista assistant at BrewMind Cafe.
Your role:
1. Ask how the user is feeling (their mood)
2. Ask about food allergies (milk, nuts, gluten, soy)
3. Recommend drinks based on mood and allergies
4. Help with ordering, reservations, loyalty points

BrewMind Menu:
HAPPY: Iced Matcha Latte RM14.50, Cold Brew Float RM18, Mango Passionfruit RM16
RELAXED: Chamomile Honey RM11, Rose Petal Tea RM12
STRESSED: Lavender Latte RM16, Turmeric Latte RM13.50
TIRED: Double Espresso RM8, Cappuccino RM12, Flat White RM11
ENERGETIC: Green Smoothie RM15, Acai Power Bowl RM22

Allergens: Milk in all coffee drinks. Nuts in Green Smoothie and Acai Bowl. Gluten in Acai Bowl.
Milk and nut free: Chamomile Honey, Rose Petal Tea, Mango Passionfruit.

Loyalty: +10 pts per order, +5 pts per reservation, +50 pts on birthday.

Be warm and concise. Use emojis. Max 3 sentences per reply.
''';

  // Main entry point
  Future<String> sendMessage({
    required List<ChatMessage> history,
    required String userMessage,
  }) async {
    if (_useGemini) {
      return _sendToGemini(history: history, userMessage: userMessage);
    } else {
      return _sendToDialogflow(userMessage: userMessage);
    }
  }

  Future<String> _sendToGemini({
    required List<ChatMessage> history,
    required String userMessage,
  }) async {
    try {
      print('🤖 [Gemini] Sending: "$userMessage"');

      final List<Map<String, dynamic>> contents = [];

      // System prompt as first exchange
      contents.add({
        'role': 'user',
        'parts': [
          {'text': _systemPrompt},
        ],
      });
      contents.add({
        'role': 'model',
        'parts': [
          {
            'text':
                'Hi! I am Brew, your BrewMind barista. How are you feeling today?',
          },
        ],
      });

      // Add conversation history
      for (final msg in history) {
        contents.add({
          'role': msg.role == 'assistant' ? 'model' : 'user',
          'parts': [
            {'text': msg.content},
          ],
        });
      }

      // Add new message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': userMessage},
        ],
      });

      final response = await http.post(
        Uri.parse(_geminiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {'maxOutputTokens': 250, 'temperature': 0.7},
        }),
      );

      print('📡 [Gemini] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['candidates'][0]['content']['parts'][0]['text']
            .toString()
            .trim();
        print('✅ [Gemini] Reply: $reply');
        return reply;
      } else {
        final error = jsonDecode(response.body)['error']['message'];
        print('❌ [Gemini] Error: $error');
        return '❌ Gemini error: $error';
      }
    } catch (e) {
      print('❌ [Gemini] Exception: $e');
      return '❌ Connection error. Check internet and API key.';
    }
  }

  Future<String> _sendToDialogflow({required String userMessage}) async {
    try {
      print('🤖 [Dialogflow] Sending: "$userMessage"');

      final response = await http.post(
        Uri.parse(_dfUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'queryInput': {
            'text': {'text': userMessage, 'languageCode': 'en'},
          },
        }),
      );

      print('📡 [Dialogflow] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['queryResult']['fulfillmentText'];
        final intent = data['queryResult']['intent']['displayName'];
        print('✅ [Dialogflow] Intent: $intent | Reply: $reply');
        return reply?.isNotEmpty == true
            ? reply
            : 'I am not sure about that. Can you ask about our menu, moods, or allergies?';
      } else {
        final error = jsonDecode(response.body)['error']['message'];
        print('❌ [Dialogflow] Error: $error');
        return '❌ Dialogflow error: $error';
      }
    } catch (e) {
      print('❌ [Dialogflow] Exception: $e');
      return '❌ Connection error. Check internet and Project ID.';
    }
  }
}