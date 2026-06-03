import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/balance_info.dart';

class ApiService {
  static const String balanceUrl = 'https://api.deepseek.com/user/balance';

  Future<List<BalanceInfo>> queryBalance(String apiKey) async {
    final response = await http.get(
      Uri.parse(balanceUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      String msg = 'HTTP ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        msg = body['message'] ?? body['msg'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }

    final data = jsonDecode(response.body);
    final infos = data['balance_infos'] as List<dynamic>?;
    if (infos == null || infos.isEmpty) {
      throw Exception('No balance data');
    }

    return infos.map((e) => BalanceInfo.fromJson(e as Map<String, dynamic>)).toList();
  }
}
