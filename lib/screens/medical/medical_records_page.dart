import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/medical_models.dart';
import '../../services/auth_service.dart';
import '../../services/doctor_service.dart';
import '../../services/medical_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

// icon w lon le kol no3 record
(IconData, Color) recordStyle(String type) => switch (type) {
      'Prescriptions' => (Icons.description_rounded, AppColors.primary),
      'Lab Reports' => (Icons.science_rounded, const Color(0xFF7C8CF8)),
      'X-Ray Reports' => (Icons.monitor_rounded, const Color(0xFF3D6FA8)),
      'Vaccinations' => (Icons.vaccines_rounded, AppColors.success),
      _ => (Icons.favorite_rounded, AppColors.error),
    };

// da el Medical Records screen (zay el sora: categories + Add New Record)
class MedicalRecordsPage extends StatefulWidget {
  const MedicalRecordsPage({super.key});

  @override
  State<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  late Future<List<MedicalRecordModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = MedicalService.getRecords();
  }

  void _reload() => setState(() => _future = MedicalService.getRecords());

  Future<void> _openAddSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AddRecordSheet(),
    );
    if (added == true) {
      _reload();
      if (mounted) showSnack(context, 'Record saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.profile.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Medical Records')),
      body: AsyncView<List<MedicalRecordModel>>(
        future: _future,
        onRetry: _reload,
        builder: (records) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            AppCard(
              child: Row(
                children: [
                  InitialsAvatar(name: user?.fullName ?? '', radius: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('${records.length} records',
                            style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // category tiles
            for (final type in MedicalRecordModel.types) ...[
              _categoryTile(type, records.where((r) => r.recordType == type).toList()),
              const SizedBox(height: 10),
            ],
            // el roshetat elly el doctors katbha (men table prescriptions)
            const SizedBox(height: 4),
            AppCard(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const DoctorPrescriptionsPage())),
              child: const Row(
                children: [
                  IconTile(icon: Icons.medication_liquid_rounded, color: Color(0xFFF08A5D)),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text('Prescriptions from my doctors',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openAddSheet,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Add New Record'),
          ),
        ),
      ),
    );
  }

  Widget _categoryTile(String type, List<MedicalRecordModel> list) {
    final (icon, color) = recordStyle(type);
    return AppCard(
      onTap: () async {
        await Navigator.push(
            context, MaterialPageRoute(builder: (_) => RecordsListPage(type: type, records: list)));
        _reload();
      },
      child: Row(
        children: [
          IconTile(icon: icon, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  list.isEmpty ? 'No records yet' : 'Updated ${formatDate(list.first.createdAt)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Text('${list.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

// list el records men no3 wa7ed: view + delete
class RecordsListPage extends StatefulWidget {
  final String type;
  final List<MedicalRecordModel> records;
  const RecordsListPage({super.key, required this.type, required this.records});

  @override
  State<RecordsListPage> createState() => _RecordsListPageState();
}

class _RecordsListPageState extends State<RecordsListPage> {
  late final List<MedicalRecordModel> _records = [...widget.records];

  // bnfta7 el file b signed URL (el bucket private)
  Future<void> _view(MedicalRecordModel r) async {
    try {
      final url = await MedicalService.getFileUrl(r.filePath!);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  Future<void> _delete(MedicalRecordModel r) async {
    if (!await confirmDialog(context, 'Delete record', 'Delete "${r.title}"?')) return;
    try {
      await MedicalService.deleteRecord(r);
      setState(() => _records.remove(r));
      if (mounted) showSnack(context, 'Record deleted');
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = recordStyle(widget.type);
    return Scaffold(
      appBar: AppBar(title: Text(widget.type)),
      body: _records.isEmpty
          ? EmptyView(message: 'No ${widget.type.toLowerCase()} yet', icon: icon)
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final r = _records[i];
                return AppCard(
                  child: Row(
                    children: [
                      IconTile(icon: icon, color: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (r.description.isNotEmpty)
                              Text(r.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            Text(formatDate(r.createdAt),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (r.filePath != null)
                        IconButton(
                          tooltip: 'View file',
                          onPressed: () => _view(r),
                          icon: const Icon(Icons.visibility_rounded, color: AppColors.primary),
                        ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _delete(r),
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// el form beta3 "Add Record" (title, type, description, file)
class AddRecordSheet extends StatefulWidget {
  const AddRecordSheet({super.key});

  @override
  State<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<AddRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _type = MedicalRecordModel.types.first;
  PlatformFile? _file;
  Uint8List? _fileBytes;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // hena el user by5tar file (PDF / sora) men el gehaz
  Future<void> _pickFile() async {
    try {
      final f = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (f == null) return; // el user 3ml cancel
      final bytes = await f.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        if (mounted) showSnack(context, 'File is too large (max 10 MB)', error: true);
        return;
      }
      setState(() {
        _file = f;
        _fileBytes = bytes;
      });
    } catch (_) {
      if (mounted) showSnack(context, 'Could not open the file', error: true);
    }
  }

  // hena bn-upload el medical record
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await MedicalService.addRecord(
        title: _titleController.text.trim(),
        type: _type,
        description: _descController.text.trim(),
        fileBytes: _fileBytes,
        fileName: _file?.name,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: MedicalRecordModel.types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Description'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(_file?.name ?? 'Attach file (PDF / image)', overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// el patient byshof el roshetat elly el doctors katbholo
class DoctorPrescriptionsPage extends StatelessWidget {
  const DoctorPrescriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Prescriptions')),
      body: AsyncView<List<PrescriptionModel>>(
        future: DoctorService.getMyPrescriptions(),
        builder: (list) {
          if (list.isEmpty) return const EmptyView(message: 'No prescriptions yet', icon: Icons.medication_outlined);
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => PrescriptionTile(p: list[i]),
          );
        },
      ),
    );
  }
}

class PrescriptionTile extends StatelessWidget {
  final PrescriptionModel p;
  final String? subtitle;
  const PrescriptionTile({super.key, required this.p, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconTile(icon: Icons.medication_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.medicineName, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('Dosage: ${p.dosage}', style: const TextStyle(fontSize: 13)),
                if (p.instructions.isNotEmpty) Text(p.instructions, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text(subtitle ?? '${p.doctorName} • ${formatDate(p.createdAt)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
