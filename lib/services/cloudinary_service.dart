// lib/services/cloudinary_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class CloudinaryService {
  // Replace with your values
  static const String cloudName = "dmteuzsos";
  static const String uploadPreset = "dmteuzsos";

  /// Upload image to Cloudinary (unsigned).
  /// Accepts either a File (mobile/desktop) OR fileBytes + fileName (web).
  ///
  /// Returns the `secure_url` on success, otherwise null.
  static Future<String?> uploadImage({
    File? file,
    Uint8List? fileBytes,
    String? fileName,
    String folder = "general",
    String? publicId, // optional: specify desired public id
    String resourceType = "image", // non-nullable now
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (file == null && fileBytes == null) {
      debugPrint("Cloudinary upload failed: no file or bytes provided.");
      return null;
    }

    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload");
      final request = http.MultipartRequest("POST", url);

      // Basic fields
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;
      if (publicId != null && publicId.isNotEmpty) request.fields['public_id'] = publicId;

      // Prepare file part with MIME type
      if (file != null) {
        final name = file.path.split(Platform.pathSeparator).last;
        final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
        final mimeParts = mimeType.split('/');
        final streamFile = await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: name,
          contentType: MediaType(mimeParts[0], mimeParts[1]),
        );
        request.files.add(streamFile);
      } else if (fileBytes != null) {
        // Ensure filename and mime
        final inferredMime = (fileName != null && fileName.contains('.'))
            ? (lookupMimeType(fileName) ?? 'image/jpeg')
            : 'image/jpeg';
        final mimeParts = inferredMime.split('/');
        final fname = fileName ??
            'upload_${DateTime.now().millisecondsSinceEpoch}.${_extFromMime(inferredMime) ?? 'jpg'}';

        final multipart = http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fname,
          contentType: MediaType(mimeParts[0], mimeParts[1]),
        );
        request.files.add(multipart);
      } else {
        throw Exception('No file data available.');
      }

      // Optional headers
      request.headers['Accept'] = 'application/json';

      // Send with timeout
      final streamed = await request.send().timeout(timeout);
      final respStr = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        final data = json.decode(respStr);
        final secureUrl = data['secure_url'] as String?;
        debugPrint('Cloudinary upload success: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('Cloudinary upload failed (status: ${streamed.statusCode}): $respStr');
        return null;
      }
    } catch (e, st) {
      debugPrint('Cloudinary upload exception: $e\n$st');
      return null;
    }
  }

  // Helper: try to guess file extension from mime type
  static String? _extFromMime(String mime) {
    final mapping = <String, String>{
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/gif': 'gif',
      'image/webp': 'webp',
      'image/heic': 'heic',
      'video/mp4': 'mp4',
      // add more if needed
    };
    return mapping[mime];
  }
}
