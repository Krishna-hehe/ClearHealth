import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/repositories/medication_repository.dart';
import '../../core/notification_service.dart';
import '../../core/providers.dart';
import 'package:image_picker/image_picker.dart';

class EditMedicationDialog extends ConsumerStatefulWidget {
  final Medication? medication;

  const EditMedicationDialog({super.key, this.medication});

  @override
  ConsumerState<EditMedicationDialog> createState() =>
      _EditMedicationDialogState();
}

class _EditMedicationDialogState extends ConsumerState<EditMedicationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _frequencyController;
  late DateTime _startDate;
  DateTime? _endDate;

  // Local state for reminders
  List<ReminderSchedule> _reminders = [];
  bool _isLoading = false;

  String? _imageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final m = widget.medication;
    _nameController = TextEditingController(text: m?.name ?? '');
    _dosageController = TextEditingController(text: m?.dosage ?? '');
    _frequencyController = TextEditingController(text: m?.frequency ?? 'Daily');
    _startDate = m?.startDate ?? DateTime.now();
    _endDate = m?.endDate;
    _imageUrl = m?.imageUrl;

    if (m?.schedules != null) {
      _reminders = List.from(m!.schedules!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isUploadingImage = true);
      try {
        final bytes = await image.readAsBytes();
        final url = await ref
            .read(storageServiceProvider)
            .uploadPrescriptionImage(bytes);
        if (url != null) {
          setState(() => _imageUrl = url);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isUploadingImage = false);
        }
      }
    }
  }

  Future<void> _addReminder() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _reminders.add(
          ReminderSchedule(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            medicationId: widget.medication?.id ?? '',
            time:
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
            daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          ),
        );
      });
    }
  }

  void _removeReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profile = ref.read(selectedProfileProvider).value;

      if (profile == null) {
        throw Exception("No profile selected");
      }

      final newMedication = Medication(
        id: widget.medication?.id ?? '',
        userId: profile.userId,
        profileId: profile.id,
        name: _nameController.text,
        dosage: _dosageController.text,
        frequency: _frequencyController.text,
        startDate: _startDate,
        endDate: _endDate,
        schedules: _reminders,
        imageUrl: _imageUrl,
      );

      final repo = ref.read(medicationRepositoryProvider);

      if (widget.medication == null) {
        await repo.createMedication(newMedication);
      } else {
        await repo.updateMedication(newMedication);
      }

      // Schedule Notifications
      for (var schedule in _reminders) {
        final timeParts = schedule.time.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        final notifId = '${newMedication.name}_${schedule.time}'.hashCode
            .toString();

        await NotificationService().scheduleReminders(
          scheduleId: notifId,
          title: 'Time for ${newMedication.name}',
          body: 'Take ${newMedication.dosage}',
          hour: hour,
          minute: minute,
          daysOfWeek: schedule.daysOfWeek,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.medication == null
                    ? 'Add Medication'
                    : 'Edit Medication',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),

              // Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!),
                      image: _imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _isUploadingImage
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _imageUrl == null
                        ? const Icon(Icons.add_a_photo, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_imageUrl == null)
                const Text(
                  'Add Photo',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),

              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        labelText: 'Medication Name',
                        labelStyle: TextStyle(color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dosageController,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        labelStyle: TextStyle(color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _frequencyController.text.isNotEmpty
                          ? _frequencyController.text
                          : 'Daily',
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        labelStyle: TextStyle(color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      items: ['Daily', '2x Daily', 'Weekly', 'As Needed']
                          .map(
                            (f) => DropdownMenuItem(value: f, child: Text(f)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _frequencyController.text = val);
                        }
                      },
                    ),
                    // Hidden Start/End date pickers for now as they weren't in mockup
                    // Or we can keep them collapsed or simplified. Mockup didn't show them,
                    // but logic needs them. I'll keep them but styling minimal or assume simple defaults.
                    // Ideally we should show them, maybe below frequency.
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) setState(() => _startDate = d);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ), // Match others? Or keep simple
                                isDense: true,
                              ),
                              child: Text(
                                _startDate.toIso8601String().split('T')[0],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Reminder Times',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),

              if (_reminders.isNotEmpty)
                ..._reminders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final reminder = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          reminder
                              .time, // format this? It is HH:mm string from provider
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF334155),
                          ),
                        ),
                        InkWell(
                          onTap: () => _removeReminder(index),
                          child: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.deepOrange,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              // Add Time Button
              Center(
                child: TextButton.icon(
                  onPressed: _addReminder,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Time'),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B), // Dark Slate
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
