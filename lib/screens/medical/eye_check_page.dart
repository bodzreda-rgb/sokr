import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../core/theme/app_theme.dart';
import '../../services/medical_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import '../doctors/doctors_page.dart';

// ======================================================
// Eye Check: el app byfta7 el camera, el user yswr 3eno,
// w bn7allel el sora b tare2a basita (nesbet el e7merar + el edaa2a)
// MOHEM: da msh tashkhees tebby w msh AI, da indicator basit bas
// ======================================================

// natiget el ta7lil
class EyeResult {
  final double rednessPercent; // nesbet el pixels el 7amra f nos el sora
  final double brightness; // 0..255
  final List<String> symptoms;

  const EyeResult(this.rednessPercent, this.brightness, this.symptoms);

  bool get tooDark => brightness < 60;
  bool get urgent => symptoms.contains('Sudden vision loss') || symptoms.contains('Eye pain');

  // el 7ala: 0 = kwayesa, 1 = e7merar khafeef / a3rad, 2 = lazem doctor
  int get level {
    if (urgent) return 2;
    if (rednessPercent >= 18) return 2;
    if (rednessPercent >= 8 || symptoms.isNotEmpty) return 1;
    return 0;
  }
}

// hena bn7allel el sora: bn3d el pixels el 7amra f el gozo2 el wastany
EyeResult analyzeEye(Uint8List bytes, List<String> symptoms) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return EyeResult(0, 0, symptoms);
  final small = img.copyResize(decoded, width: 240); // bnsa8ar el sora 3shan el sor3a

  // bnbos 3la el nos bas (makan el 3ein gowa el da2era)
  final x0 = (small.width * 0.25).round(), x1 = (small.width * 0.75).round();
  final y0 = (small.height * 0.25).round(), y1 = (small.height * 0.75).round();
  var red = 0, total = 0;
  var light = 0.0;
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final p = small.getPixel(x, y);
      final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
      light += (r + g + b) / 3;
      // pixel "7amra" lw el a7mar a3la bkteer men el a5dar w el azra2
      if (r > 120 && r > g * 1.5 && r > b * 1.4) red++;
      total++;
    }
  }
  if (total == 0) return EyeResult(0, 0, symptoms);
  return EyeResult(red * 100 / total, light / total, symptoms);
}

class EyeCheckPage extends StatefulWidget {
  const EyeCheckPage({super.key});

  @override
  State<EyeCheckPage> createState() => _EyeCheckPageState();
}

class _EyeCheckPageState extends State<EyeCheckPage> {
  CameraController? _camera;
  String? _cameraError;
  Uint8List? _photo;
  EyeResult? _result;
  bool _busy = false;

  // as2ela 3an el a3rad (el user y5tar elly 3ando)
  static const _allSymptoms = [
    'Blurred vision',
    'Redness or irritation',
    'Eye pain',
    'Floaters or dark spots',
    'Dry or itchy eyes',
    'Sudden vision loss',
  ];
  final Set<String> _symptoms = {};

  @override
  void initState() {
    super.initState();
    _openCamera();
  }

  @override
  void dispose() {
    _camera?.dispose(); // lazem n2fl el camera 3shan mtfdlsh shaghala
    super.dispose();
  }

  // hena bnfta7 el camera (el amameya lw mawgoda 3shan el user yshof nafso)
  Future<void> _openCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) throw Exception('No camera found');
      final front = cams.where((c) => c.lensDirection == CameraLensDirection.front).firstOrNull;
      final controller = CameraController(front ?? cams.first, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _camera = controller);
    } catch (_) {
      if (mounted) setState(() => _cameraError = 'Camera is not available. You can choose a photo instead.');
    }
  }

  Future<void> _capture() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    setState(() => _busy = true);
    try {
      final shot = await cam.takePicture();
      _photo = await shot.readAsBytes();
      _analyze();
    } catch (_) {
      if (mounted) showSnack(context, 'Could not take the photo', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ba2eel lw mafish camera: el user y5tar sora men el gehaz
  Future<void> _pickPhoto() async {
    final f = await FilePicker.pickFile(type: FileType.image);
    if (f == null) return;
    _photo = await f.readAsBytes();
    _analyze();
  }

  void _analyze() {
    if (_photo == null) return;
    setState(() => _result = analyzeEye(_photo!, _symptoms.toList()));
  }

  void _retake() => setState(() {
        _photo = null;
        _result = null;
      });

  // bn-save el natiga + el sora f el Medical Records
  Future<void> _saveToRecords() async {
    final r = _result!;
    setState(() => _busy = true);
    try {
      await MedicalService.addRecord(
        title: 'Eye check - ${formatDate(DateTime.now())}',
        type: 'Health Summary',
        description: '${_levelTitle(r.level)}. Redness: ${r.rednessPercent.toStringAsFixed(1)}%. '
            'Symptoms: ${r.symptoms.isEmpty ? 'none' : r.symptoms.join(', ')}.',
        fileBytes: _photo,
        fileName: 'eye_check.jpg',
      );
      if (mounted) showSnack(context, 'Saved to Medical Records');
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _levelTitle(int level) => switch (level) {
        0 => 'Your eye looks normal',
        1 => 'Mild signs - keep an eye on it',
        _ => 'Please see an eye doctor',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eye Check')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const DisclaimerCard(),
          const SizedBox(height: 14),
          if (_result == null) ..._buildCaptureStep() else ..._buildResult(_result!),
        ],
      ),
    );
  }

  // ---------------- step 1: el camera + el a3rad ----------------
  List<Widget> _buildCaptureStep() {
    final cam = _camera;
    final size = MediaQuery.sizeOf(context).width.clamp(0, 500).toDouble() - 40;
    return [
      const Text('Hold the phone close to one eye in good light, look straight, then take a photo.',
          style: TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: size,
          child: cam != null && cam.value.isInitialized
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: cam.value.previewSize?.height ?? size,
                        height: cam.value.previewSize?.width ?? size,
                        child: CameraPreview(cam),
                      ),
                    ),
                    // da'era tewaga7 el user y7ot 3eno feha
                    Center(
                      child: Container(
                        width: size * 0.55,
                        height: size * 0.55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                )
              : Container(
                  color: AppColors.peach,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20),
                  child: _cameraError == null
                      ? const CircularProgressIndicator()
                      : Text(_cameraError!, textAlign: TextAlign.center),
                ),
        ),
      ),
      const SectionHeader(title: 'Do you have any of these?'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in _allSymptoms)
            FilterChip(
              label: Text(s),
              selected: _symptoms.contains(s),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              onSelected: (v) => setState(() => v ? _symptoms.add(s) : _symptoms.remove(s)),
            ),
        ],
      ),
      const SizedBox(height: 20),
      if (cam != null)
        ElevatedButton.icon(
          onPressed: _busy ? null : _capture,
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Take photo & check'),
        ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _busy ? null : _pickPhoto,
        icon: const Icon(Icons.photo_library_outlined),
        label: const Text('Choose a photo instead'),
      ),
    ];
  }

  // ---------------- step 2: el natiga ----------------
  List<Widget> _buildResult(EyeResult r) {
    final color = [AppColors.success, AppColors.warning, AppColors.error][r.level];
    final icon = [Icons.check_circle_rounded, Icons.info_rounded, Icons.warning_rounded][r.level];
    final tips = <String>[
      if (r.tooDark) 'The photo is dark, so the result may be wrong. Retake it in better light.',
      if (r.urgent) 'Sudden vision loss or eye pain needs medical care quickly. Contact a doctor today.',
      if (r.rednessPercent >= 8) 'Some redness was detected. Rest your eyes and avoid rubbing them.',
      if (_symptoms.contains('Blurred vision') || _symptoms.contains('Floaters or dark spots'))
        'Blurred vision or floaters can be related to blood sugar. People with diabetes should have regular eye exams.',
      if (_symptoms.contains('Dry or itchy eyes')) 'Blink often and take breaks from screens.',
      if (r.level == 0) 'No obvious redness found. Keep your yearly eye exam, especially with diabetes.',
    ];
    return [
      if (_photo != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.memory(_photo!, height: 200, width: double.infinity, fit: BoxFit.cover),
        ),
      const SizedBox(height: 14),
      AppCard(
        gradient: LinearGradient(colors: [Colors.white, color.withValues(alpha: 0.12)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_levelTitle(r.level),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // nesbet el e7merar ka progress bar
            Text('Redness: ${r.rednessPercent.toStringAsFixed(1)}%'),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (r.rednessPercent / 30).clamp(0, 1).toDouble(),
                minHeight: 10,
                color: color,
                backgroundColor: AppColors.peach,
              ),
            ),
            const SizedBox(height: 8),
            Text('Light: ${r.tooDark ? 'Too dark' : 'OK'}',
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
      const SectionHeader(title: 'Advice'),
      for (final t in tips)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.circle, size: 8, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(t)),
            ],
          ),
        ),
      const SizedBox(height: 16),
      if (r.level > 0)
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DoctorsPage(initialSpecialization: 'Ophthalmologist')),
          ),
          icon: const Icon(Icons.medical_services_rounded),
          label: const Text('Find an eye doctor'),
        ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _busy ? null : _saveToRecords,
        icon: const Icon(Icons.save_alt_rounded),
        label: const Text('Save to Medical Records'),
      ),
      const SizedBox(height: 10),
      TextButton.icon(
        onPressed: _retake,
        icon: const Icon(Icons.replay_rounded),
        label: const Text('Check again'),
      ),
    ];
  }
}
