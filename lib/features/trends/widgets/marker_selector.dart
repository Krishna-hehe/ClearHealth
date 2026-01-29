import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';

class MarkerSelector extends ConsumerStatefulWidget {
  final List<String> selectedMarkers;
  final ValueChanged<List<String>> onChanged;

  const MarkerSelector({
    super.key,
    required this.selectedMarkers,
    required this.onChanged,
  });

  @override
  ConsumerState<MarkerSelector> createState() => _MarkerSelectorState();
}

class _MarkerSelectorState extends ConsumerState<MarkerSelector> {
  final List<Map<String, dynamic>> _healthBundles = [
    {
      'name': 'Thyroid Panel',
      'tests': ['TSH', 'Free T4', 'Free T3'],
    },
    {
      'name': 'Bone Health',
      'tests': ['Vitamin D', 'Calcium', 'Phosphorus'],
    },
    {
      'name': 'Kidney Health',
      'tests': ['Creatinine', 'BUN', 'GFR'],
    },
    {
      'name': 'Lipid Profile',
      'tests': ['Total Cholesterol', 'LDL', 'HDL', 'Triglycerides'],
    },
  ];

  void _addMarker(String marker) {
    if (widget.selectedMarkers.contains(marker)) return;
    if (widget.selectedMarkers.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max 3 markers allowed for comparison')),
      );
      return;
    }
    widget.onChanged([...widget.selectedMarkers, marker]);
  }

  void _removeMarker(String marker) {
    widget.onChanged(widget.selectedMarkers.where((m) => m != marker).toList());
  }

  void _applyBundle(List<String> bundle) {
    widget.onChanged(bundle);
  }

  @override
  Widget build(BuildContext context) {
    final availableTests = ref.watch(distinctTestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.selectedMarkers.map(
              (marker) => Chip(
                label: Text(marker),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeMarker(marker),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                labelStyle: const TextStyle(color: AppColors.primary),
                side: BorderSide.none,
              ),
            ),
            if (widget.selectedMarkers.length < 3)
              ActionChip(
                label: const Text('Add Marker'),
                avatar: const Icon(Icons.add, size: 18),
                onPressed: () =>
                    _showAddMarkerDialog(availableTests.value ?? []),
                backgroundColor: Colors.grey[100],
                side: BorderSide(color: Colors.grey[300]!),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Bundles
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _healthBundles.length,
            separatorBuilder: (c, i) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final bundle = _healthBundles[index];
              return ChoiceChip(
                label: Text(bundle['name']),
                selected: false,
                onSelected: (_) =>
                    _applyBundle(bundle['tests'] as List<String>),
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey[300]!),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddMarkerDialog(List<String> options) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Marker'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: options.isEmpty
              ? const Center(child: Text('No test history found'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final marker = options[index];
                    final isSelected = widget.selectedMarkers.contains(marker);
                    return ListTile(
                      title: Text(marker),
                      enabled: !isSelected,
                      onTap: () {
                        _addMarker(marker);
                        Navigator.pop(context);
                      },
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.success)
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
