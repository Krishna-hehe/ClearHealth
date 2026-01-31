import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';

class RecipesPage extends ConsumerStatefulWidget {
  const RecipesPage({super.key});

  @override
  ConsumerState<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends ConsumerState<RecipesPage> {
  String _filter = 'All'; // 'All', 'Veg', 'Non-Veg'

  List<String> _parseIngredients(dynamic input) {
    if (input == null) return [];
    if (input is List) return input.map((e) => e.toString()).toList();
    if (input is Map) return input.values.map((e) => e.toString()).toList();
    if (input is String) return [input.toString()];
    return [];
  }

  String _safeString(dynamic input, [String fallback = '']) {
    if (input == null) return fallback;
    if (input is String) return input;
    return input.toString();
  }

  @override
  Widget build(BuildContext context) {
    final optimizationAsync = ref.watch(optimizationTipsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Health Optimization',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              _buildFilterChips(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Personalized nutritional recipes and lifestyle tips based on your latest lab results.',
            style: TextStyle(color: AppColors.secondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          optimizationAsync.when(
            data: (tips) {
              if (tips.isEmpty) {
                return _buildEmptyState();
              }

              final filteredTips = _filter == 'All'
                  ? tips
                  : tips.where((t) => (t['type'] ?? 'Veg') == _filter).toList();

              if (filteredTips.isEmpty) {
                return SizedBox(
                  height: 300,
                  child: Center(
                    child: Text(
                      'No $_filter recommendations found.',
                      style: const TextStyle(color: AppColors.secondary),
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 450,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  mainAxisExtent: 500, // Increased height to prevent overflow
                ),
                itemCount: filteredTips.length,
                itemBuilder: (context, index) =>
                    _buildRecipeCard(context, filteredTips[index]),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) =>
                Center(child: Text('Error generating optimization tips: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [_buildChip('All'), _buildChip('Veg'), _buildChip('Non-Veg')],
      ),
    );
  }

  Widget _buildChip(String label) {
    bool isSelected = _filter == label;
    return InkWell(
      onTap: () => setState(() => _filter = label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.secondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.success.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'All your lab values are looking great!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'No specific deficiencies detected in your latest report.',
            style: TextStyle(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Map<String, dynamic> tip) {
    final ingredients = _parseIngredients(tip['ingredients']);
    final type = _safeString(tip['type'], 'Veg');
    final isVeg = type == 'Veg';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isVeg
                    ? [Colors.green.shade400, Colors.green.shade700]
                    : [Colors.orange.shade400, Colors.deepOrange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _safeString(tip['metric_targeted'], 'General'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: isVeg ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _safeString(tip['title'], 'Optimization Tip'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _safeString(tip['description']),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (ingredients.isNotEmpty) ...[
                    const Text(
                      'Key Ingredients:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ingredients
                          .take(3)
                          .map(
                            (item) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.replaceAll(
                                  RegExp(r'^\[|\]$'),
                                  '',
                                ), // Clean brackets
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const Spacer(),
                  const Divider(),
                  Row(
                    children: [
                      Icon(
                        Icons.flash_on,
                        size: 14,
                        color: isVeg ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _safeString(tip['benefit']),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isVeg ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showRecipeDetails(context, tip),
                        child: const Text('View Recipe'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecipeDetails(BuildContext context, Map<String, dynamic> tip) {
    final type = _safeString(tip['type'], 'Veg');
    final isVeg = type == 'Veg';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.restaurant_menu,
              color: isVeg ? Colors.green : Colors.deepOrange,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(_safeString(tip['title'], 'Recipe Details'))),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isVeg
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isVeg
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isVeg ? Colors.green : Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _safeString(tip['description']),
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Ingredients',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ..._parseIngredients(tip['ingredients']).map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fiber_manual_record,
                          size: 8,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(item),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Instructions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  _safeString(tip['instructions']),
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
