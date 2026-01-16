import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/supabase_service.dart';
import '../../core/notification_service.dart';

class PrescriptionsPage extends StatefulWidget {
  const PrescriptionsPage({super.key});

  @override
  State<PrescriptionsPage> createState() => _PrescriptionsPageState();
}

class _PrescriptionsPageState extends State<PrescriptionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _prescriptions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPrescriptions();
  }

  Future<void> _fetchPrescriptions() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService().getPrescriptions();
    setState(() {
      _prescriptions = data;
      _isLoading = false;
    });
  }

  Future<void> _addPrescription() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _AddPrescriptionDialog(),
    );

    if (result == true) {
      _fetchPrescriptions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildTabs(),
        const SizedBox(height: 24),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_prescriptions.isEmpty)
          _buildEmptyState()
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
    );
  }

  Widget _buildPrescriptionList(bool active) {
    final filtered = _prescriptions.where((p) => (p['is_active'] ?? true) == active).toList();
    if (filtered.isEmpty) {
      return Center(child: Text(active ? 'No active prescriptions' : 'No past prescriptions'));
    }
    return ListView.builder(
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.medication_outlined, color: Theme.of(context).primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${p['dosage'] ?? ''} • ${p['frequency'] ?? ''}', style: const TextStyle(color: AppColors.secondary, fontSize: 14)),
                    ],
                  ),
                ),
                
                 Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: active ? AppColors.success.withOpacity(0.1) : Theme.of(context).dividerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          active ? 'Active' : 'Past',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: active ? AppColors.success : AppColors.secondary),
                        ),
                      ),
                       const SizedBox(height: 8),
                       Text('Started ${p['start_date'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
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
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.link, size: 24, color: AppColors.secondary),
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
        color: Theme.of(context).dividerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha((0.05 * 255).toInt()), blurRadius: 4, offset: const Offset(0, 2)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
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
              backgroundColor: const Color(0xFF6B7280),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _addPrescription,
          ),
        ],
      ),
    );
  }
}

class _AddPrescriptionDialog extends StatefulWidget {
  const _AddPrescriptionDialog();

  @override
  State<_AddPrescriptionDialog> createState() => _AddPrescriptionDialogState();
}

class _AddPrescriptionDialogState extends State<_AddPrescriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;
  bool _remindMe = true;

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await SupabaseService().addPrescription({
          'name': _nameController.text,
          'dosage': _dosageController.text,
          'frequency': _frequencyController.text,
          'start_date': _startDate.toIso8601String().split('T')[0],
          'is_active': true, 
        });

        if (_remindMe) {
          // Schedule daily reminder at 9 AM
          // Use a simple hash of the name for the notification ID
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
      title: const Text('Add Prescription'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medication Name', hintText: 'e.g. Lisinopril'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(labelText: 'Dosage', hintText: 'e.g. 10mg'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(labelText: 'Frequency', hintText: 'e.g. Daily'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Start Date'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_startDate.toIso8601String().split('T')[0]),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Remind Me', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Daily reminder at 9:00 AM', style: TextStyle(fontSize: 12)),
                value: _remindMe,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _remindMe = v),
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
