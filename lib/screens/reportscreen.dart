import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  File? _image;
  Map<String, dynamic>? _aiResult;
  bool _analyzing = false;
  bool _submitting = false;
  String _selectedLang = 'en';
  int _step = 0;
  final _descController = TextEditingController();
  static const double _lat = 12.9716;
  static const double _lng = 77.5946;
  static const String _address = 'Bengaluru, Karnataka';

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1280);
    if (picked == null) return;
    setState(() { _image = File(picked.path); _analyzing = true; _aiResult = null; _step = 0; });
    try {
      final bytes = await File(picked.path).readAsBytes();
      final result = await ApiService().analyzeImage(
          imageBytes: bytes, lat: _lat, lng: _lng,
          address: _address, language: _selectedLang);
      setState(() { _aiResult = result; _analyzing = false; _step = 1; });
    } catch (e) {
      setState(() => _analyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('AI analysis failed: $e')),
          ]),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Future<void> _submitReport() async {
    if (_aiResult == null || _image == null) return;
    setState(() => _submitting = true);
    try {
      final bytes = await _image!.readAsBytes();
      final result = await ApiService().submitReport(
        issueType: _aiResult!['issue_type'] as String,
        severity: _aiResult!['severity'] as String,
        lat: _lat, lng: _lng, address: _address,
        description: _descController.text.isNotEmpty
            ? _descController.text
            : (_aiResult!['ai_summary'] as String? ?? ''),
        language: _selectedLang,
        imageBytes: bytes,
      );
      setState(() { _submitting = false; _step = 2; });
      if (mounted) _showSuccessDialog(result['ticket_number'] as String);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Submit failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _showSuccessDialog(String ticket) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF138808).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: Color(0xFF138808), size: 42),
            ),
            const SizedBox(height: 16),
            const Text('Report Submitted!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2340))),
            const SizedBox(height: 8),
            const Text('Your civic issue has been reported\nsuccessfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8C8A82), fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEdE8)),
              ),
              child: Column(children: [
                const Text('Ticket Number',
                    style: TextStyle(color: Color(0xFF8C8A82), fontSize: 11)),
                const SizedBox(height: 4),
                Text(ticket,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6B35),
                        fontSize: 18,
                        letterSpacing: 1.5)),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.stars_rounded,
                    color: Color(0xFFE8A020), size: 16),
                const SizedBox(width: 6),
                const Text('+10 points earned!',
                    style: TextStyle(
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('Back to Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        title: const Text('Report Civic Issue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLang,
                icon: const Icon(Icons.language,
                    color: Color(0xFFFF6B35), size: 18),
                style: const TextStyle(
                    color: Color(0xFF1A2340),
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                items: AppConstants.supportedLanguages.entries
                    .map((e) => DropdownMenuItem(
                        value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedLang = v ?? 'en'),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Step indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEdE8)),
              ),
              child: Row(children: [
                _Step(1, 'Capture', Icons.camera_alt, _step >= 0),
                Expanded(child: _StepLine(_step >= 1)),
                _Step(2, 'AI Review', Icons.auto_awesome, _step >= 1),
                Expanded(child: _StepLine(_step >= 2)),
                _Step(3, 'Done', Icons.check_circle, _step >= 2),
              ]),
            ),
            const SizedBox(height: 16),

            // Image capture
            GestureDetector(
              onTap: () => _showImageSheet(),
              child: Container(
                height: 220, width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _image != null
                        ? const Color(0xFFFF6B35)
                        : const Color(0xFFEEEdE8),
                    width: _image != null ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8),
                  ],
                ),
                child: _image != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_image!, fit: BoxFit.cover,
                                width: double.infinity, height: double.infinity)),
                          Positioned(
                            top: 10, right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.edit, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0EB),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(Icons.add_a_photo_outlined,
                                size: 36, color: Color(0xFFFF6B35)),
                          ),
                          const SizedBox(height: 12),
                          const Text('Tap to capture photo',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A2340))),
                          const SizedBox(height: 4),
                          const Text('AI will auto-detect the civic issue',
                              style: TextStyle(
                                  color: Color(0xFF8C8A82), fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),

            Row(children: [
              Expanded(
                child: _ActionButton(
                  Icons.camera_alt, 'Camera',
                  const Color(0xFFFF6B35),
                  () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  Icons.photo_library_outlined, 'Gallery',
                  const Color(0xFF1A2340),
                  () => _pickImage(ImageSource.gallery),
                ),
              ),
            ]),

            if (_analyzing) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEdE8)),
                ),
                child: Column(children: [
                  const LinearProgressIndicator(
                    color: Color(0xFFFF6B35),
                    backgroundColor: Color(0xFFFFF0EB),
                  ),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.auto_awesome,
                        color: Color(0xFFFF6B35), size: 18),
                    const SizedBox(width: 8),
                    const Text('AI Pipeline Running...',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2340))),
                  ]),
                  const SizedBox(height: 6),
                  const Text('YOLOv8 detection  •  Severity analysis  •  Gemini NLP',
                      style: TextStyle(
                          color: Color(0xFF8C8A82), fontSize: 11)),
                ]),
              ),
            ],

            if (_aiResult != null && !_analyzing) ...[
              const SizedBox(height: 16),
              _AIResultPanel(
                  aiResult: _aiResult!, descController: _descController),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, size: 18),
                            const SizedBox(width: 8),
                            const Text('Submit Report',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('+10 pts',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  void _showImageSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Add Photo',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2340))),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            tileColor: const Color(0xFFFFF0EB),
            leading: const Icon(Icons.camera_alt,
                color: Color(0xFFFF6B35)),
            title: const Text('Take Photo',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Use your camera'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            tileColor: const Color(0xFFF8F7F4),
            leading: const Icon(Icons.photo_library_outlined,
                color: Color(0xFF1A2340)),
            title: const Text('Choose from Gallery',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Select existing photo'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
        ]),
      ),
    );
  }
}

class _AIResultPanel extends StatelessWidget {
  final Map<String, dynamic> aiResult;
  final TextEditingController descController;
  const _AIResultPanel({required this.aiResult, required this.descController});

  @override
  Widget build(BuildContext context) {
    final confidence =
        ((aiResult['confidence_score'] as num) * 100).toStringAsFixed(0);
    final isAiGen = aiResult['is_ai_generated'] as bool? ?? false;
    final severity = aiResult['severity'] as String;
    final severityColor = severity == 'high'
        ? const Color(0xFFCC2222)
        : severity == 'medium'
            ? const Color(0xFFE8A020)
            : const Color(0xFF138808);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEdE8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F7F4),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: const Color(0xFF138808).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.auto_awesome,
                  color: Color(0xFF138808), size: 16),
            ),
            const SizedBox(width: 8),
            const Text('AI Detection Result',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2340),
                    fontSize: 14)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF138808).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                const Icon(Icons.verified, color: Color(0xFF138808), size: 12),
                const SizedBox(width: 4),
                Text('$confidence% match',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF138808),
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ResultRow(Icons.search, 'Issue Detected',
                (aiResult['issue_type'] as String)
                    .replaceAll('_', ' ')
                    .split(' ')
                    .map((w) => w[0].toUpperCase() + w.substring(1))
                    .join(' '),
                const Color(0xFF0066CC)),
            const Divider(height: 16, color: Color(0xFFEEEdE8)),
            _ResultRow(Icons.warning_amber_rounded, 'Severity Level',
                severity.toUpperCase(), severityColor),
            const Divider(height: 16, color: Color(0xFFEEEdE8)),
            _ResultRow(Icons.account_balance, 'Department Assigned',
                aiResult['department_suggestion'] as String? ??
                    'Municipal Corporation',
                const Color(0xFF6600CC)),

            if (isAiGen) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_rounded,
                      color: Color(0xFFCC2222), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Image may be AI-generated. Report will be manually reviewed.',
                      style: TextStyle(
                          color: Color(0xFFCC2222), fontSize: 11),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 14),
            TextField(
              controller: descController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A2340)),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.edit_note, color: Color(0xFF8C8A82), size: 20),
                ),
                hintText: aiResult['ai_summary'] as String? ??
                    'AI generated description...',
                hintStyle: const TextStyle(
                    fontSize: 12, color: Color(0xFF8C8A82)),
                labelText: 'Description (auto-filled by AI)',
                labelStyle: const TextStyle(
                    fontSize: 12, color: Color(0xFF8C8A82)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFEEEdE8))),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFFF6B35), width: 1.8),
                ),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFEEEdE8))),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _ResultRow(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8C8A82), fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF1A2340))),
        ]),
      ]);
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ]),
        ),
      );
}

class _Step extends StatelessWidget {
  final int number;
  final String label;
  final IconData icon;
  final bool active;
  const _Step(this.number, this.label, this.icon, this.active);

  @override
  Widget build(BuildContext context) => Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFF6B35) : const Color(0xFFEEEdE8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: active ? Colors.white : Colors.grey, size: 18),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: active ? const Color(0xFFFF6B35) : Colors.grey,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal)),
      ]);
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine(this.active);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 2,
          color: active ? const Color(0xFFFF6B35) : const Color(0xFFEEEdE8),
        ),
      );
}