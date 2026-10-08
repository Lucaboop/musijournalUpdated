// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart';
//
// class OpenAIService {
//   final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
//
//   Future<String> sendMessage(String message) async {
//     final response = await http.post(
//       Uri.parse('https://api.openai.com/v1/chat/completions'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $apiKey',
//       },
//       body: jsonEncode({
//         "model": "gpt-4.1-mini",
//         "messages": [
//           {
//             "role": "user",
//             "content": message
//           }
//         ]
//       }),
//     );
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//
//       return data['choices'][0]['message']['content'];
//     } else {
//       print(response.body);
//       throw Exception('Failed to get response');
//     }
//   }
// }