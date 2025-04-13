// File: core/api/api_service.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class APIService {
  final String baseUrl = "https://devaice-web-api.audeering.com/api/v2/";
  final String apiKey = dotenv.env['API_KEY'] ?? "";
  final String userId = dotenv.env['USER_ID'] ?? "";

  /// Uploads an audio file with the provided config and returns an uploadId
  Future<String> uploadAudio(
      File audioFile, Map<String, dynamic> config) async {
    if (apiKey.isEmpty || userId.isEmpty) {
      throw Exception("API Key or User ID is missing.");
    }

    final uri = Uri.parse("$baseUrl/upload");

    final request = http.MultipartRequest("POST", uri)
      ..headers["X-API-KEY"] = apiKey
      ..headers["X-USER-ID"] = userId
      ..fields['config'] = jsonEncode(config)
      ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 202) {
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);
      return jsonResponse["uploadId"] ?? "";
    } else {
      throw Exception(
          "Upload failed: ${response.statusCode} ${response.reasonPhrase}");
    }
  }

  /// Fetches the result of a previous upload using uploadId
  Future<Map<String, dynamic>> getResult(String uploadId) async {
    final uri = Uri.parse("$baseUrl/result/$uploadId");

    final response = await http.get(uri, headers: {
      "X-API-KEY": apiKey,
      "X-USER-ID": userId,
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Result fetch failed: ${response.statusCode}");
    }
  }
}
