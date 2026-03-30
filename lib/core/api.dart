import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'storage.dart';

class Api {
  static Map<String, String> _headers({bool auth = true}) {
    final h = {'Content-Type': 'application/json'};
    if (auth) {
      final token = Storage.getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  static Future<Map<String, dynamic>> post(String path, Map body,
      {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('${AppConst.apiUrl}$path'),
      headers: _headers(auth: auth),
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  static Future<dynamic> get(String path) async {
    final res = await http.get(
      Uri.parse('${AppConst.apiUrl}$path'),
      headers: _headers(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> put(String path, Map body) async {
    final res = await http.put(
      Uri.parse('${AppConst.apiUrl}$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> uploadImage(
      String path, File file, Map<String, String> fields) async {
    final token = Storage.getToken();
    final request =
        http.MultipartRequest('POST', Uri.parse('${AppConst.apiUrl}$path'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files
        .add(await http.MultipartFile.fromPath('image', file.path));
    fields.forEach((k, v) => request.fields[k] = v);
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> uploadAvatar(File file) async {
    final token = Storage.getToken();
    final request = http.MultipartRequest(
        'POST', Uri.parse('${AppConst.apiUrl}/users/avatar'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files
        .add(await http.MultipartFile.fromPath('avatar', file.path));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body);
  }
}
