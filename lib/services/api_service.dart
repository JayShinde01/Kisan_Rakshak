import 'dart:io';
import 'package:http/http.dart' as http;
//SERVICES/API_SERVICE.DART
class ApiService {
  static const String apiUrl = "https://kisan-rakshak-mlbackend.onrender.com/flutter_predict"; 
  // 👉 Android Emulator uses 10.0.2.2 for localhost

  static Future<Map<String, dynamic>> uploadImage(File file) async {
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();
    var responseBody = await http.Response.fromStream(response);

    return {
      "status": response.statusCode,
      "body": responseBody.body
    };
  }
}