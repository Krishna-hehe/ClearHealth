import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../widgets/glass_card.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.text, required this.isUser, required this.timestamp});
}

class HealthChatPage extends ConsumerStatefulWidget {
  const HealthChatPage({super.key});

  @override
  ConsumerState<HealthChatPage> createState() => _HealthChatPageState();
}

class _HealthChatPageState extends ConsumerState<HealthChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _messages.add(
      Message(
        text:
            "Hello! I'm LabSense AI. I can help you understand your lab results and medical history. What would you like to know today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _sendMessage() async {
    var query = _controller.text.trim();
    if (query.isEmpty) return;

    // Phase 2: Input Validation & Sanitization
    final validator = ref.read(inputValidationServiceProvider);
    query = validator.sanitizeInput(query);

    if (query.isEmpty) return; // If sanitization removed everything
    if (query.length > 500) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Message too long. Please shorten your message (max 500 chars).',
          ),
        ),
      );
      return;
    }

    // Phase 3: Rate Limiting
    final rateLimiter = ref.read(rateLimiterProvider);
    final waitDuration = rateLimiter.checkLimit('ask_labsense');
    if (waitDuration != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rate limit exceeded. Please wait ${waitDuration.inSeconds} seconds.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _messages.add(
        Message(text: query, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
      _controller.clear();
    });

    // Gather Context
    final labResults = ref.read(labResultsProvider).value ?? [];
    final prescriptions = ref.read(prescriptionsProvider).value ?? [];
    final selectedProfile = ref.read(selectedProfileProvider).value;
    final conditions = selectedProfile?.conditions ?? [];

    // Filter Abnormal Labs
    final abnormalLabs = <Map<String, dynamic>>[];
    for (var report in labResults) {
      if (report.testResults != null) {
        for (var test in report.testResults!) {
          if (test.status.toLowerCase() == 'high' ||
              test.status.toLowerCase() == 'low') {
            abnormalLabs.add({
              'test_name': test.name,
              'value': test.result,
              'unit': test.unit,
              'status': test.status,
              'reference_range': test.reference,
              'loinc': test.loinc,
              'date': report.date.toIso8601String().split('T')[0],
            });
          }
        }
      }
    }

    // Filter Active Prescriptions
    final activePrescriptions = prescriptions
        .where((p) => p['is_active'] == true)
        .map(
          (p) => {
            'medication': p['medication_name'],
            'dosage': p['dosage'],
            'frequency': p['frequency'],
          },
        )
        .toList();

    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.chat(
        query,
        healthContext: {
          'abnormal_labs': abnormalLabs,
          'active_prescriptions': activePrescriptions,
          'known_conditions': conditions,
        },
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          Message(text: response, isUser: false, timestamp: DateTime.now()),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          Message(
            text: "I'm sorry, I encountered an error: $e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: GlassCard(
            margin: const EdgeInsets.symmetric(vertical: 24),
            padding: const EdgeInsets.all(24),
            opacity: 0.05,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessageBubble(_messages[index]),
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(height: 16),
                _buildSuggestions(),
                const SizedBox(height: 12),
                _buildInputArea(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    final labResults = ref.watch(labResultsProvider).value ?? [];
    final prescriptions = ref.watch(prescriptionsProvider).value ?? [];

    final suggestions = <String>{
      "How can I improve my immunity?",
      "Explain my latest lab report",
      "What foods should I avoid?",
    };

    // Add context-aware suggestions
    for (var report in labResults) {
      if (report.testResults != null) {
        for (var test in report.testResults!) {
          if (test.status.toLowerCase() == 'high') {
            suggestions.add("How to lower ${test.name}?");
            suggestions.add("Diet for high ${test.name}");
          } else if (test.status.toLowerCase() == 'low') {
            suggestions.add("How to increase ${test.name}?");
          }
        }
      }
    }

    for (var p in prescriptions) {
      if (p['is_active'] == true) {
        suggestions.add("Side effects of ${p['name']}");
        suggestions.add("Interactions with ${p['name']}");
      }
    }

    final initialList = suggestions.take(5).toList();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: initialList.length,
        separatorBuilder: (c, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(initialList[index]),
            backgroundColor: const Color(0xFFEEF2FF),
            labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
            onPressed: () {
              _controller.text = initialList[index];
              _sendMessage();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.transparent),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(12),
          opacity: 0.1,
          child: const Icon(
            FontAwesomeIcons.robot,
            size: 24,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ask LabSense',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Context-aware AI assistant for your medical data',
              style: TextStyle(color: AppColors.secondary, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Ask about your results, trends, or health history...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onSubmitted: (_) => _sendMessage(),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendMessage,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Icon(Icons.send),
        ),
      ],
    );
  }
}
