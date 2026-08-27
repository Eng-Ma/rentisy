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

  // Dynamic Live System Prompt formatted cleanly for concise accounting answers
  static Future<String> getLiveSystemPrompt() async {
    String liveDataSummary = "لا تتوفر بيانات سريعة حالياً.";
    try {
      final dash = await ApiService.get(ApiEndpoints.dashboard);
      if (dash.success && dash.rawJson is Map) {
        final d = dash.rawJson as Map<String, dynamic>;
        final sales = d['total_sales'] ?? d['sales'] ?? 0;
        final purchases = d['total_purchases'] ?? d['purchases'] ?? 0;
        final profit = d['net_profit'] ?? d['profit'] ?? 0;
        final expenses = d['total_expenses'] ?? d['expenses'] ?? 0;
        final cash = d['cash_balance'] ?? d['safe_balance'] ?? 0;
        final receivables = d['customer_receivables'] ?? d['receivables'] ?? 0;

        liveDataSummary = '''
- صافي الأرباح: $profit ريال
- إجمالي المبيعات: $sales ريال
- إجمالي المشتريات: $purchases ريال
- إجمالي المصروفات: $expenses ريال
- رصيد النقدية والبنوك: $cash ريال
- ذمم وديون العملاء: $receivables ريال
''';
      }
    } catch (_) {}

    return '''
أنت "المحاسب الذكي لنظام الأصيل".
مهمتك: مساعدة المحاسب بإجابات مختصرة ومباشرة جداً ودقيقة وتنفيذ العمليات المالية.

المؤشرات المالية المباشرة الحالية:
$liveDataSummary

قواعد حاسمة:
1. كن فائق الإيجاز والاحترافية: أعط الأرقام والنتائج مباشرة بدون أي مقدمات إنشائية أو شروحات تقنية غير مهمة.
2. لا تطلب من المستخدم الانتظار أبداً.
3. لا تظهر أبداً كود برمجي أو أسماء دوال أو نصوص JSON في المحادثة.
4. عندما يطلب المستخدم تنفيذ عملية محاسبية، أدرج كتلة الإجراء المخفية التالية في نهاية ردك:
```action
{"tool": "create_voucher", "params": {"type": "receipt", "amount": 1500, "payment_method": "cash"}}
```

الأدوات المتاحة للتنفيذ:
- create_voucher: إنشاء سند قبض أو صرف (type: 'receipt' أو 'payment', amount: رقم, payment_method: 'cash' أو 'bank', notes: بيان)
- create_invoice: إنشاء فاتورة مبيعات أو مشتريات (type: 'sale' أو 'purchase', party_id, lines: [{item_id, quantity, unit_price}])
- create_party: إضافة عميل أو مورد (name: اسم, type: 'customer' أو 'vendor', phone: هاتف)
- create_item: إضافة صنف (name: اسم, sales_price: سعر بيع, purchase_price: سعر شراء, unit: وحدة)
''';
  }

  // Tool Definitions in JSON Schema format (Standard for OpenAI / Groq / Gemini)
  static final List<Map<String, dynamic>> toolsDefinition = [
    {
      'type': 'function',
      'function': {
        'name': 'get_dashboard_stats',
        'description': 'استرجاع ملخص مؤشرات الأداء المالي، الأرباح، إجمالي الأصول، والذمم المدينة والدائنة',
        'parameters': {
          'type': 'object',
          'properties': {},
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_accounts_list',
        'description': 'استرجاع شجرة الحسابات المالية وأرصدتها',
        'parameters': {
          'type': 'object',
          'properties': {
            'type': {'type': 'string', 'description': 'نوع الحساب اختياري (asset, liability, equity, revenue, expense)'}
          },
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_parties_list',
        'description': 'استرجاع قائمة العملاء أو الموردين وأرصدتهم',
        'parameters': {
          'type': 'object',
          'properties': {
            'type': {'type': 'string', 'description': 'نوع الطرف (customer أو vendor)'},
            'search': {'type': 'string', 'description': 'كلمة بحث بالاسم أو الهاتف'}
          },
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_items_catalog',
        'description': 'استرجاع قائمة الأصناف بالمستودع مع أسعار البيع والشراء والكميات',
        'parameters': {
          'type': 'object',
          'properties': {
            'search': {'type': 'string', 'description': 'بحث باسم الصنف أو الباركود'}
          },
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_income_statement',
        'description': 'استخراج قائمة الدخل وحساب صافي الأرباح والخسائر وإجمالي الإيرادات والمصروفات',
        'parameters': {
          'type': 'object',
          'properties': {
            'from_date': {'type': 'string', 'description': 'من تاريخ YYYY-MM-DD'},
            'to_date': {'type': 'string', 'description': 'إلى تاريخ YYYY-MM-DD'},
          },
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'create_party',
        'description': 'إنشاء عميل جديد أو مورد جديد في النظام',
        'parameters': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'description': 'اسم العميل أو المورد'},
            'type': {'type': 'string', 'enum': ['customer', 'vendor'], 'description': 'نوع الطرف'},
            'phone': {'type': 'string', 'description': 'رقم الهاتف'},
            'address': {'type': 'string', 'description': 'العنوان'},
          },
          'required': ['name', 'type'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'create_voucher',
        'description': 'إنشاء سند قبض مالي (receipt) أو سند صرف مالي (payment) وترحيل القيد آلياً',
        'parameters': {
          'type': 'object',
          'properties': {
            'type': {'type': 'string', 'enum': ['receipt', 'payment'], 'description': 'نوع السند (receipt = قبض, payment = صرف)'},
            'amount': {'type': 'number', 'description': 'مبلغ السند'},
            'payment_method': {'type': 'string', 'enum': ['cash', 'bank', 'check'], 'description': 'طريقة الدفع'},
            'party_id': {'type': 'integer', 'description': 'معرف العميل أو المورد'},
            'account_id': {'type': 'integer', 'description': 'معرف حساب الصندوق أو البنك'},
            'notes': {'type': 'string', 'description': 'بيان وملاحظات السند'},
          },
          'required': ['type', 'amount'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'create_item',
        'description': 'إضافة صنف أو منتج جديد إلى دليل المستودعات',
        'parameters': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'description': 'اسم الصنف'},
            'purchase_price': {'type': 'number', 'description': 'سعر الشراء (التكلفة)'},
            'sales_price': {'type': 'number', 'description': 'سعر البيع'},
            'unit': {'type': 'string', 'description': 'الوحدة (قطعة، حبة، كرتونة...)'},
            'barcode': {'type': 'string', 'description': 'الباركود'},
          },
          'required': ['name'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'create_invoice',
        'description': 'إنشاء فاتورة مبيعات أو مشتريات وتحديث المخزون والقيود المحاسبية تلقائياً',
        'parameters': {
          'type': 'object',
          'properties': {
            'type': {'type': 'string', 'enum': ['sale', 'purchase', 'sale_return', 'purchase_return'], 'description': 'نوع الفاتورة'},
            'party_id': {'type': 'integer', 'description': 'معرف العميل أو المورد'},
            'store_id': {'type': 'integer', 'description': 'معرف المستودع'},
            'lines': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'item_id': {'type': 'integer', 'description': 'معرف الصنف'},
                  'quantity': {'type': 'number', 'description': 'الكمية'},
                  'unit_price': {'type': 'number', 'description': 'سعر الوحدة'},
                },
                'required': ['item_id', 'quantity', 'unit_price'],
              },
            },
            'notes': {'type': 'string', 'description': 'ملاحظات الفاتورة'},
          },
          'required': ['type'],
        },
      },
    },
  ];

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
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'get_items_catalog':
          final res = await ApiService.get(ApiEndpoints.items, queryParams: args.containsKey('search') ? {'search': args['search']} : null);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

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
            'phone': args['phone'],
            'address': args['address'],
          });
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'create_voucher':
          // Normalize type & amount
          final rawType = (args['type']?.toString().toLowerCase() ?? 'receipt');
          final type = (rawType.contains('صرف') || rawType.contains('payment')) ? 'payment' : 'receipt';
          final amount = double.tryParse(args['amount']?.toString() ?? '0') ?? 0.0;
          final paymentMethod = (args['payment_method']?.toString().contains('bank') ?? false) ? 'bank' : 'cash';

          // Resolve default account if missing
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
            'notes': args['notes'] ?? 'سند تم إنشاؤه بواسطة المساعد الذكي',
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
            'notes': args['notes'] ?? 'فاتورة منشأة بواسطة المساعد الذكي',
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

  // Robust universal extractor for any JSON tool call in model text
  static Future<Map<String, dynamic>> _extractAndExecuteAnyTool(String rawText) async {
    String cleaned = rawText;
    List<AiToolAction> actions = [];

    // Regex to match JSON with "tool": "..."
    final jsonRegex = RegExp(r'\{[\s\S]*?"tool"\s*:\s*"([a-zA-Z0-9_]+)"[\s\S]*?\}');
    final match = jsonRegex.firstMatch(rawText);

    if (match != null) {
      try {
        final jsonText = match.group(0)!;
        final decoded = jsonDecode(jsonText);
        final toolName = decoded['tool']?.toString() ?? '';
        final params = (decoded['params'] as Map<String, dynamic>?) ?? {};

        if (toolName.isNotEmpty) {
          final actionResult = await executeTool(toolName, params);
          actions.add(actionResult);

          // Clean away code blocks & JSON
          cleaned = cleaned.replaceAll(match.group(0)!, '').replaceAll(RegExp(r'```action[\s\S]*?```'), '').replaceAll(RegExp(r'```[\s\S]*?```'), '').trim();

          if (cleaned.isEmpty || cleaned.length < 5) {
            cleaned = 'تم تنفيذ وترحيل العملية بنجاح في النظام المحاسبي.';
          }
        }
      } catch (_) {}
    }

    // Also strip any leftover backtick blocks
    cleaned = cleaned.replaceAll(RegExp(r'```action[\s\S]*?```'), '').trim();

    return {
      'text': cleaned,
      'actions': actions,
    };
  }

  // ==========================================
  // --- SEND MESSAGE (MULTI-PROVIDER) ---
  // ==========================================
  static Future<AiMessage> sendMessage({
    required String prompt,
    required List<AiMessage> history,
    required AiProviderType provider,
    required String apiKey,
    required String model,
  }) async {
    if (apiKey.trim().isEmpty) {
      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.assistant,
        text: 'الرجاء إدخال مفتاح API الخاص بك أولاً بالضغط على أيقونة الإعدادات ⚙️ أعلى الشاشة.',
        timestamp: DateTime.now(),
      );
    }

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
        text: 'حدث خطأ أثناء التواصل مع نموذج الذكاء الاصطناعي:\n$e',
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
    final liveSysPrompt = await getLiveSystemPrompt();
    final messages = [
      {'role': 'system', 'content': liveSysPrompt},
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

    final requestBody = {
      'model': activeModel,
      'messages': messages,
      'tools': toolsDefinition,
      'tool_choice': 'auto',
      'temperature': 0.2,
    };

    var response = await http.post(
      Uri.parse(endpointUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    );

    // If tool calling is not supported on this model, retry automatically without tools
    if (response.statusCode != 200) {
      final errorJson = jsonDecode(utf8.decode(response.bodyBytes));
      final errorMsg = (errorJson['error']?['message'] ?? '').toString().toLowerCase();

      if (errorMsg.contains('tool') || errorMsg.contains('function') || errorMsg.contains('not supported')) {
        final fallbackBody = {
          'model': activeModel,
          'messages': messages,
          'temperature': 0.2,
        };
        response = await http.post(
          Uri.parse(endpointUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(fallbackBody),
        );
      }
    }

    if (response.statusCode != 200) {
      final errorJson = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorJson['error']?['message'] ?? 'Status code: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final choice = data['choices']?[0];
    final message = choice?['message'];

    final toolCalls = message?['tool_calls'] as List?;
    List<AiToolAction> executedActions = [];

    // If Model decided to call tools natively:
    if (toolCalls != null && toolCalls.isNotEmpty) {
      for (var toolCall in toolCalls) {
        final toolName = toolCall['function']['name'];
        final arguments = jsonDecode(toolCall['function']['arguments'] ?? '{}');
        final actionResult = await executeTool(toolName, arguments);
        executedActions.add(actionResult);
      }

      String summaryText = 'تم تنفيذ العملية المحاسبية وتحديث القيود بنجاح.';
      if (toolCalls.first['function']['name'] == 'create_voucher') {
        summaryText = 'تم إنشاء سند القبض/الصرف بنجاح وترحيل القيد المحاسبي.';
      } else if (toolCalls.first['function']['name'] == 'create_invoice') {
        summaryText = 'تم إنشاء الفاتورة وتحديث المخزون والقيود المحاسبية بنجاح.';
      }

      return AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.assistant,
        text: summaryText,
        timestamp: DateTime.now(),
        executedActions: executedActions,
      );
    }

    String rawText = message?['content'] ?? '';
    final extracted = await _extractAndExecuteAnyTool(rawText);

    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.assistant,
      text: extracted['text'],
      timestamp: DateTime.now(),
      executedActions: (extracted['actions'] as List<AiToolAction>).isNotEmpty
          ? (extracted['actions'] as List<AiToolAction>)
          : null,
    );
  }

  // --- GOOGLE GEMINI IMPLEMENTATION ---
  static Future<AiMessage> _sendGemini(
    String prompt,
    List<AiMessage> history,
    String apiKey,
    String model,
  ) async {
    final liveSysPrompt = await getLiveSystemPrompt();
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
        'parts': [{'text': '$liveSysPrompt\n\nطلب المستخدم:\n$prompt'}],
      }
    ];

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.2,
        },
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['error']?['message'] ?? 'Gemini status ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    String rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
    final extracted = await _extractAndExecuteAnyTool(rawText);

    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.assistant,
      text: extracted['text'],
      timestamp: DateTime.now(),
      executedActions: (extracted['actions'] as List<AiToolAction>).isNotEmpty
          ? (extracted['actions'] as List<AiToolAction>)
          : null,
    );
  }
}
