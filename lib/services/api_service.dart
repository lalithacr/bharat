import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Flutter Web  → http://localhost:8000/api/v1
  // Android Emu  → http://10.0.2.2:8000/api/v1
  // Real device  → http://YOUR_PC_IP:8000/api/v1
  static const String _base = 'http://localhost:8000/api/v1';

  // ── Token ─────────────────────────────────────────────────────────────────
  Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('access_token', token);
  }

  Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('access_token');
  }

  Future<void> clearToken() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('access_token');
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await http.post(
      Uri.parse('$_base/auth/otp/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp(
      String phone, String otp) async {
    final res = await http.post(
      Uri.parse('$_base/auth/otp/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['access_token'] != null) {
      await saveToken(data['access_token'] as String);
    }
    return data;
  }

  Future<Map<String, dynamic>> loginGoogle(String idToken) async {
    final res = await http.post(
      Uri.parse('$_base/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken, 'preferred_lang': 'en'}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['access_token'] != null) {
      await saveToken(data['access_token'] as String);
    }
    return data;
  }

  // ── Reports ───────────────────────────────────────────────────────────────
  Future<List<dynamic>> getMyReports({String? status}) async {
    final headers = await _authHeaders();
    final q = status != null ? '?status=$status' : '';
    final res = await http.get(
        Uri.parse('$_base/reports/my$q'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    return [];
  }

  Future<List<dynamic>> getNearbyReports({
    required double lat,
    required double lng,
    double radiusKm = 2.0,
    String? issueType,
  }) async {
    var url = '$_base/reports/nearby?lat=$lat&lng=$lng&radius_km=$radiusKm';
    if (issueType != null) url += '&issue_type=$issueType';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    return [];
  }

  Future<Map<String, dynamic>> submitReport({
    required String issueType,
    required String severity,
    required double lat,
    required double lng,
    String address = '',
    String description = '',
    String language = 'en',
    File? image,
  }) async {
    final token = await getToken();
    final req = http.MultipartRequest(
        'POST', Uri.parse('$_base/reports'));
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.fields['issue_type']  = issueType;
    req.fields['severity']    = severity;
    req.fields['latitude']    = lat.toString();
    req.fields['longitude']   = lng.toString();
    req.fields['address']     = address;
    req.fields['description'] = description;
    req.fields['language']    = language;
    if (image != null) {
      req.files.add(
          await http.MultipartFile.fromPath('image', image.path));
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> analyzeImage({
    required File image,
    required double lat,
    required double lng,
    String address = '',
    String language = 'en',
  }) async {
    final token = await getToken();
    final req = http.MultipartRequest(
        'POST', Uri.parse('$_base/reports/analyze-image'));
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.fields['latitude']  = lat.toString();
    req.fields['longitude'] = lng.toString();
    req.fields['address']   = address;
    req.fields['language']  = language;
    req.files
        .add(await http.MultipartFile.fromPath('image', image.path));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Analytics ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboardStats() async {
    final headers = await _authHeaders();
    final res = await http.get(
        Uri.parse('$_base/analytics/dashboard'), headers: headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return {};
  }

  Future<List<dynamic>> getLeaderboard() async {
    final res = await http.get(Uri.parse('$_base/analytics/leaderboard'));
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    return [];
  }
}