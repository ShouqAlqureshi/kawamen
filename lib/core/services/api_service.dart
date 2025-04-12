import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class APIService {
  final String baseUrl = "https://devaice-web-api.audeering.com/api/v2/";

  // Securely load credentials from .env(Create .env file in root directory)
  final String apiKey = dotenv.env['API_KEY'] ?? "";
  final String userId = dotenv.env['USER_ID'] ?? "";

  Future<String> uploadAudio(File audioFile) async {
    try {
      if (apiKey.isEmpty || userId.isEmpty) {
        throw Exception(
            "API Key or UserID is missing. Please set them in your .env file.");
      }

      var uri = Uri.parse("$baseUrl/upload");

      var request = http.MultipartRequest("POST", uri)
        ..headers["X-API-KEY"] = apiKey
        ..headers["X-USER-ID"] = userId
        ..fields['config'] = jsonEncode({
          "apiVersion": "4.7.0",
          "timeout": 10000,
          "modules": {
            "vad": {"minSegmentLength": 2.0},
            "speakerAttributes": {},
            "expression_large": {}
          }
        })
        ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 202) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        return jsonResponse["uploadId"] ?? "No uploadId returned";
      } else {
        throw Exception(
            "Upload failed with status: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      throw Exception("Error uploading audio: $e");
    }
  }
}
