import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://backend-fpoj.onrender.com/api';
  
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (includeAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  static Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Request failed';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData is String) {
          errorMessage = errorData;
        }
      } catch (e) {
        errorMessage = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
      }
      throw Exception(errorMessage);
    }
  }

  // Authentication APIs
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signin'),
      headers: await _getHeaders(includeAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return await _handleResponse(response);
  }

  static Future<String> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: await _getHeaders(includeAuth: false),
      body: jsonEncode(userData),
    );
    return await _handleResponse(response);
  }

  static Future<String> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: await _getHeaders(includeAuth: false),
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );
    return await _handleResponse(response);
  }

  static Future<String> resendOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/resend-otp?email=$email'),
      headers: await _getHeaders(includeAuth: false),
    );
    return await _handleResponse(response);
  }

  static Future<String> changePassword(String currentPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    final result = await _handleResponse(response);
    return result['message'] ?? 'Password changed successfully';
  }

  // Assessment APIs
  static Future<Map<String, dynamic>> generateAIAssessment(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assessments/generate-ai'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return await _handleResponse(response);
  }

  static Future<List<dynamic>> getStudentAssessments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/assessments/student'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> submitAssessment(String assessmentId, Map<String, dynamic> submission) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assessments/$assessmentId/submit'),
      headers: await _getHeaders(),
      body: jsonEncode(submission),
    );
    return await _handleResponse(response);
  }

  static Future<List<dynamic>> getAssessmentResults(String assessmentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/assessments/$assessmentId/results'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createAssessment(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assessments'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return await _handleResponse(response);
  }

  static Future<List<dynamic>> getProfessorAssessments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/assessments/professor'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<List<dynamic>> searchStudents(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/assessments/search-students?query=$query'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  // Job APIs
  static Future<List<dynamic>> getAllJobs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs'),
      headers: await _getHeaders(includeAuth: false),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createJob(Map<String, dynamic> jobData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jobs'),
      headers: await _getHeaders(),
      body: jsonEncode(jobData),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateJob(String jobId, Map<String, dynamic> jobData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/jobs/$jobId'),
      headers: await _getHeaders(),
      body: jsonEncode(jobData),
    );
    return await _handleResponse(response);
  }

  static Future<void> deleteJob(String jobId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/jobs/$jobId'),
      headers: await _getHeaders(),
    );
    await _handleResponse(response);
  }

  static Future<List<dynamic>> getMyJobs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs/my-jobs'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  // Events APIs
  static Future<List<dynamic>> getApprovedEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/events/approved'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateAttendance(String eventId, bool attending) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/events/$eventId/attendance'),
      headers: await _getHeaders(),
      body: jsonEncode({'attending': attending}),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> submitEventRequest(Map<String, dynamic> eventData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/alumni-events/request'),
      headers: await _getHeaders(),
      body: jsonEncode(eventData),
    );
    return await _handleResponse(response);
  }

  // Alumni Directory APIs
  static Future<List<dynamic>> getAllVerifiedAlumni() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/alumni-directory'),
      headers: await _getHeaders(includeAuth: false),
    );
    return await _handleResponse(response);
  }

  static Future<List<dynamic>> getAllVerifiedAlumniForAlumni() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/alumni-directory/for-alumni'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAlumniProfile(String alumniId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/alumni-directory/$alumniId'),
      headers: await _getHeaders(includeAuth: false),
    );
    return await _handleResponse(response);
  }

  // Connection APIs
  static Future<Map<String, dynamic>> sendConnectionRequest(String recipientId, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/connections/send-request'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'recipientId': recipientId,
        'message': message,
      }),
    );
    return await _handleResponse(response);
  }

  static Future<List<dynamic>> getPendingConnectionRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/connections/pending'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> acceptConnectionRequest(String connectionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/connections/$connectionId/accept'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> rejectConnectionRequest(String connectionId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/connections/$connectionId/reject'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getConnectionStatus(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/connections/status/$userId'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  // Profile APIs
  static Future<Map<String, dynamic>> getStudentProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/students/my-profile'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateStudentProfile(Map<String, dynamic> profileData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/students/my-profile'),
      headers: await _getHeaders(),
      body: jsonEncode(profileData),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAlumniMyProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/alumni/my-profile'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateAlumniProfile(Map<String, dynamic> profileData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/alumni/my-profile'),
      headers: await _getHeaders(),
      body: jsonEncode(profileData),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProfessorProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/professors/my-profile'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfessorProfile(Map<String, dynamic> profileData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/professors/my-profile'),
      headers: await _getHeaders(),
      body: jsonEncode(profileData),
    );
    return await _handleResponse(response);
  }

  // Activity APIs
  static Future<void> logActivity(String type, String description) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/activities'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'type': type,
          'description': description,
        }),
      );
    } catch (e) {
      // Don't throw error for activity logging failures
      print('Failed to log activity: $e');
    }
  }

  static Future<Map<String, dynamic>> getHeatmapData(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/activities/heatmap/$userId'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  // Chat APIs
  static Future<Map<String, dynamic>> sendAIMessage(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/ai'),
      headers: await _getHeaders(),
      body: jsonEncode({'message': message}),
    );
    return await _handleResponse(response);
  }

  static Future<List<dynamic>> getConversations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/conversations'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<List<dynamic>> getAllChatUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/users'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> sendMessage(String receiverId, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/send'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'receiverId': receiverId,
        'message': message,
      }),
    );
    return await _handleResponse(response);
  }

  static Future<List<dynamic>> getChatHistory(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/history/$userId'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  // Management APIs
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/management/stats'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<List<dynamic>> getAlumniApplications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/management/alumni'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<String> approveAlumni(String alumniId, bool approved) async {
    final response = await http.put(
      Uri.parse('$baseUrl/management/alumni/$alumniId/status'),
      headers: await _getHeaders(),
      body: jsonEncode({'approved': approved}),
    );
    return await _handleResponse(response);
  }

  static Future<List<dynamic>> getAllAlumniEventRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/management/alumni-event-requests'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> approveAlumniEventRequest(String requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/management/alumni-event-requests/$requestId/approve'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> rejectAlumniEventRequest(String requestId, String reason) async {
    final response = await http.post(
      Uri.parse('$baseUrl/management/alumni-event-requests/$requestId/reject'),
      headers: await _getHeaders(),
      body: jsonEncode({'reason': reason}),
    );
    return await _handleResponse(response);
  }

  // Alumni Stats
  static Future<Map<String, dynamic>> getAlumniStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/alumni/stats'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  // Attendance APIs
  static Future<List<dynamic>> getStudentsByClass(String department, String className) async {
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/students?department=${Uri.encodeComponent(department)}&className=$className'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> submitAttendance(Map<String, dynamic> attendanceData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/submit'),
      headers: await _getHeaders(),
      body: jsonEncode(attendanceData),
    );
    return await _handleResponse(response);
  }

  static Future<List<dynamic>> getProfessorAttendanceRecords(String? className) async {
    String url = '$baseUrl/attendance/professor/records';
    if (className != null) {
      url += '?className=$className';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMyAttendanceSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/student/my-summary'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  // Task APIs
  static Future<List<dynamic>> getUserTasks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: await _getHeaders(),
      body: jsonEncode(taskData),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> generateRoadmap(String taskId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/roadmap'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateTaskStatus(String taskId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$taskId/status'),
      headers: await _getHeaders(),
      body: jsonEncode({'status': status}),
    );
    return await _handleResponse(response);
  }
}