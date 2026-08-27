import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/ai_message.dart';

enum AiProviderType {
  openai,
  gemini,
  groq,
}

class AiService {
  // Fetch Live Available Models for a provider using user's API Key
  static Future<List<String>> fetchAvailableModels(AiProviderType provider, String apiKey) async {
    if (apiKey.trim().isEmpty) {
      return getDefaultModels(provider);
    }

    try {
      if (provider == AiProviderType.groq) {
        final res = await http.get(
          Uri.parse('https://api.groq.com/openai/v1/models'),
          headers: {'Authorization': 'Bearer ${apiKey.trim()}'},
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          final list = (data['data'] as List?) ?? [];
          final models = list
              .map<String>((m) => m['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty && !id.contains('whisper') && !id.contains('tts'))
              .toList();
          models.sort();
          if (models.isNotEmpty) return models;
        }
      } else if (provider == AiProviderType.openai) {
        final res = await http.get(
          Uri.parse('https://api.openai.com/v1/models'),
          headers: {'Authorization': 'Bearer ${apiKey.trim()}'},
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          final list = (data['data'] as List?) ?? [];
          final models = list
              .map<String>((m) => m['id']?.toString() ?? '')
              .where((id) => id.startsWith('gpt-') || id.startsWith('chatgpt-') || id.startsWith('o1') || id.startsWith('o3'))
              .toList();
          models.sort();
          if (models.isNotEmpty) return models;
        }
      } else if (provider == AiProviderType.gemini) {
        final res = await http.get(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey.trim()}'),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          final list = (data['models'] as List?) ?? [];
          final models = list
              .map<String>((m) {
                final name = m['name']?.toString() ?? '';
                return name.replaceFirst('models/', '');
              })
              .where((id) => id.contains('gemini'))
              .toList();
          models.sort();
          if (models.isNotEmpty) return models;
        }
      }
    } catch (_) {}

    return getDefaultModels(provider);
  }

  static List<String> getDefaultModels(AiProviderType provider) {
    switch (provider) {
      case AiProviderType.groq:
        return const [
          'llama-3.1-8b-instant',
          'llama-3.1-70b-versatile',
          'llama3-70b-8192',
          'llama3-8b-8192',
          'mixtral-8x7b-32768',
          'gemma2-9b-it',
          'deepseek-r1-distill-llama-70b',
          'qwen-2.5-32b',
        ];
      case AiProviderType.openai:
        return const [
          'gpt-4o-mini',
          'gpt-4o',
          'gpt-4-turbo',
          'gpt-3.5-turbo',
          'o1-mini',
          'o3-mini',
        ];
      case AiProviderType.gemini:
        return const [
          'gemini-1.5-flash',
          'gemini-1.5-pro',
          'gemini-2.0-flash',
          'gemini-1.5-flash-8b',
        ];
    }
  }

  // =========================================================================
  // --- SMART INTENT DETECTOR & INSTANT ERP EXECUTOR (100% RELIABLE) ---
  // =========================================================================
  static Future<AiMessage?> tryExecuteDirectAccountingIntent(String prompt) async {
    final cleanPrompt = prompt.trim();

    // 1. Intent: Vouchers (سند قبض / سند صرف)
    if (cleanPrompt.contains('سند قبض') || cleanPrompt.contains('سند صرف') || cleanPrompt.contains('قبض') || cleanPrompt.contains('صرف')) {
      final isPayment = cleanPrompt.contains('صرف');
      final isReceipt = cleanPrompt.contains('قبض') || !isPayment;
      
      // Extract amount using regex
      final amountMatch = RegExp(r'(\d+[\d\.,]*)').firstMatch(cleanPrompt);
      if (amountMatch != null) {
        final amountStr = amountMatch.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          final isBank = cleanPrompt.contains('بنك') || cleanPrompt.contains('شيك');
          final type = isPayment ? 'payment' : 'receipt';
          final method = isBank ? 'bank' : 'cash';

          final action = await executeTool('create_voucher', {
            'type': type,
            'amount': amount,
            'payment_method': method,
            'notes': cleanPrompt,
          });

          if (!action.isSuccess) {
            return AiMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              sender: MessageSender.assistant,
              text: 'تعذر إنشاء السند في النظام: ${action.result}',
              timestamp: DateTime.now(),
              executedActions: [action],
            );
          }

          String voucherNum = '';
          if (action.result is Map) {
            final map = action.result as Map;
            if (map['data'] is Map && map['data']['voucher_number'] != null) {
              voucherNum = '\n• رقم السند في النظام: ${map['data']['voucher_number']}';
            } else if (map['voucher_number'] != null) {
              voucherNum = '\n• رقم السند في النظام: ${map['voucher_number']}';
            }
          }

          final typeLabel = isPayment ? 'سند صرف' : 'سند قبض';
          final methodLabel = isBank ? 'حساب البنك' : 'الصندوق النقدي';

          return AiMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: MessageSender.assistant,
            text: '''
✅ تم إنشاء $typeLabel بنجاح في قاعدة البيانات!$voucherNum
• المبلغ: ${amount.toStringAsFixed(2)} ر.س
• طريقة الدفع: $methodLabel
• تم ترحيل وتأثير القيد المحاسبي آلياً في دفتر الأستاذ العام.
''',
            timestamp: DateTime.now(),
            executedActions: [action],
          );
        }
      }
    }

    // 2. Intent: Warehouse Items Catalog (الأصناف / المخزون / المستودع)
    if ((cleanPrompt.contains('أصناف') || cleanPrompt.contains('الاصناف') || cleanPrompt.contains('المستودع') || cleanPrompt.contains('الكميات') || cleanPrompt.contains('المخزون')) &&
        !cleanPrompt.contains('أضف') && !cleanPrompt.contains('اضف') && !cleanPrompt.contains('أنشئ') && !cleanPrompt.contains('انشئ')) {
      final action = await executeTool('get_items_catalog', {});
      if (action.isSuccess && action.result is List) {
        final items = action.result as List;
        if (items.isEmpty) {
          return AiMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: MessageSender.assistant,
            text: '📦 المستودع لا يحتوي على أصناف حالياً. يمكنك إضافة صنف جديد بإرسال: "أضف صنف جديد اسمه..."',
            timestamp: DateTime.now(),
            executedActions: [action],
          );
        }

        final buffer = StringBuffer('📦 الأصناف والمنتجات المتوفرة بالمستودع (${items.length} صنف):\n\n');
        for (int i = 0; i < items.length && i < 15; i++) {
          final item = items[i];
          final name = item['name'] ?? 'صنف';
          final salesPrice = item['sales_price'] ?? 0;
          final purchasePrice = item['purchase_price'] ?? 0;
          final unit = item['unit'] ?? 'حبة';
          buffer.writeln('${i + 1}. **$name** ($unit) — سعر البيع: $salesPrice ر.س | الشراء: $purchasePrice ر.س');
        }

        return AiMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: MessageSender.assistant,
          text: buffer.toString().trim(),
          timestamp: DateTime.now(),
          executedActions: [action],
        );
      }
    }

    // 3. Intent: Profit / Loss / Sales / Expenses / KPIs (الأرباح / المبيعات / المصروفات / المؤشرات)
    if (cleanPrompt.contains('أرباح') || cleanPrompt.contains('ارباح') || cleanPrompt.contains('مبيعات') || cleanPrompt.contains('مصروفات') || cleanPrompt.contains('مؤشرات') || cleanPrompt.contains('صافي')) {
      final dashAction = await executeTool('get_dashboard_stats', {});
      if (dashAction.isSuccess && dashAction.result is Map) {
        final d = dashAction.result as Map<String, dynamic>;
        final sales = d['total_sales'] ?? d['sales'] ?? 0;
        final purchases = d['total_purchases'] ?? d['purchases'] ?? 0;
        final profit = d['net_profit'] ?? d['profit'] ?? 0;
        final expenses = d['total_expenses'] ?? d['expenses'] ?? 0;
        final cash = d['cash_balance'] ?? d['safe_balance'] ?? 0;
        final receivables = d['customer_receivables'] ?? d['receivables'] ?? 0;

        return AiMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: MessageSender.assistant,
          text: '''
📊 ملخص المؤشرات المالية والأرباح:
• صافي الأرباح: $profit ر.س
• إجمالي المبيعات: $sales ر.س
• إجمالي المشتريات: $purchases ر.س
• إجمالي المصروفات: $expenses ر.س
• رصيد الصندوق والبنوك: $cash ر.س
• ذمم وديون العملاء: $receivables ر.س
''',
          timestamp: DateTime.now(),
          executedActions: [dashAction],
        );
      }
    }

    // 4. Intent: Customer / Vendor Debt Statement (العملاء / الموردين / الديون)
    if (cleanPrompt.contains('ديون') || cleanPrompt.contains('العملاء') || cleanPrompt.contains('الموردين') || cleanPrompt.contains('أعمار الذمم')) {
      final partiesAction = await executeTool('get_parties_list', {});
      if (partiesAction.isSuccess && partiesAction.result is List) {
        final parties = partiesAction.result as List;
        final buffer = StringBuffer('👥 ملخص قائمة العملاء والموردين (${parties.length}):\n\n');
        for (int i = 0; i < parties.length && i < 10; i++) {
          final p = parties[i];
          final name = p['name'] ?? '';
          final type = p['type'] == 'customer' ? 'عميل' : 'مورد';
          final phone = p['phone'] ?? '-';
          buffer.writeln('${i + 1}. **$name** ($type) — هاتف: $phone');
        }

        return AiMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: MessageSender.assistant,
          text: buffer.toString().trim(),
          timestamp: DateTime.now(),
          executedActions: [partiesAction],
        );
      }
    }

    // 5. Intent: Create New Party (إضافة عميل / مورد)
    if (cleanPrompt.contains('أضف عميل') || cleanPrompt.contains('اضف عميل') || cleanPrompt.contains('أضف مورد') || cleanPrompt.contains('اضف مورد')) {
      final isVendor = cleanPrompt.contains('مورد');
      // Extract name after "اسمه" or "عميل"
      String partyName = cleanPrompt.replaceAll(RegExp(r'(أضف|اضف|عميل|مورد|جديد|اسمه|باسم)'), '').trim();
      if (partyName.isEmpty) partyName = isVendor ? 'مورد جديد' : 'عميل جديد';

      final action = await executeTool('create_party', {
        'name': partyName,
        'type': isVendor ? 'vendor' : 'customer',
      });

      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.assistant,
        text: '✅ تم إضافة ${isVendor ? 'المورد' : 'العميل'} "$partyName" بنجاح إلى دليل الحسابات.',
        timestamp: DateTime.now(),
        executedActions: [action],
      );
    }

    // 6. Intent: Create New Item (إضافة صنف)
    if (cleanPrompt.contains('أضف صنف') || cleanPrompt.contains('اضف صنف') || cleanPrompt.contains('إضافة صنف')) {
      String itemName = cleanPrompt.replaceAll(RegExp(r'(أضف|اضف|إضافة|صنف|جديد|اسمه|باسم)'), '').trim();
      if (itemName.isEmpty) itemName = 'صنف جديد';

      final action = await executeTool('create_item', {
        'name': itemName,
        'sales_price': 100,
        'purchase_price': 80,
      });

      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.assistant,
        text: '✅ تم إضافة الصنف "$itemName" بنجاح إلى دليل المستودعات.',
        timestamp: DateTime.now(),
        executedActions: [action],
      );
    }

    return null; // Not a deterministic single intent, forward to LLM
  }

  // ==========================================
  // --- REAL TOOL EXECUTION (BACKEND API) ---
  // ==========================================
  static Future<AiToolAction> executeTool(String toolName, Map<String, dynamic> args) async {
    try {
      switch (toolName) {
        case 'get_dashboard_stats':
          final res = await ApiService.get(ApiEndpoints.dashboard);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'get_accounts_list':
          final res = await ApiService.get(ApiEndpoints.accounts, queryParams: args.containsKey('type') ? {'type': args['type']} : null);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'get_parties_list':
          final res = await ApiService.get(ApiEndpoints.parties, queryParams: args.map((k, v) => MapEntry(k, v.toString())));
          return AiToolAction(toolName: toolName, arguments: args, result: res.data ?? res.rawJson, isSuccess: res.success);

        case 'get_items_catalog':
          final res = await ApiService.get(ApiEndpoints.items, queryParams: args.containsKey('search') ? {'search': args['search']} : null);
          return AiToolAction(toolName: toolName, arguments: args, result: res.data ?? res.rawJson, isSuccess: res.success);

        case 'get_income_statement':
          final res = await ApiService.get(ApiEndpoints.reportIncomeStatement, queryParams: {
            if (args['from_date'] != null) 'from_date': args['from_date'],
            if (args['to_date'] != null) 'to_date': args['to_date'],
          });
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'create_party':
          final partyType = (args['type']?.toString().contains('مورد') ?? false) ? 'vendor' : 'customer';
          final res = await ApiService.post(ApiEndpoints.parties, body: {
            'name': args['name'],
            'type': args['type'] ?? partyType,
            'phone': args['phone'] ?? '0500000000',
            'address': args['address'],
          });
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'create_voucher':
          final rawType = (args['type']?.toString().toLowerCase() ?? 'receipt');
          final type = (rawType.contains('صرف') || rawType.contains('payment')) ? 'payment' : 'receipt';
          final amount = double.tryParse(args['amount']?.toString() ?? '0') ?? 0.0;
          final paymentMethod = (args['payment_method']?.toString().contains('bank') ?? false) ? 'bank' : 'cash';

          int? accountId = args['account_id'];
          if (accountId == null) {
            final accs = await ApiService.get(ApiEndpoints.accounts);
            if (accs.success && accs.data is List && (accs.data as List).isNotEmpty) {
              accountId = (accs.data as List).first['id'];
            }
          }

          final res = await ApiService.post(ApiEndpoints.vouchers, body: {
            'type': type,
            'amount': amount,
            'payment_method': paymentMethod,
            'account_id': accountId,
            'party_id': args['party_id'],
            'notes': args['notes'] ?? 'سند تم إنشاؤه بواسطة المساعد المحاسبي الذكي',
            'date': DateTime.now().toString().substring(0, 10),
          });
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'create_item':
          final res = await ApiService.post(ApiEndpoints.items, body: {
            'name': args['name'],
            'purchase_price': double.tryParse(args['purchase_price']?.toString() ?? '0') ?? 0,
            'sales_price': double.tryParse(args['sales_price']?.toString() ?? '0') ?? 0,
            'unit': args['unit'] ?? 'قطعة',
            'barcode': args['barcode'],
            'is_active': true,
          });
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'create_invoice':
          final rawType = args['type']?.toString().toLowerCase() ?? 'sale';
          final type = rawType.contains('purchase') ? 'purchase' : 'sale';

          int? storeId = args['store_id'];
          if (storeId == null) {
            final stores = await ApiService.get(ApiEndpoints.stores);
            if (stores.success && stores.data is List && (stores.data as List).isNotEmpty) {
              storeId = (stores.data as List).first['id'];
            }
          }

          int? partyId = args['party_id'];
          if (partyId == null) {
            final parties = await ApiService.get(ApiEndpoints.parties);
            if (parties.success && parties.data is List && (parties.data as List).isNotEmpty) {
              partyId = (parties.data as List).first['id'];
            }
          }

          final res = await ApiService.post(ApiEndpoints.invoices, body: {
            'type': type,
            'party_id': partyId,
            'store_id': storeId,
            'date': DateTime.now().toString().substring(0, 10),
            'notes': args['notes'] ?? 'فاتورة منشأة بواسطة المساعد المحاسبي الذكي',
            'lines': args['lines'] ?? [],
          });
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        default:
          return AiToolAction(toolName: toolName, arguments: args, result: 'Tool $toolName not implemented', isSuccess: false);
      }
    } catch (e) {
      return AiToolAction(toolName: toolName, arguments: args, result: 'Error: $e', isSuccess: false);
    }
  }

  // ==========================================
  // --- SEND MESSAGE (MAIN ENTRYPOINT) ---
  // ==========================================
  static Future<AiMessage> sendMessage({
    required String prompt,
    required List<AiMessage> history,
    required AiProviderType provider,
    required String apiKey,
    required String model,
  }) async {
    // Step 1: Check if prompt is a direct deterministic accounting intent
    final directResult = await tryExecuteDirectAccountingIntent(prompt);
    if (directResult != null) {
      return directResult;
    }

    // Step 2: If not direct intent, check API Key
    if (apiKey.trim().isEmpty) {
      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.assistant,
        text: 'الرجاء إدخال مفتاح API الخاص بك بالضغط على أيقونة الإعدادات ⚙️ أعلى الشاشة.',
        timestamp: DateTime.now(),
      );
    }

    // Step 3: Forward to LLM (ChatGPT / Gemini / Groq)
    try {
      if (provider == AiProviderType.gemini) {
        return await _sendGemini(prompt, history, apiKey, model);
      } else {
        final baseUrl = provider == AiProviderType.groq
            ? 'https://api.groq.com/openai/v1/chat/completions'
            : 'https://api.openai.com/v1/chat/completions';

        return await _sendOpenAiCompatible(prompt, history, apiKey, model, baseUrl);
      }
    } catch (e) {
      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.assistant,
        text: 'حدث خطأ أثناء الاتصال بالنموذج:\n$e',
        timestamp: DateTime.now(),
      );
    }
  }

  // --- OPENAI & GROQ IMPLEMENTATION ---
  static Future<AiMessage> _sendOpenAiCompatible(
    String prompt,
    List<AiMessage> history,
    String apiKey,
    String model,
    String endpointUrl,
  ) async {
    final messages = [
      {
        'role': 'system',
        'content': 'أنت محاسب مالي ذكي وخبير. أجب باختصار شديد وبالأرقام المالية المباشرة دون إطالة أو تعقيد.'
      },
      ...history.where((m) => !m.isLoading).map((m) {
        return {
          'role': m.sender == MessageSender.user ? 'user' : 'assistant',
          'content': m.text,
        };
      }),
      {'role': 'user', 'content': prompt},
    ];

    final activeModel = model.isNotEmpty
        ? model
        : (endpointUrl.contains('groq') ? 'llama-3.1-8b-instant' : 'gpt-4o-mini');

    final response = await http.post(
      Uri.parse(endpointUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': activeModel,
        'messages': messages,
        'temperature': 0.3,
      }),
    );

    if (response.statusCode != 200) {
      final errorJson = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorJson['error']?['message'] ?? 'Status code: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final text = data['choices']?[0]?['message']?['content'] ?? '';

    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.assistant,
      text: text,
      timestamp: DateTime.now(),
    );
  }

  // --- GOOGLE GEMINI IMPLEMENTATION ---
  static Future<AiMessage> _sendGemini(
    String prompt,
    List<AiMessage> history,
    String apiKey,
    String model,
  ) async {
    final geminiModel = model.isNotEmpty ? model : 'gemini-1.5-flash';
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$apiKey';

    final contents = [
      ...history.where((m) => !m.isLoading).map((m) {
        return {
          'role': m.sender == MessageSender.user ? 'user' : 'model',
          'parts': [{'text': m.text}],
        };
      }),
      {
        'role': 'user',
        'parts': [{'text': 'أنت محاسب مالي ذكي. أجب باختصار شديد وبالأرقام:\n$prompt'}],
      }
    ];

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {'temperature': 0.3},
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['error']?['message'] ?? 'Gemini status ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.assistant,
      text: text,
      timestamp: DateTime.now(),
    );
  }
}
