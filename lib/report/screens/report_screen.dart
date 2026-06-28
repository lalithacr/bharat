import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _api         = ApiService();
  final _descCtrl    = TextEditingController();
  final _addressCtrl = TextEditingController();

  XFile?      _imageFile;   // ✅ use XFile instead of File (works on web)
  Uint8List?  _imageBytes;  // ✅ bytes for web preview
  String   _issueType = 'pothole';
  String   _severity  = 'medium';
  double?  _lat;
  double?  _lng;
  bool     _loading   = false;
  bool     _submitted = false;
  String?  _ticketNumber;
  String?  _error;

  static const _issueTypes = [
    'pothole', 'garbage', 'water_leak', 'broken_light',
    'road_damage', 'drainage', 'flooding',
  ];

  static const _severities = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() { _lat = pos.latitude; _lng = pos.longitude; });
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, // ✅ gallery works on web; camera may not
        imageQuality: 75);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile  = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (_lat == null || _lng == null) {
      setState(() => _error = 'Location not available. Please enable GPS.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.submitReport(
        issueType:   _issueType,
        severity:    _severity,
        lat:         _lat!,
        lng:         _lng!,
        address:     _addressCtrl.text,
        description: _descCtrl.text,
        imageBytes: kIsWeb ? _imageBytes : null,
        image:       kIsWeb ? null : _imageFile as dynamic,
        imageFileName: _imageFile?.name,
      );
      setState(() {
        _submitted    = true;
        _ticketNumber = data['ticket_number']?.toString();
      });
    } catch (_) {
      setState(() => _error = 'Submission failed. Check your connection.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _submitted    = false;
      _ticketNumber = null;
      _imageFile    = null;
      _imageBytes   = null;
      _error        = null;
      _issueType    = 'pothole';
      _severity     = 'medium';
      _descCtrl.clear();
      _addressCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A2035),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF22C55E), size: 72),
              const SizedBox(height: 16),
              const Text('Report Submitted!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_ticketNumber != null)
                Text(_ticketNumber!,
                    style: const TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Report Another Issue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A2035),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232B45),
        automaticallyImplyLeading: false,
        title: const Text('Report Issue',
            style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo picker ─────────────────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF232B45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _imageBytes != null
                          ? const Color(0xFFFF6B35)
                          : Colors.white24),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        // ✅ Image.memory works on both web and mobile
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: Colors.white38, size: 40),
                          SizedBox(height: 8),
                          Text('Tap to attach photo',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),
            _Label('Issue Type'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _issueTypes.map((t) {
                final on = _issueType == t;
                return GestureDetector(
                  onTap: () => setState(() => _issueType = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: on
                          ? const Color(0xFFFF6B35).withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: on
                              ? const Color(0xFFFF6B35)
                              : Colors.white24),
                    ),
                    child: Text(
                      t.replaceAll('_', ' '),
                      style: TextStyle(
                          color: on
                              ? const Color(0xFFFF6B35)
                              : Colors.white54,
                          fontSize: 12,
                          fontWeight: on
                              ? FontWeight.w700
                              : FontWeight.w400),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            _Label('Severity'),
            Row(
              children: _severities.map((s) {
                final on = _severity == s;
                final color = s == 'high'
                    ? const Color(0xFFEF4444)
                    : s == 'medium'
                        ? const Color(0xFFFF6B35)
                        : const Color(0xFF22C55E);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _severity = s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: on
                            ? color.withOpacity(0.2)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: on ? color : Colors.white24),
                      ),
                      child: Center(
                        child: Text(
                          s.toUpperCase(),
                          style: TextStyle(
                              color: on ? color : Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            _Label('Address (optional)'),
            TextField(
              controller: _addressCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('e.g. MG Road, Coimbatore'),
            ),

            const SizedBox(height: 16),
            _Label('Description (optional)'),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Describe the issue...'),
            ),

            const SizedBox(height: 8),
            Row(children: [
              Icon(
                _lat != null
                    ? Icons.location_on_rounded
                    : Icons.location_off_outlined,
                color: _lat != null
                    ? const Color(0xFF22C55E)
                    : Colors.white38,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                _lat != null
                    ? 'GPS: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                    : 'Waiting for GPS...',
                style: TextStyle(
                    color: _lat != null ? Colors.white38 : Colors.white24,
                    fontSize: 11),
              ),
            ]),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontSize: 12)),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _loading ? 'Submitting...' : 'Submit Report',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF232B45),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: Color(0xFFFF6B35), width: 1.5)),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );
}