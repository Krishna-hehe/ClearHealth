import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/models.dart';
import '../../core/repositories/medication_repository.dart';
import '../../core/providers.dart';
import 'edit_medication_page.dart';

class PrescriptionsPage extends ConsumerStatefulWidget {
  const PrescriptionsPage({super.key});

  @override
  ConsumerState<PrescriptionsPage> createState() => _PrescriptionsPageState();
}

class _PrescriptionsPageState extends ConsumerState<PrescriptionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Medication> _medications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addPrescription() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const EditMedicationDialog(),
    );

    if (result == true) {
      ref.invalidate(medicationsProvider);
    }
  }

  Future<void> _editPrescription(Medication medication) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditMedicationDialog(medication: medication),
    );

    if (result == true) {
      ref.invalidate(medicationsProvider);
    }
  }

  Future<void> _deletePrescription(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: const Text(
          'Are you sure you want to delete this medication? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(medicationRepositoryProvider).deleteMedication(id);
        ref.invalidate(medicationsProvider);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Medication deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _moveToPast(Medication medication) async {
    final updated = Medication(
      id: medication.id,
      userId: medication.userId,
      profileId: medication.profileId,
      name: medication.name,
      dosage: medication.dosage,
      frequency: medication.frequency,
      startDate: medication.startDate,
      endDate: DateTime.now().subtract(const Duration(days: 1)),
      schedules: medication.schedules,
    );

    try {
      await ref.read(medicationRepositoryProvider).updateMedication(updated);
      ref.invalidate(medicationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moved to past medications')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicationsAsync = ref.watch(medicationsProvider);

    return medicationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (medications) {
        _medications = medications;

        return Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildTabs(),
              const SizedBox(height: 24),
              if (medications.isEmpty)
                Expanded(child: _buildEmptyState())
              else
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPrescriptionList(true),
                      _buildPrescriptionList(false),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isActive(Medication m) {
    final now = DateTime.now();
    if (m.endDate == null) return true;
    return m.endDate!.isAfter(now.subtract(const Duration(days: 1)));
  }

  Widget _buildPrescriptionList(bool active) {
    final filtered = _medications.where((m) => _isActive(m) == active).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          active ? 'No active medications' : 'No past medications',
          style: const TextStyle(color: AppColors.lightTextSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final m = filtered[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.lightBorder),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    image: m.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(m.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: m.imageUrl == null
                      ? const Icon(
                          Icons.medication_outlined,
                          color: AppColors.primaryBrand,
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${m.dosage} • ${m.frequency}',
                        style: const TextStyle(
                          color: AppColors.lightTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateRange(m),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                      if (m.schedules != null && m.schedules!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.alarm,
                              size: 12,
                              color: AppColors.lightTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${m.schedules!.length} reminders',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.lightTextSecondary.withValues(
                                alpha: 0.1,
                              ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        active ? 'Active' : 'Past',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: active
                              ? AppColors.success
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: AppColors.lightTextSecondary,
                          ),
                          tooltip: 'Edit',
                          onPressed: () => _editPrescription(m),
                        ),
                        if (active)
                          IconButton(
                            icon: const Icon(
                              Icons.archive_outlined,
                              size: 20,
                              color: AppColors.lightTextSecondary,
                            ),
                            tooltip: 'Move to Past',
                            onPressed: () => _moveToPast(m),
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppColors.danger,
                          ),
                          tooltip: 'Delete',
                          onPressed: () => _deletePrescription(m.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateRange(Medication m) {
    final start = m.startDate.toIso8601String().split('T')[0];
    final end = m.endDate?.toIso8601String().split('T')[0] ?? 'Ongoing';
    return '$start - $end';
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightTextSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.medication_outlined,
            size: 24,
            color: AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Medications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.lightTextPrimary,
              ),
            ),
            Text(
              'Manage your prescriptions',
              style: TextStyle(
                color: AppColors.lightTextSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Medication'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBrand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _addPrescription,
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightTextSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: AppColors.primaryBrand,
        unselectedLabelColor: AppColors.lightTextSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: [
          Tab(
            text: 'Active (${_medications.where((m) => _isActive(m)).length})',
          ),
          Tab(
            text: 'Past (${_medications.where((m) => !_isActive(m)).length})',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 80),
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightTextSecondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                size: 48,
                color: AppColors.lightBorder,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No active medications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your current medications to keep track of them.',
              style: TextStyle(
                color: AppColors.lightTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Medication'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _addPrescription,
            ),
          ],
        ),
      ),
    );
  }
}
