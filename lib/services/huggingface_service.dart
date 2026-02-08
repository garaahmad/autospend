import 'dart:convert';
import 'package:http/http.dart' as http;

class HuggingFaceService {
  final String _token = 'YOUR_HUGGINGFACE_TOKEN';
  final String _model = 'meta-llama/Llama-3.2-3B-Instruct';
  final String _baseUrl = 'https://router.huggingface.co/v1/chat/completions';

  HuggingFaceService();

  /// Sanitize sensitive data
  String sanitizeData(String text) {
    return text.replaceAll(RegExp(r'\d{10,}'), '[SENSITIVE DATA]');
  }

  Future<Map<String, dynamic>?> analyzeNotification(String originalText) async {
    final sanitizedText = sanitizeData(originalText);

    final systemPrompt = """
Analyze the following text from a mobile notification. 
Context: You are a financial transaction extractor for a budgeting app.

CRITICAL RULES:
1. ONLY return 'is_banking': true if this is an OUTGOING financial deduction (خصم), purchase (شراء/مشتريات/سحب), or spending.
2. EXPLICITLY set 'is_banking': false for:
   - Incoming transfers (حوالة واردة / استلام مبلغ / تم استلام).
   - Account information updates (تحديث معلومات / تحديث مستخدم).
   - OTP codes, backup alerts, system messages, USB connections.
   - Promotional messages or marketing.
3. If 'is_banking' is true, you MUST find a valid 'amount' and 'currency'.
4. Extract 'merchant' strictly. In Arabic messages, it usually follows 'لدى:' or 'في:'. In English, it follows 'at:'.
5. Extract 'card_digits' if mentioned.
6. Generate a short, descriptive 'category' based on the merchant.
7. Return ONLY a valid JSON object.

Format Example:
{"is_banking": true, "merchant": "Starbucks", "amount": 25.5, "currency": "SAR", "card_digits": "1234", "category": "Food & Drinks"}

Text to analyze:
""";

    try {
      print('Calling Hugging Face Router API...');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': sanitizedText},
          ],
          'max_tokens': 150,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        String text = "";

        if (data['choices'] != null && data['choices'].isNotEmpty) {
          text = data['choices'][0]['message']['content'] ?? "";
        }

        print('HF Raw Response: $text');

        // Extract JSON from the response
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
        if (jsonMatch != null) {
          final jsonString = jsonMatch.group(0)!;
          final result = json.decode(jsonString) as Map<String, dynamic>;

          if (result['is_banking'] == true) {
            // Robust amount parsing
            if (result['amount'] != null) {
              if (result['amount'] is String) {
                final cleanAmount = result['amount'].toString().replaceAll(
                  RegExp(r'[^0-9.]'),
                  '',
                );
                result['amount'] = double.tryParse(cleanAmount) ?? 0.0;
              } else if (result['amount'] is num) {
                result['amount'] = (result['amount'] as num).toDouble();
              }
            }
            return result;
          }
          return result;
        }
      } else {
        print('HF API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception in HuggingFaceService: $e');
    }
    return null;
  }
}
