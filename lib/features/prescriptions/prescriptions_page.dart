import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/models.dart';
import '../../core/repositories/medication_repository.dart';
import '../../core/providers.dart';
import '../../widgets/glass_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
          opacity: 0.1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active
                    ? FontAwesomeIcons.pills
                    : FontAwesomeIcons.clockRotateLeft,
                size: 48,
                color: AppColors.primaryBrand.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                active ? 'No active medications' : 'No past medications',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                active
                    ? 'Your current prescriptions will appear here.'
                    : 'Your medication history will be archived here.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final m = filtered[index];

        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16.0),
          opacity: 0.1,
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryBrand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${m.dosage} • ${m.frequency}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateRange(m),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                      ),
                    ),
                    if (m.schedules != null && m.schedules!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.alarm,
                            size: 12,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${m.schedules!.length} reminders',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
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
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      active ? 'Active' : 'Past',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: active ? AppColors.success : AppColors.secondary,
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
                          size: 18,
                          color: AppColors.secondary,
                        ),
                        tooltip: 'Edit',
                        onPressed: () => _editPrescription(m),
                      ),
                      if (active)
                        IconButton(
                          icon: const Icon(
                            Icons.archive_outlined,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                          tooltip: 'Move to Past',
                          onPressed: () => _moveToPast(m),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
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
            color: AppColors.primaryBrand.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            FontAwesomeIcons.pills,
            size: 24,
            color: AppColors.primaryBrand,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const Text(
              'Manage your clinical prescriptions',
              style: TextStyle(color: AppColors.secondary, fontSize: 14),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Medication'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBrand,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          onPressed: _addPrescription,
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: GlassCard(
        padding: const EdgeInsets.all(6),
        opacity: 0.12,
        child: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          labelColor: AppColors.primaryBrand,
          unselectedLabelColor: AppColors.secondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
          tabs: [
            Tab(
              text:
                  'Active (${_medications.where((m) => _isActive(m)).length})',
            ),
            Tab(
              text: 'Past (${_medications.where((m) => !_isActive(m)).length})',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
        opacity: 0.1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primaryBrand.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBrand.withValues(alpha: 0.1),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Hero(
                tag: 'empty_meds_icon',
                child: Icon(
                  FontAwesomeIcons.kitMedical,
                  size: 64,
                  color: AppColors.primaryBrand,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No active medications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: AppColors.primaryBrand,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Keep track of your dosages and schedules.\nAdd your first medication to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 20),
              label: const Text("Securely Add Medication"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrand,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _addPrescription,
            ),
          ],
        ),
      ),
    );
  }
}
