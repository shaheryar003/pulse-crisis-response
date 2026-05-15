import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/alert.dart';
import '../models/dispatch.dart';
import '../models/incident.dart';
import '../shared/auth.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient shared = ApiClient._();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (session.token != null) 'Authorization': 'Bearer ${session.token}',
      };

  Uri _u(String path) => Uri.parse('${session.apiBase}$path');

  // --- auth ---
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final r = await http.post(_u('/auth/otp/request'), headers: _headers, body: jsonEncode({'phone': phone}));
    _check(r);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp({required String phone, required String otp, required String role}) async {
    final r = await http.post(
      _u('/auth/otp/verify'),
      headers: _headers,
      body: jsonEncode({'phone': phone, 'otp': otp, 'role': role}),
    );
    _check(r);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // --- incidents ---
  Future<List<Incident>> listIncidents({String status = 'active', String? zone}) async {
    final qp = {'status': status, if (zone != null) 'zone': zone};
    final r = await http.get(_u('/incidents').replace(queryParameters: qp), headers: _headers);
    _check(r);
    final js = jsonDecode(r.body) as Map<String, dynamic>;
    return (js['incidents'] as List).map((j) => Incident.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> incidentDetail(String id) async {
    final r = await http.get(_u('/incidents/$id'), headers: _headers);
    _check(r);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // --- signals ---
  Future<Map<String, dynamic>> submitCitizenReport(Map<String, dynamic> payload) async {
    final r = await http.post(_u('/signals/citizen'), headers: _headers, body: jsonEncode(payload));
    _check(r);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // --- dispatches ---
  Future<List<Dispatch>> dispatchQueue(String assetId) async {
    final r = await http.get(_u('/dispatch/queue').replace(queryParameters: {'asset_id': assetId}), headers: _headers);
    _check(r);
    final js = jsonDecode(r.body) as Map<String, dynamic>;
    return (js['dispatches'] as List).map((j) => Dispatch.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> ackDispatch(String id) async {
    final r = await http.post(_u('/dispatch/$id/ack'), headers: _headers);
    _check(r);
  }

  Future<void> updateDispatchStatus(String id, String status) async {
    final r = await http.post(_u('/dispatch/$id/status'), headers: _headers, body: jsonEncode({'status': status}));
    _check(r);
  }

  // --- alerts ---
  Future<List<AlertItem>> listAlerts({String? incidentId, String? status}) async {
    final qp = <String, String>{};
    if (incidentId != null) qp['incident_id'] = incidentId;
    if (status != null) qp['status'] = status;
    final r = await http.get(_u('/alerts').replace(queryParameters: qp), headers: _headers);
    _check(r);
    final js = jsonDecode(r.body) as Map<String, dynamic>;
    return (js['alerts'] as List).map((j) => AlertItem.fromJson(j as Map<String, dynamic>)).toList();
  }

  // --- resources ---
  Future<List<Map<String, dynamic>>> resources() async {
    final r = await http.get(_u('/resources'), headers: _headers);
    _check(r);
    final js = jsonDecode(r.body) as Map<String, dynamic>;
    return (js['assets'] as List).cast<Map<String, dynamic>>();
  }

  // --- scenarios ---
  Future<List<Map<String, dynamic>>> scenarios() async {
    final r = await http.get(_u('/scenarios'), headers: _headers);
    _check(r);
    final js = jsonDecode(r.body) as Map<String, dynamic>;
    return (js['scenarios'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> runScenario(String id) async {
    final r = await http.post(_u('/scenarios/$id/run'), headers: _headers);
    _check(r);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // --- trace ws ---
  Stream<Map<String, dynamic>> traceStream() {
    final url = '${session.apiBase.replaceFirst(RegExp('^http'), 'ws')}/trace';
    final channel = WebSocketChannel.connect(Uri.parse(url));
    return channel.stream.map<Map<String, dynamic>>((event) {
      try {
        return jsonDecode(event as String) as Map<String, dynamic>;
      } catch (_) {
        return {'raw': event};
      }
    });
  }

  void _check(http.Response r) {
    if (r.statusCode >= 400) {
      throw ApiException(r.statusCode, r.body);
    }
  }
}

class ApiException implements Exception {
  final int status;
  final String body;
  ApiException(this.status, this.body);
  @override
  String toString() => 'API $status: $body';
}
