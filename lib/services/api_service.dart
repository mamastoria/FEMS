import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/script_request.dart';
import '../utils/constants.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = AppConstants.baseUrl});

  Future<Map<String, dynamic>> generateScript(ScriptRequest request) async {
    final url = Uri.parse('$baseUrl/api/script');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate script: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<String> renderAllStart(Map<String, dynamic> scriptJson) async {
    final url = Uri.parse('$baseUrl/api/render_all_start');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'script': scriptJson}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['job_id'];
      } else {
        throw Exception('Failed to start render: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Future<Map<String, dynamic>> checkJobStatus(String jobId) async {
    final url = Uri.parse('$baseUrl/api/job/$jobId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
         // If job not found or 404
         return {'status': 'error', 'error': 'Job not found'};
      }
    } catch (e) {
       return {'status': 'error', 'error': '$e'};
    }
  }
}
