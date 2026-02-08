import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'duqagxxpu';
  static const String _uploadPreset = 'saferoute_unsigned';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/duqagxxpu/image/upload';

  Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
        ..fields['upload_preset'] = _uploadPreset
        ..fields['cloud_name'] = _cloudName
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['secure_url'] is String) {
          return data['secure_url'] as String;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
