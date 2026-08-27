import 'dart:async';
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

  // Fetch Live Database System Context for LLMs
  static Future<String> _getLiveDatabaseContext() async {
    try {
      final dashRes = await ApiService.get(ApiEndpoints.dashboard);
      if (dashRes.success && dashRes.rawJson is Map) {
        final d = dashRes.rawJson as Map<String, dynamic>;
        final sales = d['total_sales'] ?? d['sales'] ?? 0;
        final purchases = d['total_purchases'] ?? d['purchases'] ?? 0;
        final profit = d['net_profit'] ?? d['profit'] ?? 0;
        final expenses = d['total_expenses'] ?? d['expenses'] ?? 0;
        final cash = d['cash_balance'] ?? d['safe_balance'] ?? 0;
        final receivables = d['customer_receivables'] ?? d['receivables'] ?? 0;
        final invCount = d['total_invoices_count'] ?? 0;
        final vouchCount = d['total_vouchers_count'] ?? 0;

        return '''
أنت المحاسب المالي الذكي وخبير ERP لنظام المحاسبة وإدارة المستودعات.
أنت متصل بالفعل بقاعدة بيانات النظام الحقيقية ولديك كافة الصلاحيات لقراءتها والتعديل عليها.
لا تخبر المستخدم أبداً أنك لا تملك صلاحية أو تطلب منه مفاتيح للوصول إلى قاعدة البيانات.

البيانات المالية الحقيقية اللحظية للنظام الآن:
- صافي الأرباح: $profit ر.س
- إجمالي المبيعات: $sales ر.س
- إجمالي المشتريات: $purchases ر.س
- إجمالي المصروفات: $expenses ر.س
- رصيد الصندوق والبنوك: $cash ر.س
- ذمم وديون العملاء: $receivables ر.س
- إجمالي الفواتير: $invCount | إجمالي السندات: $vouchCount

أجب باختصار شديد، باللغة العربية، وبالأرقام المالية المباشرة والواضحة.
''';
      }
    } catch (_) {}

    return 'أنت محاسب مالي ذكي وخبير في النظام. أجب باختصار شديد وبالأرقام المالية المباشرة.';
  }

  // =========================================================================
  // --- REAL-TIME STREAMING ENTRYPOINT ---
  // =========================================================================
  static Future<void> sendMessageStream({
    required String prompt,
    required List<AiMessage> history,
    required AiProviderType provider,
    required String apiKey,
    required String model,
    required Function(String chunk, {List<AiToolAction>? actions, bool isDone}) onChunk,
  }) async {
    // 1. Direct Deterministic Intent & SQL Engine
    final directResult = await tryExecuteDirectAccountingIntent(prompt);
    if (directResult != null) {
      final fullText = directResult.text;
      final words = fullText.split(' ');
      for (int i = 0; i < words.length; i++) {
        final isLast = i == words.length - 1;
        onChunk(
          words[i] + (isLast ? '' : ' '),
          actions: isLast ? directResult.executedActions : null,
          isDone: isLast,
        );
        await Future.delayed(const Duration(milliseconds: 16));
      }
      return;
    }

    // 2. If prompt asks for database/data, give live DB overview even without key
    final p = prompt.trim();
    if (p.contains('بيانات') || p.contains('بياناتي') || p.contains('قاعدة البيانات') || p.contains('معلومات') || p.contains('أرصدتي') || p.contains('تقرير')) {
      final dashAction = await executeTool('get_dashboard_stats', {});
      if (dashAction.isSuccess && dashAction.result is Map) {
        final d = dashAction.result as Map<String, dynamic>;
        final sales = d['total_sales'] ?? d['sales'] ?? 0;
        final purchases = d['total_purchases'] ?? d['purchases'] ?? 0;
        final profit = d['net_profit'] ?? d['profit'] ?? 0;
        final expenses = d['total_expenses'] ?? d['expenses'] ?? 0;
        final cash = d['cash_balance'] ?? d['safe_balance'] ?? 0;
        final receivables = d['customer_receivables'] ?? d['receivables'] ?? 0;

        final fullText = '''
📊 إليك بياناتك المالية الحقيقية المستخرجة مباشرة من قاعدة البيانات:
• صافي الأرباح: $profit ر.س
• إجمالي المبيعات: $sales ر.س
• إجمالي المشتريات: $purchases ر.س
• إجمالي المصروفات: $expenses ر.س
• رصيد الصندوق والبنوك: $cash ر.س
• ذمم وديون العملاء: $receivables ر.س

(جميع البيانات أعلاه حية ومحدثة من قيود وفواتير النظام الحقيقية).
''';
        final words = fullText.split(' ');
        for (int i = 0; i < words.length; i++) {
          final isLast = i == words.length - 1;
          onChunk(words[i] + (isLast ? '' : ' '), actions: isLast ? [dashAction] : null, isDone: isLast);
          await Future.delayed(const Duration(milliseconds: 16));
        }
        return;
      }
    }

    // 3. If conversational question and API key is missing
    if (apiKey.trim().isEmpty) {
      final fullText = 'الرجاء إدخال مفتاح API الخاص بك بالضغط على أيقونة الإعدادات ⚙️ أعلى الشاشة لتمكين النماذج الذكية (ChatGPT, Gemini, Groq) من إجراء المحادثات المتقدمة.';
      final words = fullText.split(' ');
      for (int i = 0; i < words.length; i++) {
        final isLast = i == words.length - 1;
        onChunk(words[i] + (isLast ? '' : ' '), isDone: isLast);
        await Future.delayed(const Duration(milliseconds: 16));
      }
      return;
    }

    // 4. Stream from LLM Provider with Live DB Context Injected
    try {
      final systemPrompt = await _getLiveDatabaseContext();
      if (provider == AiProviderType.gemini) {
        await _streamGemini(prompt, history, apiKey, model, systemPrompt, onChunk);
      } else {
        final baseUrl = provider == AiProviderType.groq
            ? 'https://api.groq.com/openai/v1/chat/completions'
            : 'https://api.openai.com/v1/chat/completions';
        await _streamOpenAiCompatible(prompt, history, apiKey, model, baseUrl, systemPrompt, onChunk);
      }
    } catch (e) {
      onChunk('\n\nحدث خطأ أثناء البث المباشر:\n$e', isDone: true);
    }
  }

  // --- OPENAI & GROQ REAL-TIME STREAMING ---
  static Future<void> _streamOpenAiCompatible(
    String prompt,
    List<AiMessage> history,
    String apiKey,
    String model,
    String endpointUrl,
    String systemPrompt,
    Function(String chunk, {List<AiToolAction>? actions, bool isDone}) onChunk,
  ) async {
    final client = http.Client();
    try {
      final activeModel = model.isNotEmpty
          ? model
          : (endpointUrl.contains('groq') ? 'llama-3.1-8b-instant' : 'gpt-4o-mini');

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

      final request = http.Request('POST', Uri.parse(endpointUrl))
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'Accept': 'text/event-stream',
        })
        ..body = jsonEncode({
          'model': activeModel,
          'messages': messages,
          'temperature': 0.3,
          'stream': true,
        });

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final bytes = await response.stream.toBytes();
        final err = utf8.decode(bytes);
        throw Exception(err);
      }

      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed == 'data: [DONE]') {
          onChunk('', isDone: true);
          break;
        }

        if (trimmed.startsWith('data: ')) {
          final jsonStr = trimmed.substring(6).trim();
          try {
            final data = jsonDecode(jsonStr);
            final delta = data['choices']?[0]?['delta']?['content']?.toString() ?? '';
            if (delta.isNotEmpty) {
              onChunk(delta, isDone: false);
            }
          } catch (_) {}
        }
      }
      onChunk('', isDone: true);
    } finally {
      client.close();
    }
  }

  // --- GOOGLE GEMINI REAL-TIME STREAMING ---
  static Future<void> _streamGemini(
    String prompt,
    List<AiMessage> history,
    String apiKey,
    String model,
    String systemPrompt,
    Function(String chunk, {List<AiToolAction>? actions, bool isDone}) onChunk,
  ) async {
    final client = http.Client();
    try {
      final geminiModel = model.isNotEmpty ? model : 'gemini-1.5-flash';
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:streamGenerateContent?alt=sse&key=$apiKey';

      final contents = [
        ...history.where((m) => !m.isLoading).map((m) {
          return {
            'role': m.sender == MessageSender.user ? 'user' : 'model',
            'parts': [{'text': m.text}],
          };
        }),
        {
          'role': 'user',
          'parts': [{'text': '$systemPrompt\n\nسؤال المستخدم:\n$prompt'}],
        }
      ];

      final request = http.Request('POST', Uri.parse(url))
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        })
        ..body = jsonEncode({
          'contents': contents,
          'generationConfig': {'temperature': 0.3},
        });

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final bytes = await response.stream.toBytes();
        final err = utf8.decode(bytes);
        throw Exception(err);
      }

      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith('data: ')) {
          final jsonStr = trimmed.substring(6).trim();
          try {
            final data = jsonDecode(jsonStr);
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final parts = candidates[0]?['content']?['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                final delta = parts[0]?['text']?.toString() ?? '';
                if (delta.isNotEmpty) {
                  onChunk(delta, isDone: false);
                }
              }
            }
          } catch (_) {}
        }
      }
      onChunk('', isDone: true);
    } finally {
      client.close();
    }
  }

  // =========================================================================
  // --- COMPLETE DETERMINISTIC ERP & DIRECT SQL DATABASE ENGINE ---
  // =========================================================================
  static Future<AiMessage?> tryExecuteDirectAccountingIntent(String prompt) async {
    final p = prompt.trim();
    final upper = p.toUpperCase();

    // -------------------------------------------------------------
    // 0. DIRECT RAW SQL EXECUTION (SELECT / UPDATE / INSERT / DELETE)
    // -------------------------------------------------------------
    if (upper.startsWith('SELECT ') || upper.startsWith('PRAGMA ') || upper.startsWith('SHOW ') || upper.startsWith('UPDATE ') || upper.startsWith('INSERT ') || upper.startsWith('DELETE FROM')) {
      final action = await executeTool('execute_sql_query', {'query': p});
      if (action.isSuccess && action.result is Map) {
        final res = action.result as Map;
        if (res['type'] == 'read' && res['data'] is List) {
          final rows = res['data'] as List;
          if (rows.isEmpty) {
            return _msg('🔍 تم تنفيذ الاستعلام بنجاح. النتيجة: 0 سجلات (لا توجد بيانات مطابقة).', [action]);
          }
          final buf = StringBuffer('⚡ نتيجة استعلام قاعدة البيانات المباشر (${rows.length} سجل):\n\n');
          for (int i = 0; i < rows.length && i < 20; i++) {
            final row = rows[i];
            buf.writeln('${i + 1}. $row');
          }
          return _msg(buf.toString().trim(), [action]);
        } else {
          return _msg('✅ ${res['message'] ?? 'تم تنفيذ استعلام SQL بنجاح.'}', [action]);
        }
      } else {
        return _msg('تعذر تنفيذ الاستعلام: ${action.result}', [action]);
      }
    }

    // -------------------------------------------------------------
    // 0.1 DATABASE SCHEMA INSPECTOR (فحص هيكلية قاعدة البيانات وجداولها)
    // -------------------------------------------------------------
    if (p.contains('هيكلية قاعدة البيانات') || p.contains('جداول قاعدة البيانات') || p.contains('فحص قاعدة البيانات') || p.contains('database schema') || p.contains('tables')) {
      final action = await executeTool('get_database_schema', {});
      if (action.isSuccess && action.result is Map) {
        final tables = (action.result['tables'] as Map?) ?? {};
        final driver = action.result['driver'] ?? 'Database';
        final buf = StringBuffer('🗄️ هيكلية قاعدة البيانات المباشرة ($driver) — عدد الجداول: ${tables.length}:\n\n');
        tables.forEach((tableName, info) {
          final count = info['row_count'] ?? 0;
          final cols = (info['columns'] as List?)?.map((c) => c['name']).join(', ') ?? '';
          buf.writeln('• جدول **`$tableName`** ($count سجل) ➔ أعمدة: `$cols`');
        });
        return _msg(buf.toString().trim(), [action]);
      }
    }

    // -------------------------------------------------------------
    // 0.2 GLOBAL UNIVERSAL DATABASE SEARCH (بحث شامل في كل الجداول)
    // -------------------------------------------------------------
    if (p.startsWith('ابحث في قاعدة البيانات عن') || p.startsWith('ابحث في كل الجداول عن') || p.startsWith('بحث شامل عن')) {
      final term = p.replaceAll(RegExp(r'(ابحث في قاعدة البيانات عن|ابحث في كل الجداول عن|بحث شامل عن|ابحث عن|بحث عن)'), '').trim();
      final action = await executeTool('global_database_search', {'q': term});
      if (action.isSuccess && action.result is Map) {
        final res = action.result['results'] as Map? ?? {};
        if (res.isEmpty) return _msg('🔍 لم يتم العثور على أي نتائج لكلمة "$term" في أي جدول بقاعدة البيانات.', [action]);
        final buf = StringBuffer('🔍 نتائج البحث الشامل في قاعدة البيانات عن "$term":\n\n');
        res.forEach((table, records) {
          buf.writeln('📂 **جدول $table** (${(records as List).length} نتيجة):');
          for (final r in records) {
            buf.writeln('  • ${r.toString()}');
          }
          buf.writeln();
        });
        return _msg(buf.toString().trim(), [action]);
      }
    }

    // Helper: Extract ID numbers (e.g. "رقم 5", "#5", "5")
    int? extractId() {
      final match = RegExp(r'(?:رقم|id|#)\s*(\d+)').firstMatch(p) ?? RegExp(r'(\d+)').firstMatch(p);
      if (match != null) return int.tryParse(match.group(1)!);
      return null;
    }

    // Helper: Extract Amount
    double? extractAmount() {
      final match = RegExp(r'(\d+[\d\.,]*)').firstMatch(p);
      if (match != null) {
        return double.tryParse(match.group(1)!.replaceAll(',', ''));
      }
      return null;
    }

    // -------------------------------------------------------------
    // 1. DELETE ACTIONS (حذف أي عنصر من الـ 12 شاشة)
    // -------------------------------------------------------------
    if (p.contains('احذف') || p.contains('حذف') || p.contains('مسح')) {
      final id = extractId();
      if (id != null) {
        if (p.contains('سند')) {
          final action = await executeTool('delete_voucher', {'id': id});
          return _resultMsg('تم حذف السند #$id وإلغاء قيوده بنجاح.', action);
        }
        if (p.contains('فاتورة') || p.contains('فاتوره')) {
          final action = await executeTool('delete_invoice', {'id': id});
          return _resultMsg('تم حذف الفاتورة #$id وإرجاع المخزون والقيود بنجاح.', action);
        }
        if (p.contains('قيد')) {
          final action = await executeTool('delete_journal_entry', {'id': id});
          return _resultMsg('تم حذف قيد اليومية #$id بنجاح.', action);
        }
        if (p.contains('شيك')) {
          final action = await executeTool('delete_check', {'id': id});
          return _resultMsg('تم حذف الشيك #$id من الحافظة بنجاح.', action);
        }
        if (p.contains('عرض سعر') || p.contains('عرض السعر')) {
          final action = await executeTool('delete_quotation', {'id': id});
          return _resultMsg('تم حذف عرض السعر #$id بنجاح.', action);
        }
        if (p.contains('صنف') || p.contains('منتج')) {
          final action = await executeTool('delete_item', {'id': id});
          return _resultMsg('تم حذف الصنف #$id من المستودع بنجاح.', action);
        }
        if (p.contains('عميل') || p.contains('مورد') || p.contains('طرف')) {
          final action = await executeTool('delete_party', {'id': id});
          return _resultMsg('تم حذف العميل/المورد #$id بنجاح.', action);
        }
        if (p.contains('حساب')) {
          final action = await executeTool('delete_account', {'id': id});
          return _resultMsg('تم حذف الحساب #$id من شجرة الحسابات بنجاح.', action);
        }
        if (p.contains('أصل') || p.contains('اصل')) {
          final action = await executeTool('delete_fixed_asset', {'id': id});
          return _resultMsg('تم حذف الأصل الثابت #$id بنجاح.', action);
        }
        if (p.contains('مركز تكلفة') || p.contains('مركز التكلفة')) {
          final action = await executeTool('delete_cost_center', {'id': id});
          return _resultMsg('تم حذف مركز التكلفة #$id بنجاح.', action);
        }
        if (p.contains('مناقلة') || p.contains('مناقله')) {
          final action = await executeTool('delete_stock_transfer', {'id': id});
          return _resultMsg('تم حذف مناقلة المخزون #$id بنجاح.', action);
        }
      }
    }

    // -------------------------------------------------------------
    // 2. CHECKS LIFECYCLE (تحصيل، إيداع، إرجاع الشيكات)
    // -------------------------------------------------------------
    if (p.contains('شيك') && (p.contains('حصل') || p.contains('تحصيل') || p.contains('اودع') || p.contains('إيداع') || p.contains('ارجع') || p.contains('ارتجاع') || p.contains('حالة'))) {
      final id = extractId();
      if (id != null) {
        String status = 'collected';
        if (p.contains('اودع') || p.contains('إيداع') || p.contains('بنك')) status = 'deposited';
        if (p.contains('ارجع') || p.contains('مرتجع') || p.contains('ارتجاع')) status = 'bounced';
        if (p.contains('جير') || p.contains('تجيير')) status = 'endorsed';
        if (p.contains('الغ') || p.contains('إلغاء')) status = 'cancelled';

        final action = await executeTool('update_check_status', {'id': id, 'status': status});
        return _resultMsg('تم تحديث حالة الشيك #$id إلى ($status) وترحيل قيوده آلياً.', action);
      }
    }

    // -------------------------------------------------------------
    // 3. QUOTATIONS CONVERSION (تحويل عرض سعر إلى فاتورة)
    // -------------------------------------------------------------
    if ((p.contains('عرض سعر') || p.contains('عرض السعر')) && (p.contains('حول') || p.contains('تحويل') || p.contains('فاتورة'))) {
      final id = extractId();
      if (id != null) {
        final action = await executeTool('convert_quotation', {'id': id});
        return _resultMsg('✅ تم تحويل عرض السعر #$id إلى فاتورة مبيعات معتمدة وترحيل المخزون.', action);
      }
    }

    // -------------------------------------------------------------
    // 4. FIXED ASSETS DEPRECIATION (إهلاك الأصول الثابتة)
    // -------------------------------------------------------------
    if ((p.contains('أصل') || p.contains('اصل') || p.contains('الأصول')) && (p.contains('اهلك') || p.contains('إهلاك') || p.contains('اهلاك') || p.contains('حساب الإهلاك'))) {
      final id = extractId();
      if (id != null) {
        final action = await executeTool('depreciate_fixed_asset', {'id': id});
        return _resultMsg('✅ تم احتساب إهلاك الأصل #$id وتوليد قيد الإهلاك المحاسبي بنجاح.', action);
      }
    }

    // -------------------------------------------------------------
    // 5. VOUCHERS CREATION (إنشاء سند قبض / سند صرف)
    // -------------------------------------------------------------
    if (p.contains('سند قبض') || p.contains('سند صرف') || (p.contains('سند') && (p.contains('قبض') || p.contains('صرف')))) {
      final isPayment = p.contains('صرف');
      final amount = extractAmount();
      if (amount != null && amount > 0) {
        final isBank = p.contains('بنك') || p.contains('شيك');
        final type = isPayment ? 'payment' : 'receipt';
        final method = isBank ? 'bank' : 'cash';

        final action = await executeTool('create_voucher', {
          'type': type,
          'amount': amount,
          'payment_method': method,
          'notes': p,
        });

        String voucherNum = '';
        if (action.result is Map) {
          final m = action.result as Map;
          if (m['data'] is Map && m['data']['voucher_number'] != null) {
            voucherNum = ' (رقم السند: ${m['data']['voucher_number']})';
          }
        }

        final label = isPayment ? 'سند صرف' : 'سند قبض';
        final box = isBank ? 'البنك' : 'الصندوق النقدي';
        return _resultMsg('✅ تم إنشاء $label بمبلغ ${amount.toStringAsFixed(2)} ر.س من حساب $box وترحيل القيد المحاسبي بنجاح.$voucherNum', action);
      }
    }

    // -------------------------------------------------------------
    // 6. INVOICES CREATION (إنشاء فاتورة مبيعات / مشتريات)
    // -------------------------------------------------------------
    if ((p.contains('فاتورة') || p.contains('فاتوره')) && (p.contains('أنشئ') || p.contains('انشئ') || p.contains('أضف') || p.contains('سجل') || p.contains('جديدة'))) {
      final isPurchase = p.contains('شراء') || p.contains('مشتريات');
      final type = isPurchase ? 'purchase' : 'sale';

      final action = await executeTool('create_invoice', {
        'type': type,
        'notes': p,
      });

      final typeText = isPurchase ? 'مشتريات' : 'مبيعات';
      return _resultMsg('✅ تم إنشاء فاتورة $typeText جديدة وتحديث أرصدة المخازن والقيود المحاسبية بنجاح.', action);
    }

    // -------------------------------------------------------------
    // 7. PARTIES CREATION (إضافة عميل أو مورد)
    // -------------------------------------------------------------
    if ((p.contains('عميل') || p.contains('مورد')) && (p.contains('أضف') || p.contains('اضف') || p.contains('إضافة') || p.contains('سجل') || p.contains('جديد'))) {
      final isVendor = p.contains('مورد');
      String name = p.replaceAll(RegExp(r'(أضف|اضف|إضافة|سجل|عميل|مورد|جديد|اسمه|باسم|شركة|مؤسسة)'), '').trim();
      if (name.isEmpty) name = isVendor ? 'مورد جديد' : 'عميل جديد';

      final action = await executeTool('create_party', {
        'name': name,
        'type': isVendor ? 'vendor' : 'customer',
      });

      return _resultMsg('✅ تم إضافة ${isVendor ? 'المورد' : 'العميل'} "$name" بنجاح إلى النظام.', action);
    }

    // -------------------------------------------------------------
    // 8. ITEMS CREATION (إضافة صنف بالمستودع)
    // -------------------------------------------------------------
    if ((p.contains('صنف') || p.contains('منتج')) && (p.contains('أضف') || p.contains('اضف') || p.contains('إضافة') || p.contains('سجل') || p.contains('جديد'))) {
      String name = p.replaceAll(RegExp(r'(أضف|اضف|إضافة|سجل|صنف|منتج|جديد|اسمه|باسم)'), '').trim();
      if (name.isEmpty) name = 'صنف جديد';

      final action = await executeTool('create_item', {
        'name': name,
        'sales_price': extractAmount() ?? 100.0,
        'purchase_price': (extractAmount() ?? 100.0) * 0.8,
      });

      return _resultMsg('✅ تم إضافة الصنف "$name" إلى دليل المستودعات بنجاح.', action);
    }

    // -------------------------------------------------------------
    // 9. COST CENTERS & FIXED ASSETS CREATION
    // -------------------------------------------------------------
    if (p.contains('مركز تكلفة') && (p.contains('أضف') || p.contains('اضف') || p.contains('جديد'))) {
      String name = p.replaceAll(RegExp(r'(أضف|اضف|مركز|تكلفة|التكلفة|جديد|اسمه)'), '').trim();
      final action = await executeTool('create_cost_center', {'name': name.isEmpty ? 'مشروع جديد' : name});
      return _resultMsg('✅ تم إنشاء مركز التكلفة "$name" بنجاح.', action);
    }

    if (p.contains('أصل') && (p.contains('أضف') || p.contains('اضف') || p.contains('جديد'))) {
      String name = p.replaceAll(RegExp(r'(أضف|اضف|أصل|ثابت|جديد|اسمه)'), '').trim();
      final action = await executeTool('create_fixed_asset', {
        'name': name.isEmpty ? 'أصل رأسمالي جديد' : name,
        'purchase_cost': extractAmount() ?? 5000.0,
        'useful_life_years': 5,
      });
      return _resultMsg('✅ تم تسجيل الأصل الثابت "$name" في السجل العام بنجاح.', action);
    }

    // -------------------------------------------------------------
    // 10. ADVANCED SEARCH & FILTERING & QUERIES (فحص واستعلام وفلترة)
    // -------------------------------------------------------------

    // A. Warehouse Items Search & Filter
    if (p.contains('أصناف') || p.contains('الاصناف') || p.contains('المستودع') || p.contains('الكميات') || p.contains('المخزون')) {
      final action = await executeTool('get_items_catalog', {'search': p.replaceAll(RegExp(r'(أصناف|الاصناف|المستودع|الكميات|المخزون|ابحث|عن|اعرض|فحص|فلتر)'), '').trim()});
      if (action.isSuccess && action.result is List) {
        final items = action.result as List;
        if (items.isEmpty) return _msg('📦 لم يتم العثور على أصناف مطابقة للبحث بالمستودع.', [action]);
        final buf = StringBuffer('📦 قائمة الأصناف المتوفرة بالمستودع (${items.length} صنف):\n\n');
        for (int i = 0; i < items.length && i < 15; i++) {
          final it = items[i];
          buf.writeln('${i + 1}. **${it['name']}** (${it['unit'] ?? 'حبة'}) — سعر البيع: ${it['sales_price']} ر.س | التكلفة: ${it['purchase_price']} ر.س');
        }
        return _msg(buf.toString().trim(), [action]);
      }
    }

    // B. Customers & Vendors Search & Filter
    if (p.contains('عملاء') || p.contains('موردين') || p.contains('العملاء') || p.contains('الموردين') || p.contains('ديون') || p.contains('ذمم')) {
      final action = await executeTool('get_parties_list', {'search': p.replaceAll(RegExp(r'(عملاء|موردين|العملاء|الموردين|ديون|ذمم|ابحث|عن|اعرض|فحص|فلتر)'), '').trim()});
      if (action.isSuccess && action.result is List) {
        final parties = action.result as List;
        if (parties.isEmpty) return _msg('👥 لم يتم العثور على أطراف مطابقة للبحث.', [action]);
        final buf = StringBuffer('👥 قائمة العملاء والموردين (${parties.length}):\n\n');
        for (int i = 0; i < parties.length && i < 12; i++) {
          final pt = parties[i];
          final type = pt['type'] == 'customer' ? 'عميل' : 'مورد';
          buf.writeln('${i + 1}. **${pt['name']}** ($type) — هاتف: ${pt['phone'] ?? '-'}');
        }
        return _msg(buf.toString().trim(), [action]);
      }
    }

    // C. Checks Portfolio Search & Filter
    if (p.contains('شيكات') || p.contains('الشيكات') || p.contains('حافظة الشيكات')) {
      final action = await executeTool('get_checks_list', {});
      if (action.isSuccess && action.result is List) {
        final checks = action.result as List;
        if (checks.isEmpty) return _msg('📑 حافظة الشيكات فارغة حالياً.', [action]);
        final buf = StringBuffer('📑 حافظة الشيكات المسجلة (${checks.length} شيك):\n\n');
        for (int i = 0; i < checks.length && i < 10; i++) {
          final chk = checks[i];
          final type = chk['type'] == 'received' ? 'وارد' : 'صادر';
          buf.writeln('${i + 1}. شيك رقم **${chk['check_number']}** ($type) — مبلغ: ${chk['amount']} ر.س | حالة: ${chk['status']}');
        }
        return _msg(buf.toString().trim(), [action]);
      }
    }

    // D. Chart of Accounts Tree (شجرة الحسابات)
    if (p.contains('شجرة الحسابات') || p.contains('الحسابات') || p.contains('دليل الحسابات')) {
      final action = await executeTool('get_accounts_list', {});
      if (action.isSuccess && action.result is List) {
        final accs = action.result as List;
        final buf = StringBuffer('🌳 دليل وشجرة الحسابات المالية (${accs.length} حساب):\n\n');
        for (int i = 0; i < accs.length && i < 15; i++) {
          final a = accs[i];
          buf.writeln('• [${a['code']}] **${a['name']}** (${a['type']}) — الرصيد: ${a['balance'] ?? '0.00'} ر.س');
        }
        return _msg(buf.toString().trim(), [action]);
      }
    }

    // E. Financial KPIs, Profit & Loss, Balance Snapshot
    if (p.contains('أرباح') || p.contains('ارباح') || p.contains('مبيعات') || p.contains('مصروفات') || p.contains('مؤشرات') || p.contains('صافي')) {
      final dashAction = await executeTool('get_dashboard_stats', {});
      if (dashAction.isSuccess && dashAction.result is Map) {
        final d = dashAction.result as Map<String, dynamic>;
        final sales = d['total_sales'] ?? d['sales'] ?? 0;
        final purchases = d['total_purchases'] ?? d['purchases'] ?? 0;
        final profit = d['net_profit'] ?? d['profit'] ?? 0;
        final expenses = d['total_expenses'] ?? d['expenses'] ?? 0;
        final cash = d['cash_balance'] ?? d['safe_balance'] ?? 0;
        final receivables = d['customer_receivables'] ?? d['receivables'] ?? 0;

        return _msg('''
📊 ملخص المؤشرات المالية والأرباح:
• صافي الأرباح: $profit ر.س
• إجمالي المبيعات: $sales ر.س
• إجمالي المشتريات: $purchases ر.س
• إجمالي المصروفات: $expenses ر.س
• رصيد الصندوق والبنوك: $cash ر.س
• ذمم وديون العملاء: $receivables ر.س
''', [dashAction]);
      }
    }

    return null; // Forward to LLM for other queries
  }

  static AiMessage _resultMsg(String text, AiToolAction action) {
    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.assistant,
      text: action.isSuccess ? text : 'تعذر تنفيذ العملية: ${action.result}',
      timestamp: DateTime.now(),
      executedActions: [action],
    );
  }

  static AiMessage _msg(String text, List<AiToolAction> actions) {
    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.assistant,
      text: text,
      timestamp: DateTime.now(),
      executedActions: actions,
    );
  }

  // =========================================================================
  // --- REAL REST API & DIRECT SQL EXECUTOR FOR ALL ERP MODULES ---
  // =========================================================================
  static Future<AiToolAction> executeTool(String toolName, Map<String, dynamic> args) async {
    try {
      switch (toolName) {
        // --- 0. Direct SQL & Database Queries ---
        case 'execute_sql_query':
          final res = await ApiService.post(ApiEndpoints.aiQuery, body: {'query': args['query']});
          return AiToolAction(toolName: 'Direct SQL Engine', arguments: args, result: res.data ?? res.rawJson, isSuccess: res.success);

        case 'get_database_schema':
          final res = await ApiService.get(ApiEndpoints.aiSchema);
          return AiToolAction(toolName: 'Database Schema Inspector', arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'global_database_search':
          final res = await ApiService.post(ApiEndpoints.aiSearch, body: {'q': args['q']});
          return AiToolAction(toolName: 'Global DB Search', arguments: args, result: res.rawJson, isSuccess: res.success);

        // --- 1. Dashboard & Reports ---
        case 'get_dashboard_stats':
          final res = await ApiService.get(ApiEndpoints.dashboard);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        // --- 2. Accounts (شجرة الحسابات) ---
        case 'get_accounts_list':
          final res = await ApiService.get(ApiEndpoints.accounts, queryParams: args.map((k, v) => MapEntry(k, v.toString())));
          return AiToolAction(toolName: toolName, arguments: args, result: res.data ?? res.rawJson, isSuccess: res.success);

        case 'create_account':
          final res = await ApiService.post(ApiEndpoints.accounts, body: args);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'update_account':
          final res = await ApiService.put('${ApiEndpoints.accounts}/${args['id']}', body: args);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'delete_account':
          final res = await ApiService.delete('${ApiEndpoints.accounts}/${args['id']}');
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        // --- 3. Journal Entries (قيود اليومية) ---
        case 'get_journal_entries':
          final res = await ApiService.get(ApiEndpoints.journalEntries, queryParams: args.map((k, v) => MapEntry(k, v.toString())));
          return AiToolAction(toolName: toolName, arguments: args, result: res.data ?? res.rawJson, isSuccess: res.success);

        case 'create_journal_entry':
          final res = await ApiService.post(ApiEndpoints.journalEntries, body: args);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'delete_journal_entry':
          final res = await ApiService.delete('${ApiEndpoints.journalEntries}/${args['id']}');
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        // --- 4. Vouchers (سندات القبض والصرف) ---
        case 'get_vouchers':
          final res = await ApiService.get(ApiEndpoints.vouchers, queryParams: args.map((k, v) => MapEntry(k, v.toString())));
          return AiToolAction(toolName: toolName, arguments: args, result: res.data ?? res.rawJson, isSuccess: res.success);

        case 'create_voucher':
          final rawType = (args['type']?.toString().toLowerCase() ?? 'receipt');
          final type = (rawType.contains('صرف') || rawType.contains('payment')) ? 'payment' : 'receipt';
          final amount = double.tryParse(args['amount']?.toString() ?? '0') ?? 0.0;
          final paymentMethod = (args['payment_method']?.toString().contains('bank') ?? false) ? 'bank' : 'cash';

          final res = await ApiService.post(ApiEndpoints.vouchers, body: {
            'type': type,
            'amount': amount,
            'payment_method': paymentMethod,
            'account_id': args['account_id'],
            'party_id': args['party_id'],
            'notes': args['notes'] ?? 'سند منشأ بواسطة المساعد المحاسبي الذكي',
            'date': DateTime.now().toString().substring(0, 10),
          });
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'delete_voucher':
          final res = await ApiService.delete('${ApiEndpoints.vouchers}/${args['id']}');
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        // --- 5. Checks (حافظة الشيكات) ---
        case 'get_checks_list':
          final res = await ApiService.get(ApiEndpoints.checks, queryParams: args.map((k, v) => MapEntry(k, v.toString())));
          return AiToolAction(toolName: toolName, arguments: args, result: res.data ?? res.rawJson, isSuccess: res.success);

        case 'create_check':
          final res = await ApiService.post(ApiEndpoints.checks, body: args);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'update_check_status':
          final res = await ApiService.post('${ApiEndpoints.checks}/${args['id']}/status', body: {'status': args['status']});
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'delete_check':
          final res = await ApiService.delete('${ApiEndpoints.checks}/${args['id']}');
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        // --- 6. Invoices (الفواتير والمبيعات) ---
        case 'get_invoices':
          final res = await ApiService.get(ApiEndpoints.invoices, queryParams: args.map((k, v) => MapEntry(k, v.toString())));
          return AiToolAction(toolName: toolName, arguments: args, result: res.data ?? res.rawJson, isSuccess: res.success);

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

        case 'delete_invoice':
          final res = await ApiService.delete('${ApiEndpoints.invoices}/${args['id']}');
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        // --- 7. Quotations (عروض الأسعار) ---
        case 'get_quotations':
          final res = await ApiService.get(ApiEndpoints.quotations, queryParams: args.map((k, v) => MapEntry(k, v.toString())));
          return AiToolAction(toolName: toolName, arguments: args, result: res.data ?? res.rawJson, isSuccess: res.success);

        case 'convert_quotation':
          final res = await ApiService.post('${ApiEndpoints.quotations}/${args['id']}/convert');
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'delete_quotation':
          final res = await ApiService.delete('${ApiEndpoints.quotations}/${args['id']}');
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        // --- 8. Items & Catalog (الأصناف والمستودع) ---
        case 'get_items_catalog':
          final res = await ApiService.get(ApiEndpoints.items, queryParams: args.containsKey('search') ? {'search': args['search']} : null);
          return AiToolAction(toolName: toolName, arguments: args, result: res.data ?? res.rawJson, isSuccess: res.success);

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

        case 'update_item':
          final res = await ApiService.put('${ApiEndpoints.items}/${args['id']}', body: args);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'delete_item':
          final res = await ApiService.delete('${ApiEndpoints.items}/${args['id']}');
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        // --- 9. Stock Transfers (مناقلات المخزون) ---
        case 'get_stock_transfers':
          final res = await ApiService.get(ApiEndpoints.stockTransfers, queryParams: args.map((k, v) => MapEntry(k, v.toString())));
          return AiToolAction(toolName: toolName, arguments: args, result: res.data ?? res.rawJson, isSuccess: res.success);

        case 'create_stock_transfer':
          final res = await ApiService.post(ApiEndpoints.stockTransfers, body: args);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'delete_stock_transfer':
          final res = await ApiService.delete('${ApiEndpoints.stockTransfers}/${args['id']}');
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        // --- 10. Parties (العملاء والموردين) ---
        case 'get_parties_list':
          final res = await ApiService.get(ApiEndpoints.parties, queryParams: args.map((k, v) => MapEntry(k, v.toString())));
          return AiToolAction(toolName: toolName, arguments: args, result: res.data ?? res.rawJson, isSuccess: res.success);

        case 'create_party':
          final partyType = (args['type']?.toString().contains('مورد') ?? false) ? 'vendor' : 'customer';
          final res = await ApiService.post(ApiEndpoints.parties, body: {
            'name': args['name'],
            'type': args['type'] ?? partyType,
            'phone': args['phone'] ?? '0500000000',
            'address': args['address'],
          });
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'update_party':
          final res = await ApiService.put('${ApiEndpoints.parties}/${args['id']}', body: args);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'delete_party':
          final res = await ApiService.delete('${ApiEndpoints.parties}/${args['id']}');
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        // --- 11. Fixed Assets (الأصول الثابتة والإهلاك) ---
        case 'get_fixed_assets':
          final res = await ApiService.get(ApiEndpoints.fixedAssets, queryParams: args.map((k, v) => MapEntry(k, v.toString())));
          return AiToolAction(toolName: toolName, arguments: args, result: res.data ?? res.rawJson, isSuccess: res.success);

        case 'create_fixed_asset':
          final res = await ApiService.post(ApiEndpoints.fixedAssets, body: args);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'depreciate_fixed_asset':
          final res = await ApiService.post('${ApiEndpoints.fixedAssets}/${args['id']}/depreciate');
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'delete_fixed_asset':
          final res = await ApiService.delete('${ApiEndpoints.fixedAssets}/${args['id']}');
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        // --- 12. Cost Centers (مراكز التكلفة) ---
        case 'get_cost_centers':
          final res = await ApiService.get(ApiEndpoints.costCenters, queryParams: args.map((k, v) => MapEntry(k, v.toString())));
          return AiToolAction(toolName: toolName, arguments: args, result: res.data ?? res.rawJson, isSuccess: res.success);

        case 'create_cost_center':
          final res = await ApiService.post(ApiEndpoints.costCenters, body: args);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'update_cost_center':
          final res = await ApiService.put('${ApiEndpoints.costCenters}/${args['id']}', body: args);
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        case 'delete_cost_center':
          final res = await ApiService.delete('${ApiEndpoints.costCenters}/${args['id']}');
          return AiToolAction(toolName: toolName, arguments: args, result: res.rawJson, isSuccess: res.success);

        default:
          return AiToolAction(toolName: toolName, arguments: args, result: 'Tool $toolName not recognized', isSuccess: false);
      }
    } catch (e) {
      return AiToolAction(toolName: toolName, arguments: args, result: 'Error: $e', isSuccess: false);
    }
  }
}
