import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/providers/user_providers.dart';
import '../../core/providers.dart';

class ConditionsPage extends ConsumerStatefulWidget {
  const ConditionsPage({super.key});

  @override
  ConsumerState<ConditionsPage> createState() => _ConditionsPageState();
}

class _ConditionsPageState extends ConsumerState<ConditionsPage> {
  final List<String> _quickAdds = [
    'Diabetes (Type 1)',
    'Diabetes (Type 2)',
    'Thyroid disorder',
    'Hypothyroidism',
    'Hyperthyroidism',
    'Hypertension',
    'High cholesterol',
  ];

  final List<String> _conditions = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchConditions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchConditions() async {
    setState(() => _isLoading = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final profile = await userRepo.getProfile();
      if (profile != null && profile['conditions'] != null) {
        setState(() {
          _conditions.addAll(List<String>.from(profile['conditions']));
        });
      }
    } catch (e) {
      debugPrint('Error fetching conditions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConditions() async {
    setState(() => _isLoading = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.saveConditions(_conditions);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conditions saved successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error saving conditions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving conditions: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addCondition(String condition) {
    if (condition.isNotEmpty && !_conditions.contains(condition)) {
      setState(() {
        _conditions.add(condition);
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildConditionsCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.favorite_border, size: 24, color: Theme.of(context).colorScheme.secondary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Known Conditions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Manually track conditions for Krishna Modi.',
              style: TextStyle(color: AppColors.secondary, fontSize: 14),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _saveConditions,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary.withValues(alpha: 0.5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildConditionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add a condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'e.g., Diabetes (Type 2)',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  onSubmitted: _addCondition,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _addCondition(_controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).cardColor,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('+ Add'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Quick add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAdds.map((item) => _buildChip(item)).toList(),
          ),
          const SizedBox(height: 32),
          const Text('Current list', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          if (_conditions.isEmpty)
            Text(
              'No conditions added yet.',
              style: TextStyle(color: AppColors.secondary, fontSize: 14),
            )
          else
            ..._conditions.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                      const SizedBox(width: 12),
                      Text(item, style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                        onPressed: () => setState(() => _conditions.remove(item)),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 24),
          Text(
            'This is a manual list for your records. It does not diagnose or replace medical advice.',
            style: TextStyle(color: AppColors.secondary, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _addCondition(label),
      backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      labelStyle: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    );
  }
}
