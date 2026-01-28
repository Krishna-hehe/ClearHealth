import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models.dart';
import '../../core/repositories/medication_repository.dart';
import '../../core/theme.dart';
import '../../core/notification_service.dart';
import '../../core/providers.dart';
import 'package:uuid/uuid.dart' as uuid;

final medicationsProvider = FutureProvider.family<List<Medication>, String?>((
  ref,
  profileId,
) async {
  final repo = ref.watch(medicationRepositoryProvider);
  return repo.getMedications(profileId: profileId);
});

class MedicationsPage extends ConsumerStatefulWidget {
  final String? profileId;
  const MedicationsPage({super.key, this.profileId});

  @override
  ConsumerState<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends ConsumerState<MedicationsPage> {
  @override
  Widget build(BuildContext context) {
    final medicationsAsync = ref.watch(medicationsProvider(widget.profileId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: medicationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (medications) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            if (medications.isEmpty)
              Expanded(child: _buildEmptyState(context))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: medications.length,
                  itemBuilder: (context, index) =>
                      _MedicationCard(medication: medications[index]),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMedicationDialog(context),
        label: const Text('Add Medication'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medication Reminders',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Manage your daily medications and schedule alerts.',
          style: TextStyle(fontSize: 16, color: AppColors.lightTextSecondary),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.medication_liquid_outlined,
            size: 80,
            color: AppColors.lightTextSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No medications added yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep track of your meds and never miss a dose.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.lightTextSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMedicationDialog(
    BuildContext context, {
    Medication? medication,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AddMedicationDialog(
        medication: medication,
        profileId: widget.profileId,
      ),
    );

    if (result == true) {
      ref.invalidate(medicationsProvider(widget.profileId));
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              medication == null ? 'Medication added!' : 'Medication updated!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _deleteMedication(Medication medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to remove ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Cancel existing notifications
        await NotificationService().cancelScheduledReminders(medication.id);

        await ref
            .read(medicationRepositoryProvider)
            .deleteMedication(medication.id);
        ref.invalidate(medicationsProvider(widget.profileId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medication deleted'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }
}

class _MedicationCard extends ConsumerWidget {
  final Medication medication;
  const _MedicationCard({required this.medication});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: AppColors.primaryBrand.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication, color: AppColors.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${medication.dosage} • ${medication.frequency}',
                    style: const TextStyle(color: AppColors.lightTextSecondary),
                  ),
                  if (medication.schedules != null &&
                      medication.schedules!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: medication.schedules!
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.accent.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                s.time,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') {
                  final state = context
                      .findAncestorStateOfType<_MedicationsPageState>();
                  state?._showAddMedicationDialog(
                    context,
                    medication: medication,
                  );
                } else if (val == 'delete') {
                  final state = context
                      .findAncestorStateOfType<_MedicationsPageState>();
                  state?._deleteMedication(medication);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMedicationDialog extends ConsumerStatefulWidget {
  final Medication? medication;
  final String? profileId;
  const _AddMedicationDialog({this.medication, this.profileId});

  @override
  ConsumerState<_AddMedicationDialog> createState() =>
      _AddMedicationDialogState();
}

class _AddMedicationDialogState extends ConsumerState<_AddMedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  String _frequency = 'Daily';
  List<TimeOfDay> _reminderTimes = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication?.name);
    _dosageController = TextEditingController(text: widget.medication?.dosage);
    _frequency = widget.medication?.frequency ?? 'Daily';

    if (widget.medication?.schedules != null) {
      _reminderTimes = widget.medication!.schedules!.map((s) {
        final parts = s.time.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();
    } else if (widget.medication == null) {
      _reminderTimes = [const TimeOfDay(hour: 9, minute: 0)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.medication == null ? 'Add Medication' : 'Edit Medication',
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medication Name',
                    hintText: 'e.g. Lisinopril',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: 'e.g. 10mg',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: ['Daily', 'Weekly', 'Monthly', 'As Needed']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _frequency = v!),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Reminder Times',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ..._reminderTimes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final time = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: time,
                              );
                              if (picked != null) {
                                setState(() => _reminderTimes[idx] = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(time.format(context)),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              setState(() => _reminderTimes.removeAt(idx)),
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => setState(
                    () =>
                        _reminderTimes.add(const TimeOfDay(hour: 9, minute: 0)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Time'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(medicationRepositoryProvider);
      final userId = ref.read(authServiceProvider).currentUser?.id ?? '';

      final medication = Medication(
        id: widget.medication?.id ?? const uuid.Uuid().v4(),
        userId: userId,
        profileId: widget.profileId ?? '',
        name: _nameController.text,
        dosage: _dosageController.text,
        frequency: _frequency,
        startDate: DateTime.now(),
        schedules: _reminderTimes
            .map(
              (t) => ReminderSchedule(
                id: const uuid.Uuid().v4(),
                medicationId: '', // Handled by backend/repo
                time:
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                daysOfWeek: [
                  1,
                  2,
                  3,
                  4,
                  5,
                  6,
                  7,
                ], // Default to all days for now
              ),
            )
            .toList(),
      );

      if (widget.medication == null) {
        await repo.createMedication(medication);
      } else {
        // Cancel old reminders first
        await NotificationService().cancelScheduledReminders(medication.id);
        await repo.updateMedication(medication);
      }

      // Schedule notifications
      for (final time in _reminderTimes) {
        await NotificationService().scheduleReminders(
          scheduleId: medication.id.hashCode.toString(),
          title: 'Medication Reminder',
          body:
              'It\'s time to take your ${_dosageController.text} of ${_nameController.text}.',
          hour: time.hour,
          minute: time.minute,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
