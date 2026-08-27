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

  // System Prompt explaining the accounting context and available ERP functions
  static const String systemPrompt = '''
أنت "مساعد الأصيل الذكي المحاسبي" (Al-Aseel AI Accounting Agent) - وكيل ذكاء اصطناعي خبير في إدارة نظام المحاسبة والمستودعات.
يمكنك مساعدة المستخدم في الاستعلام عن التقارير المالية وتنفيذ المهام المحاسبية الفعلية مثل:
1. إنشاء فواتير المبيعات والمشتريات (create_invoice)
2. إنشاء سندات القبض والصرف (create_voucher)
3. تسجيل قيود اليومية العامة (create_journal_entry)
4. إضافة العملاء والموردين (create_party)
5. إضافة أصناف جديدة للمستودع (create_item)
6. الاستعلام عن ميزان المراجعة وقائمة الدخل والأرباح وأرصدة الحسابات ومراكز التكلفة وحافظة الشيكات (get_reports / get_dashboard / get_accounts / get_items / get_parties).

عندما يطلب المستخدم تنفيذ عملية أو استعلام مالي، استخدم الأدوات المتاحة (Tool Calling) لتنفيذها والرد ببيان واضح ومنسق باللغة العربية مع الأرقام والمبالغ.
''';

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
          final res = await ApiService.post(ApiEndpoints.parties, body: args);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'create_voucher':
          // Fill default account if missing
          if (!args.containsKey('account_id')) {
            final accs = await ApiService.get(ApiEndpoints.accounts);
            if (accs.success && accs.data is List && (accs.data as List).isNotEmpty) {
              args['account_id'] = (accs.data as List).first['id'];
            }
          }
          final res = await ApiService.post(ApiEndpoints.vouchers, body: {
            'type': args['type'] ?? 'receipt',
            'amount': args['amount'],
            'payment_method': args['payment_method'] ?? 'cash',
            'account_id': args['account_id'],
            'party_id': args['party_id'],
            'notes': args['notes'] ?? 'تم الإنشاء بواسطة المساعد الذكي',
            'date': DateTime.now().toString().substring(0, 10),
          });
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'create_item':
          final res = await ApiService.post(ApiEndpoints.items, body: {
            'name': args['name'],
            'purchase_price': args['purchase_price'] ?? 0,
            'sales_price': args['sales_price'] ?? 0,
            'unit': args['unit'] ?? 'قطعة',
            'barcode': args['barcode'],
            'is_active': true,
          });
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'create_invoice':
          // Auto resolve store and party if needed
          if (!args.containsKey('store_id')) {
            final stores = await ApiService.get(ApiEndpoints.stores);
            if (stores.success && stores.data is List && (stores.data as List).isNotEmpty) {
              args['store_id'] = (stores.data as List).first['id'];
            }
          }
          if (!args.containsKey('party_id')) {
            final parties = await ApiService.get(ApiEndpoints.parties);
            if (parties.success && parties.data is List && (parties.data as List).isNotEmpty) {
              args['party_id'] = (parties.data as List).first['id'];
            }
          }
          final res = await ApiService.post(ApiEndpoints.invoices, body: {
            'type': args['type'] ?? 'sale',
            'party_id': args['party_id'],
            'store_id': args['store_id'],
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
        // OpenAI or Groq (OpenAI Compatible)
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
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history.where((m) => !m.isLoading).map((m) {
        return {
          'role': m.sender == MessageSender.user ? 'user' : 'assistant',
          'content': m.text,
        };
      }),
      {'role': 'user', 'content': prompt},
    ];

    final requestBody = {
      'model': model.isNotEmpty ? model : (endpointUrl.contains('groq') ? 'llama-3.3-70b-versatile' : 'gpt-4o-mini'),
      'messages': messages,
      'tools': toolsDefinition,
      'tool_choice': 'auto',
      'temperature': 0.3,
    };

    final response = await http.post(
      Uri.parse(endpointUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      final errorJson = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorJson['error']?['message'] ?? 'Status code: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final choice = data['choices']?[0];
    final message = choice?['message'];

    final toolCalls = message?['tool_calls'] as List?;
    List<AiToolAction> executedActions = [];

    // If Model decided to call tools:
    if (toolCalls != null && toolCalls.isNotEmpty) {
      final List<Map<String, dynamic>> toolMessages = [
        ...messages,
        message, // Include assistant tool call request
      ];

      for (var toolCall in toolCalls) {
        final toolName = toolCall['function']['name'];
        final arguments = jsonDecode(toolCall['function']['arguments'] ?? '{}');

        // Execute Tool in ERP
        final actionResult = await executeTool(toolName, arguments);
        executedActions.add(actionResult);

        toolMessages.add({
          'role': 'tool',
          'tool_call_id': toolCall['id'],
          'name': toolName,
          'content': jsonEncode(actionResult.result),
        });
      }

      // Send tool results back to LLM to summarize response in Arabic
      final followUpResponse = await http.post(
        Uri.parse(endpointUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model.isNotEmpty ? model : (endpointUrl.contains('groq') ? 'llama-3.3-70b-versatile' : 'gpt-4o-mini'),
          'messages': toolMessages,
          'temperature': 0.3,
        }),
      );

      if (followUpResponse.statusCode == 200) {
        final followUpData = jsonDecode(utf8.decode(followUpResponse.bodyBytes));
        final finalContent = followUpData['choices']?[0]?['message']?['content'] ?? '';

        return AiMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: MessageSender.assistant,
          text: finalContent,
          timestamp: DateTime.now(),
          executedActions: executedActions,
        );
      }
    }

    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.assistant,
      text: message?['content'] ?? '',
      timestamp: DateTime.now(),
      executedActions: executedActions.isNotEmpty ? executedActions : null,
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
        'parts': [{'text': '$systemPrompt\n\nطلب المستخدم:\n$prompt'}],
      }
    ];

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.3,
        },
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
