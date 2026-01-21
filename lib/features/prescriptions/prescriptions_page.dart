import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/notification_service.dart';
import '../../core/providers/user_providers.dart';
import '../../core/providers.dart';

class PrescriptionsPage extends ConsumerStatefulWidget {
  const PrescriptionsPage({super.key});

  @override
  ConsumerState<PrescriptionsPage> createState() => _PrescriptionsPageState();
}

class _PrescriptionsPageState extends ConsumerState<PrescriptionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _prescriptions = [];

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
      builder: (context) => const _AddPrescriptionDialog(),
    );

    if (result == true) {
      ref.invalidate(prescriptionsProvider);
      ref.invalidate(activePrescriptionsCountProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prescriptionsAsync = ref.watch(prescriptionsProvider);

    return prescriptionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (prescriptions) {
        _prescriptions = prescriptions;
        
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
              if (prescriptions.isEmpty)
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

  Future<void> _togglePrescriptionStatus(String id, bool isActive) async {
    try {
      await ref.read(userRepositoryProvider).updatePrescription(id, {'is_active': !isActive});
      ref.invalidate(prescriptionsProvider);
      ref.invalidate(activePrescriptionsCountProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _editPrescription(Map<String, dynamic> prescription) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AddPrescriptionDialog(prescription: prescription),
    );

    if (result == true) {
      ref.invalidate(prescriptionsProvider);
      ref.invalidate(activePrescriptionsCountProvider);
    }
  }

  Future<void> _deletePrescription(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prescription'),
        content: const Text('Are you sure you want to delete this prescription? This action cannot be undone.'),
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
        await ref.read(userRepositoryProvider).deletePrescription(id);
        ref.invalidate(prescriptionsProvider);
        ref.invalidate(activePrescriptionsCountProvider);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prescription deleted')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildPrescriptionList(bool active) {
    final filtered = _prescriptions.where((p) => (p['is_active'] ?? true) == active).toList();
    if (filtered.isEmpty) {
      return Center(child: Text(active ? 'No active prescriptions' : 'No past prescriptions'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final p = filtered[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border)
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                 Container(
                  height: 48, width: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    image: p['image_url'] != null ? DecorationImage(image: NetworkImage(p['image_url']), fit: BoxFit.cover) : null, 
                  ),
                  child: p['image_url'] == null 
                    ? Icon(Icons.medication_outlined, color: Theme.of(context).primaryColor, size: 24)
                    : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${p['dosage'] ?? ''} • ${p['frequency'] ?? ''}', style: const TextStyle(color: AppColors.secondary, fontSize: 14)),
                      if (p['start_date'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${p['start_date']} ${p['end_date'] != null ? '- ${p['end_date']}' : ''}', 
                          style: const TextStyle(fontSize: 12, color: AppColors.secondary)
                        ),
                      ],
                      if (p['reminder_time'] != null) ...[
                         const SizedBox(height: 4),
                         Row(
                           children: [
                             const Icon(Icons.alarm, size: 12, color: AppColors.secondary),
                             const SizedBox(width: 4),
                             Text(p['reminder_time'], style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
                           ],
                         ),
                      ]
                    ],
                  ),
                ),
                
                 Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: active ? AppColors.success.withValues(alpha: 0.1) : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          active ? 'Active' : 'Past',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: active ? AppColors.success : AppColors.secondary),
                        ),
                      ),
                       const SizedBox(height: 8),
                       Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           IconButton(
                             icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.secondary),
                             tooltip: 'Edit',
                             onPressed: () => _editPrescription(p),
                           ),
                           if (active)
                             IconButton(
                               icon: const Icon(Icons.archive_outlined, size: 20, color: AppColors.secondary),
                               tooltip: 'Move to Past',
                               onPressed: () => _togglePrescriptionStatus(p['id'].toString(), true),
                             ),
                           IconButton(
                             icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                             tooltip: 'Delete',
                             onPressed: () => _deletePrescription(p['id'].toString()),
                           ),
                         ],
                       )
                    ],
                 )
              ],
            ),
          ),
        );
      },
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
          child: const Icon(Icons.medication_outlined, size: 24, color: AppColors.secondary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prescriptions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Manage your medications',
              style: TextStyle(color: AppColors.secondary, fontSize: 14),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Prescription'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _addPrescription,
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: AppColors.secondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: [
          Tab(text: 'Active (${_prescriptions.where((p) => (p['is_active'] ?? true) == true).length})'),
          Tab(text: 'Past (${_prescriptions.where((p) => (p['is_active'] ?? true) == false).length})'),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medical_services_outlined, size: 48, color: AppColors.border),
            ),
            const SizedBox(height: 24),
            const Text('No active prescriptions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Add your current medications to keep track of them.', style: TextStyle(color: AppColors.secondary, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Prescription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _addPrescription,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPrescriptionDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? prescription;
  const _AddPrescriptionDialog({this.prescription});

  @override
  ConsumerState<_AddPrescriptionDialog> createState() => _AddPrescriptionDialogState();
}

class _AddPrescriptionDialogState extends ConsumerState<_AddPrescriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;
  bool _remindMe = true;
  bool _isUploadingPhoto = false;
  String? _prescriptionImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.prescription != null) {
      final p = widget.prescription!;
      _nameController.text = p['name'] ?? '';
      _dosageController.text = p['dosage'] ?? '';
      _frequencyController.text = p['frequency'] ?? '';
      if (p['start_date'] != null) _startDate = DateTime.parse(p['start_date']);
      if (p['end_date'] != null) _endDate = DateTime.parse(p['end_date']);
      
      if (p['reminder_time'] != null) {
        _remindMe = true;
        final parts = p['reminder_time'].split(':');
        _reminderTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } else {
        _remindMe = false;
      }
      _prescriptionImageUrl = p['image_url'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await image.readAsBytes();
      final url = await ref.read(storageServiceProvider).uploadPrescriptionImage(bytes);
      if (url != null) {
        setState(() => _prescriptionImageUrl = url);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userRepo = ref.read(userRepositoryProvider);
        final data = {
          'name': _nameController.text,
          'dosage': _dosageController.text,
          'frequency': _frequencyController.text,
          'start_date': _startDate.toIso8601String().split('T')[0],
          'end_date': _endDate?.toIso8601String().split('T')[0],
          'reminder_time': _remindMe ? '${_reminderTime.hour}:${_reminderTime.minute}' : null,
          'image_url': _prescriptionImageUrl,
           // Keep existing status if editing, enable if new
          'is_active': widget.prescription != null ? (widget.prescription!['is_active'] ?? true) : true, 
        };

        if (widget.prescription != null) {
          await userRepo.updatePrescription(widget.prescription!['id'].toString(), data);
        } else {
          await userRepo.addPrescription(data);
        }

        if (_remindMe) {
          // Re-schedule reminder (simple logic: cancel old by id? Implementation details vary, 
          // but scheduling overwrites if ID matches in many plug-ins. Here we just schedule new/update)
          final id = _nameController.text.hashCode;
          await NotificationService().scheduleMedicationReminder(
            id: id,
            name: _nameController.text,
            dosage: _dosageController.text,
          );
        }

        if (mounted) {
           Navigator.pop(context, true);
        }
      } catch (e) {
        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.prescription != null ? 'Edit Prescription' : 'Add Prescription'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo Upload Section
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _uploadPhoto,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    image: _prescriptionImageUrl != null 
                        ? DecorationImage(image: NetworkImage(_prescriptionImageUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _isUploadingPhoto 
                      ? const Center(child: CircularProgressIndicator())
                      : _prescriptionImageUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.camera_alt_outlined, size: 32, color: AppColors.secondary),
                                SizedBox(height: 8),
                                Text('Add Photo', style: TextStyle(color: AppColors.secondary)),
                              ],
                            )
                          : null,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medication Name', hintText: 'e.g. Lisinopril'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(labelText: 'Dosage', hintText: 'e.g. 10mg'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _frequencyController,
                      decoration: const InputDecoration(labelText: 'Frequency', hintText: 'e.g. Daily'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Dates
              Row(
                children: [
                   Expanded(
                    child: InkWell(
                      onTap: () async {
                         final picked = await showDatePicker(
                          context: context, 
                          initialDate: _startDate, 
                          firstDate: DateTime(2000), 
                          lastDate: DateTime(2100)
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Start Date'),
                        child: Text(_startDate.toIso8601String().split('T')[0]),
                      ),
                    ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                    child: InkWell(
                      onTap: () async {
                         final picked = await showDatePicker(
                          context: context, 
                          initialDate: _endDate ?? _startDate.add(const Duration(days: 30)), 
                          firstDate: _startDate, 
                          lastDate: DateTime(2100)
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'End Date (Optional)'),
                        child: Text(_endDate != null ? _endDate!.toIso8601String().split('T')[0] : 'None'),
                      ),
                    ),
                   ),
                ],
              ),
              const SizedBox(height: 16),

              // Reminders
              SwitchListTile(
                title: const Text('Remind Me', style: TextStyle(fontSize: 14)),
                subtitle: Text(_remindMe ? 'Daily at ${_reminderTime.format(context)}' : 'No reminders'),
                value: _remindMe,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _remindMe = v),
              ),
              if (_remindMe)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(context: context, initialTime: _reminderTime);
                      if (picked != null) setState(() => _reminderTime = picked);
                    },
                    child: const Text('Set Reminder Time'),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
        ),
      ],
    );
  }
}
