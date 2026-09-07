import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/service_item.dart';
import '../screens/service_detail_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? serviceId;
  final String? serviceName;
  final String? category;
  final String? priceFormatted;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.serviceId,
    this.serviceName,
    this.category,
    this.priceFormatted,
  });
}

class AiAssistantSheet extends StatefulWidget {
  final List<ServiceItem> availableServices;

  const AiAssistantSheet({
    super.key,
    required this.availableServices,
  });

  static void show(BuildContext context, List<ServiceItem> services) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiAssistantSheet(availableServices: services),
    );
  }

  @override
  State<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<AiAssistantSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  static const String _geminiApiKey = 'AQ.Ab8RN6K65CXmhqF1DXLpCEm1u7QBxj4BEMof2TQ2WqxgaQZ8yQ';
  static const String _geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';

  static const Map<String, Map<String, String>> _servicesCatalog = {
    'plumber': {
      'service_id': 'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
      'service_name': 'Plumbing Inspection & Repair',
      'category': 'Plumber',
      'price_formatted': '₹399'
    },
    'electrician': {
      'service_id': 'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44',
      'service_name': 'Electrician Home Service',
      'category': 'Electrician',
      'price_formatted': '₹299'
    },
    'appliance': {
      'service_id': 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
      'service_name': 'AC Service & Repair',
      'category': 'Appliance',
      'price_formatted': '₹599'
    },
    'cleaning': {
      'service_id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      'service_name': 'Home Deep Cleaning',
      'category': 'Cleaning',
      'price_formatted': '₹1,499'
    },
    'pest_control': {
      'service_id': 'e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a55',
      'service_name': 'Pest Control Treatment',
      'category': 'Pest Control',
      'price_formatted': '₹899'
    }
  };

  static const String _systemPrompt = """You are Sahayak AI (सहायक AI), the intelligent, helpful, and empathetic AI assistant for the Sahayak Worker Cooperative Platform.
Sahayak connects urban household customers with certified labour cooperative workers without high corporate middleman commissions.

YOUR INSTRUCTIONS:
1. Converse naturally, intelligently, and warmly. Answer any question the user asks (you can chat about anything, explain how cooperatives empower workers, how fair pricing works, general home maintenance tips, etc.).
2. You can understand and respond in English, Hindi, or Hinglish.
3. If the user describes ANY repair, appliance issue, leak, electrical problem, or cleaning requirement, empathize with them, give useful diagnostic advice, and recommend one of our exact service categories:
   - "plumber" (pipe leaks, tap/faucet issues, drainage blocks, toilet/flush repair)
   - "electrician" (short circuit, sparking switchboard, wiring, fan repair, MCB trip)
   - "appliance" (AC cooling problems, gas refill, foam jet servicing)
   - "cleaning" (deep home cleaning, kitchen scrubbing, bathroom sanitization)
   - "pest_control" (cockroaches, termites, bed bugs, ants)
   - "none" (if the user is chatting, greeting, asking general questions, or issues outside our current catalog)

RESPONSE FORMAT:
You MUST format your reply strictly as valid JSON matching this schema:
{
  "reply": "Your conversational answer to the user",
  "category": "plumber" | "electrician" | "appliance" | "cleaning" | "pest_control" | "none"
}
Do NOT include markdown backticks or any other text. Output raw JSON only.
""";

  final List<String> _quickPrompts = [
    'My kitchen pipe is leaking water',
    'AC is not blowing cold air',
    'Switchboard is sparking',
    'Need deep house cleaning',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: 'Namaste! I am Sahayak AI. Tell me what problem you are facing at home, or ask me anything about our cooperative services.',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String userText) async {
    final query = userText.trim();
    if (query.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(text: query, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Build full conversation history for Gemini
      final List<Map<String, dynamic>> contents = [];
      for (int i = 1; i < _messages.length; i++) {
        final m = _messages[i];
        contents.add({
          'role': m.isUser ? 'user' : 'model',
          'parts': [{'text': m.text}],
        });
      }

      final payload = jsonEncode({
        'system_instruction': {
          'parts': [{'text': _systemPrompt}]
        },
        'contents': contents,
        'generationConfig': {
          'response_mime_type': 'application/json',
          'temperature': 0.4,
        }
      });

      final response = await http.post(
        Uri.parse(_geminiUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _geminiApiKey,
        },
        body: payload,
      );

      debugPrint('[AI Gemini] HTTP status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> geminiData = jsonDecode(response.body);
        final String rawText = geminiData['candidates'][0]['content']['parts'][0]['text'];
        final Map<String, dynamic> parsed = jsonDecode(rawText);

        final String reply = parsed['reply'] ?? 'I am here to help you with cooperative services.';
        final String category = (parsed['category'] as String? ?? 'none').toLowerCase();
        final srv = _servicesCatalog[category];

        setState(() {
          _messages.add(
            ChatMessage(
              text: reply,
              isUser: false,
              serviceId: srv?['service_id'],
              serviceName: srv?['service_name'],
              category: srv?['category'],
              priceFormatted: srv?['price_formatted'],
            ),
          );
          _isLoading = false;
        });
      } else {
        debugPrint('[AI Gemini] Error: ${response.statusCode} - ${response.body}');
        _handleFallback(query);
      }
    } catch (e) {
      debugPrint('[AI Gemini] Exception: $e');
      _handleFallback(query);
    }
    _scrollToBottom();
  }

  void _handleFallback(String query) {
    final lower = query.toLowerCase();
    String reply = "I am here to help with your home maintenance. How can I assist you?";
    String? srvId;
    String? srvName;
    String? price;
    String? cat;

    if (lower.contains('pipe') || lower.contains('leak') || lower.contains('tap') || lower.contains('drain') || lower.contains('water') || lower.contains('sink')) {
      final s = _servicesCatalog['plumber']!;
      reply = "A leaking pipe needs immediate plumbing attention to prevent damage. Our cooperative plumbers can inspect and repair this right away.";
      srvId = s['service_id'];
      srvName = s['service_name'];
      price = s['price_formatted'];
      cat = s['category'];
    } else if (lower.contains('spark') || lower.contains('switch') || lower.contains('electric') || lower.contains('wire') || lower.contains('mcb')) {
      final s = _servicesCatalog['electrician']!;
      reply = "Electrical sparking is hazardous. A certified cooperative electrician can inspect and repair your wiring safely.";
      srvId = s['service_id'];
      srvName = s['service_name'];
      price = s['price_formatted'];
      cat = s['category'];
    } else if (lower.contains('ac') || lower.contains('cool') || lower.contains('gas')) {
      final s = _servicesCatalog['appliance']!;
      reply = "Your AC likely needs foam jet cleaning and gas pressure check. Here is our certified AC service.";
      srvId = s['service_id'];
      srvName = s['service_name'];
      price = s['price_formatted'];
      cat = s['category'];
    } else if (lower.contains('clean') || lower.contains('dust')) {
      final s = _servicesCatalog['cleaning']!;
      reply = "Our cooperative deep cleaning crew provides comprehensive floor scrubbing, kitchen degreasing, and sanitization.";
      srvId = s['service_id'];
      srvName = s['service_name'];
      price = s['price_formatted'];
      cat = s['category'];
    }

    setState(() {
      _messages.add(
        ChatMessage(
          text: reply,
          isUser: false,
          serviceId: srvId,
          serviceName: srvName,
          category: cat,
          priceFormatted: price,
        ),
      );
      _isLoading = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openBookingForService(String serviceId, String serviceName) {
    Navigator.of(context).pop();

    ServiceItem target = widget.availableServices.firstWhere(
      (s) => s.serviceId == serviceId || s.name.toLowerCase() == serviceName.toLowerCase(),
      orElse: () => ServiceItem.mockServices.firstWhere(
        (s) => s.serviceId == serviceId || s.name.toLowerCase() == serviceName.toLowerCase(),
        orElse: () => ServiceItem.mockServices.first,
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServiceDetailScreen(service: target),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E7E34).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF1E7E34),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sahayak AI Assistant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Powered by Gemini Flash • Cooperative Diagnostics',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageItem(msg);
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E7E34)),
                  ),
                  SizedBox(width: 10),
                  Text('Sahayak AI is thinking...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),

          // Quick Suggestion Chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  label: Text(prompt, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide.none,
                  onPressed: () => _sendMessage(prompt),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: 'Ask anything or describe your issue...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFF1E7E34), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E7E34),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _sendMessage(_inputController.text),
                  icon: const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Column(
          crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isUser ? const Color(0xFF1E7E34) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: msg.isUser ? const Radius.circular(2) : const Radius.circular(16),
                  bottomLeft: !msg.isUser ? const Radius.circular(2) : const Radius.circular(16),
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: msg.isUser ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),

            if (!msg.isUser && msg.serviceId != null) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _openBookingForService(msg.serviceId!, msg.serviceName ?? 'Service'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E7E34), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E7E34).withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E7E34).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.handshake_rounded,
                          color: Color(0xFF1E7E34),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.serviceName ?? 'Recommended Service',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Standard Price: ${msg.priceFormatted ?? "₹399"}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1E7E34),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF1E7E34)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
