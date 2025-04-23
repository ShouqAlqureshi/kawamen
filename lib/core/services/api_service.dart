// File: core/api/api_service.dart
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class APIService {
  final String baseUrl = "https://devaice-web-api.audeering.com/api/v2";
  final String apiKey = dotenv.env['API_KEY'] ?? "";
  final String userId = dotenv.env['USER_ID'] ?? "";

  /// Uploads an audio file with the provided config and returns an uploadId
  Future<Map<String, dynamic>> uploadAudio(
      File audioFile, Map<String, dynamic> config) async {
    if (apiKey.isEmpty || userId.isEmpty) {
      throw Exception("API Key or User ID is missing.");
    }

    final uri = Uri.parse("$baseUrl/upload");

    print("Uploading to: $uri");
    print("Config: ${jsonEncode(config)}");

    final request = http.MultipartRequest("POST", uri)
      ..headers["X-API-KEY"] = apiKey
      ..headers["X-USER-ID"] = userId
      ..fields['config'] = jsonEncode(config)
      ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print("Upload response status: ${response.statusCode}");
      print("Upload response body: $responseData");

      if (response.statusCode == 200 || response.statusCode == 202) {
        final jsonResponse = json.decode(responseData);

        // Check if we got an upload ID or direct results
        if (jsonResponse.containsKey("uploadId")) {
          // We got an upload ID for polling
          return {"uploadId": jsonResponse["uploadId"], "result": null};
        } else if (jsonResponse.containsKey("result")) {
          // We got direct results
          return {"uploadId": null, "result": jsonResponse["result"]};
        } else {
          throw Exception("Unknown response format: $responseData");
        }
      } else {
        throw Exception(
            "Upload failed: ${response.statusCode} ${response.reasonPhrase} - $responseData");
      }
    } catch (e) {
      print("Error during upload: $e");
      rethrow;
    }
  }

  /// Fetches the result of a previous upload using uploadId
  Future<Map<String, dynamic>> getResult(String uploadId) async {
    if (uploadId.isEmpty) {
      throw Exception("Cannot fetch results with empty uploadId");
    }

    final uri = Uri.parse("$baseUrl/result/$uploadId");
    print("Fetching results from: $uri");

    try {
      final response = await http.get(uri, headers: {
        "X-API-KEY": apiKey,
        "X-USER-ID": userId,
      });

      print("Result response status: ${response.statusCode}");

      if (response.body.isNotEmpty) {
        print(
            "Result response body preview: ${response.body.substring(0, min(100, response.body.length))}...");
      } else {
        print("Result response body: empty");
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            "Result fetch failed: ${response.statusCode} - ${response.reasonPhrase} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching results: $e");
      rethrow;
    }
  }
}
