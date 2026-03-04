import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/home_style_card.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  static const String _kEntriesKey = 'finance_entries_v2';
  static const String _kBudgetTotalKey = 'finance_budget_total_v2';
  static const String _kCategoryBudgetsKey = 'finance_category_budgets_v2';
  static const String _kGoalsKey = 'finance_goals_v2';
  static const String _kSavingsBalanceKey = 'finance_savings_balance_v2';
  static const String _kAutoSaveEnabledKey = 'finance_auto_save_enabled_v2';
  static const String _kDailyTasksAssistantFeedKey = 'daily_tasks_assistant_feed_v2';
  static const String _kRolloverModeKey = 'finance_daily_rollover_mode_v1';
  static const String _kMoveSurplusToSavingsKey = 'finance_move_surplus_to_savings_v1';
  static const String _kDailyBudgetOverrideKey = 'finance_daily_budget_override_v1';
  static const String _kSurplusTransferMonthKey = 'finance_surplus_transfer_month_v1';
  static const String _kSurplusTransferredDayKey = 'finance_surplus_transferred_day_v1';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _goalTitleController = TextEditingController();
  final TextEditingController _goalTargetController = TextEditingController();
  final TextEditingController _goalMonthsController = TextEditingController(text: '6');
  final TextEditingController _dailyBudgetController = TextEditingController();

  final List<_MoneyEntry> _entries = <_MoneyEntry>[];
  final List<_FinanceGoal> _goals = <_FinanceGoal>[];
  final List<String> _assistantNotes = <String>[];

  _EntryKind _entryKind = _EntryKind.expense;
  _SpendCategory _category = _SpendCategory.misc;
  double _monthlyBudget = 5000;
  double _savingsBalance = 0;
  double _dailyBudgetOverride = 0;
  bool _autoSaveEnabled = true;
  bool _moveSurplusToSavings = false;
  bool _loading = true;
  _RolloverMode _rolloverMode = _RolloverMode.carryForward;
  String _surplusTransferMonth = '';
  int _surplusTransferredDay = 0;

  final Map<_SpendCategory, double> _categoryBudgets = <_SpendCategory, double>{
    _SpendCategory.food: 900,
    _SpendCategory.shopping: 700,
    _SpendCategory.transport: 650,
    _SpendCategory.health: 400,
    _SpendCategory.bills: 950,
    _SpendCategory.entertainment: 450,
    _SpendCategory.study: 350,
    _SpendCategory.kids: 400,
    _SpendCategory.misc: 200,
  };

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _goalTitleController.dispose();
    _goalTargetController.dispose();
    _goalMonthsController.dispose();
    _dailyBudgetController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getString(_kEntriesKey);
    final goalsJson = prefs.getString(_kGoalsKey);
    final budget = prefs.getDouble(_kBudgetTotalKey);
    final savings = prefs.getDouble(_kSavingsBalanceKey);
    final autoSave = prefs.getBool(_kAutoSaveEnabledKey);
    final catJson = prefs.getString(_kCategoryBudgetsKey);
    final rolloverRaw = prefs.getString(_kRolloverModeKey);
    final moveSurplus = prefs.getBool(_kMoveSurplusToSavingsKey);
    final dailyOverride = prefs.getDouble(_kDailyBudgetOverrideKey);
    final transferMonth = prefs.getString(_kSurplusTransferMonthKey);
    final transferredDay = prefs.getInt(_kSurplusTransferredDayKey);

    if (entriesJson != null) {
      final data = (jsonDecode(entriesJson) as List<dynamic>)
          .map((e) => _MoneyEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _entries
        ..clear()
        ..addAll(data);
    }
    if (goalsJson != null) {
      final data = (jsonDecode(goalsJson) as List<dynamic>)
          .map((e) => _FinanceGoal.fromJson(e as Map<String, dynamic>))
          .toList();
      _goals
        ..clear()
        ..addAll(data);
    }
    if (budget != null) _monthlyBudget = budget;
    if (savings != null) _savingsBalance = savings;
    if (autoSave != null) _autoSaveEnabled = autoSave;
    if (moveSurplus != null) _moveSurplusToSavings = moveSurplus;
    if (dailyOverride != null) _dailyBudgetOverride = dailyOverride;
    if (transferMonth != null) _surplusTransferMonth = transferMonth;
    if (transferredDay != null) _surplusTransferredDay = transferredDay;
    if (rolloverRaw != null) {
      _rolloverMode = _RolloverMode.values.firstWhere(
        (e) => e.name == rolloverRaw,
        orElse: () => _RolloverMode.carryForward,
      );
    }
    if (catJson != null) {
      final map = jsonDecode(catJson) as Map<String, dynamic>;
      for (final c in _SpendCategory.values) {
        final v = (map[c.name] as num?)?.toDouble();
        if (v != null) _categoryBudgets[c] = v;
      }
    }

    if (_entries.isEmpty) _seedData();
    _dailyBudgetController.text =
        _dailyBudgetOverride <= 0 ? '' : _dailyBudgetOverride.toStringAsFixed(0);
    _refreshAssistantInsights();

    if (!mounted) return;
    setState(() => _loading = false);
    await _saveState();
  }

  void _seedData() {
    _entries.addAll([
      _MoneyEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'راتب شهري',
        amount: 7000,
        kind: _EntryKind.income,
        category: _SpendCategory.misc,
        date: DateTime.now().subtract(const Duration(days: 10)),
      ),
      _MoneyEntry(
        id: '${DateTime.now().millisecondsSinceEpoch + 1}',
        title: 'مطاعم',
        amount: 220,
        kind: _EntryKind.expense,
        category: _SpendCategory.food,
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      _MoneyEntry(
        id: '${DateTime.now().millisecondsSinceEpoch + 2}',
        title: 'فاتورة كهرباء',
        amount: 310,
        kind: _EntryKind.bill,
        category: _SpendCategory.bills,
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kEntriesKey,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _kGoalsKey,
      jsonEncode(_goals.map((g) => g.toJson()).toList()),
    );
    await prefs.setDouble(_kBudgetTotalKey, _monthlyBudget);
    await prefs.setDouble(_kSavingsBalanceKey, _savingsBalance);
    await prefs.setBool(_kAutoSaveEnabledKey, _autoSaveEnabled);
    await prefs.setString(_kRolloverModeKey, _rolloverMode.name);
    await prefs.setBool(_kMoveSurplusToSavingsKey, _moveSurplusToSavings);
    await prefs.setDouble(_kDailyBudgetOverrideKey, _dailyBudgetOverride);
    await prefs.setString(_kSurplusTransferMonthKey, _surplusTransferMonth);
    await prefs.setInt(_kSurplusTransferredDayKey, _surplusTransferredDay);
    await prefs.setString(
      _kCategoryBudgetsKey,
      jsonEncode(_categoryBudgets.map((k, v) => MapEntry(k.name, v))),
    );
  }

  void _addEntry() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (title.isEmpty || amount == null || amount <= 0) return;

    final autoCat = _detectCategory(title);
    final entry = _MoneyEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      kind: _entryKind,
      category: autoCat,
      date: DateTime.now(),
    );

    setState(() {
      _entries.insert(0, entry);
      _category = autoCat;
      _titleController.clear();
      _amountController.clear();
    });

    _refreshAssistantInsights();
    _saveState();
  }

  _SpendCategory _detectCategory(String text) {
    final t = text.toLowerCase();
    if (t.contains('مطعم') || t.contains('قهوة') || t.contains('food')) return _SpendCategory.food;
    if (t.contains('بنزين') || t.contains('وقود') || t.contains('نقل')) return _SpendCategory.transport;
    if (t.contains('صحة') || t.contains('صيدلية') || t.contains('دواء')) return _SpendCategory.health;
    if (t.contains('كهرب') || t.contains('ماء') || t.contains('فاتورة')) return _SpendCategory.bills;
    if (t.contains('طفل') || t.contains('ابن')) return _SpendCategory.kids;
    if (t.contains('دراسة') || t.contains('كتاب')) return _SpendCategory.study;
    if (t.contains('تسوق') || t.contains('ملابس')) return _SpendCategory.shopping;
    return _category;
  }

  void _addGoal() {
    final title = _goalTitleController.text.trim();
    final target = double.tryParse(_goalTargetController.text.trim());
    final months = int.tryParse(_goalMonthsController.text.trim());
    if (title.isEmpty || target == null || target <= 0 || months == null || months <= 0) return;

    final suggested = target / months;
    setState(() {
      _goals.insert(
        0,
        _FinanceGoal(
          title: title,
          targetAmount: target,
          months: months,
          savedAmount: 0,
          monthlySuggested: suggested,
        ),
      );
      _goalTitleController.clear();
      _goalTargetController.clear();
      _goalMonthsController.text = '6';
    });
    _refreshAssistantInsights();
    _saveState();
  }

  double _incomeThisMonth() {
    final now = DateTime.now();
    return _entries
        .where((e) => e.date.year == now.year && e.date.month == now.month && e.kind == _EntryKind.income)
        .fold(0.0, (a, b) => a + b.amount);
  }

  double _expenseThisMonth() {
    final now = DateTime.now();
    return _entries
        .where((e) => e.date.year == now.year && e.date.month == now.month && e.kind != _EntryKind.income)
        .fold(0.0, (a, b) => a + b.amount);
  }

  double _expenseLastMonth() {
    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final year = now.month == 1 ? now.year - 1 : now.year;
    return _entries
        .where((e) => e.date.year == year && e.date.month == lastMonth && e.kind != _EntryKind.income)
        .fold(0.0, (a, b) => a + b.amount);
  }

  Map<_SpendCategory, double> _spentByCategory() {
    final map = <_SpendCategory, double>{for (final c in _SpendCategory.values) c: 0};
    final now = DateTime.now();
    for (final e in _entries) {
      if (e.kind == _EntryKind.income) continue;
      if (e.date.year == now.year && e.date.month == now.month) {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
    }
    return map;
  }

  int _daysInMonth(int year, int month) {
    final nextMonth = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1));
    return lastDay.day;
  }

  double _dailyBaseBudget({required int year, required int month}) {
    if (_dailyBudgetOverride > 0) return _dailyBudgetOverride;
    final days = _daysInMonth(year, month);
    if (days <= 0) return 0;
    return _monthlyBudget / days;
  }

  Map<int, double> _spentByDayCurrentMonth() {
    final now = DateTime.now();
    final map = <int, double>{};
    for (final e in _entries) {
      if (e.kind == _EntryKind.income) continue;
      if (e.date.year == now.year && e.date.month == now.month) {
        map[e.date.day] = (map[e.date.day] ?? 0) + e.amount;
      }
    }
    return map;
  }

  List<_DailyBudgetRow> _buildDailyBudgetRows() {
    final now = DateTime.now();
    final days = _daysInMonth(now.year, now.month);
    final base = _dailyBaseBudget(year: now.year, month: now.month);
    final spentByDay = _spentByDayCurrentMonth();

    final rows = <_DailyBudgetRow>[];
    var carry = 0.0;
    for (var day = 1; day <= days; day++) {
      final date = DateTime(now.year, now.month, day);
      final spent = spentByDay[day] ?? 0.0;
      final carryIn = _rolloverMode == _RolloverMode.carryForward ? carry : 0.0;
      final available = base + carryIn;
      final balance = available - spent;

      double carryOut = 0.0;
      if (_rolloverMode == _RolloverMode.carryForward) {
        if (_moveSurplusToSavings && balance > 0) {
          carryOut = 0;
        } else {
          carryOut = balance;
        }
      }
      carry = carryOut;

      rows.add(
        _DailyBudgetRow(
          date: date,
          baseBudget: base,
          carryIn: carryIn,
          spent: spent,
          balance: balance,
        ),
      );
    }
    return rows;
  }

  Future<void> _applySurplusToSavings() async {
    if (!_moveSurplusToSavings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فعّل خيار تحويل الفائض للادخار أولًا.')),
      );
      return;
    }

    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    if (_surplusTransferMonth != monthKey) {
      _surplusTransferMonth = monthKey;
      _surplusTransferredDay = 0;
    }

    final yesterday = now.day - 1;
    if (yesterday <= 0 || _surplusTransferredDay >= yesterday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد فائض جديد للترحيل اليوم.')),
      );
      return;
    }

    final rows = _buildDailyBudgetRows();
    var transferable = 0.0;
    for (final row in rows) {
      final d = row.date.day;
      if (d <= _surplusTransferredDay || d > yesterday) continue;
      if (row.balance > 0) transferable += row.balance;
    }

    if (transferable <= 0) {
      _surplusTransferredDay = yesterday;
      await _saveState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد فائض موجب خلال الأيام السابقة.')),
      );
      return;
    }

    setState(() {
      _savingsBalance += transferable;
      _surplusTransferredDay = yesterday;
    });
    await _saveState();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تحويل ${transferable.toStringAsFixed(0)} ريال إلى الادخار.')),
    );
  }

  Map<String, double> _monthSnapshot({required int year, required int month}) {
    final income = _entries
        .where((e) => e.date.year == year && e.date.month == month && e.kind == _EntryKind.income)
        .fold(0.0, (a, b) => a + b.amount);
    final expense = _entries
        .where((e) => e.date.year == year && e.date.month == month && e.kind != _EntryKind.income)
        .fold(0.0, (a, b) => a + b.amount);
    final savings = income - expense;
    return <String, double>{
      'income': income,
      'expense': expense,
      'savings': savings,
    };
  }

  void _refreshAssistantInsights() {
    _assistantNotes.clear();
    final spent = _expenseThisMonth();
    final income = _incomeThisMonth();
    final last = _expenseLastMonth();
    final byCat = _spentByCategory();

    if (last > 0) {
      final growth = ((spent - last) / last) * 100;
      if (growth > 8) {
        _assistantNotes.add('مصاريفك الشهرية زادت ${growth.toStringAsFixed(0)}% مقارنة بالشهر الماضي.');
      }
    }

    final topCat = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (topCat.isNotEmpty && topCat.first.value > 0) {
      _assistantNotes.add('أعلى فئة صرف هذا الشهر: ${topCat.first.key.label} (${topCat.first.value.toStringAsFixed(0)} ريال).');
      final catBudget = _categoryBudgets[topCat.first.key] ?? 0;
      if (catBudget > 0 && topCat.first.value > catBudget * 0.8) {
        _assistantNotes.add('صرف ${topCat.first.key.label} قرب نهاية ميزانيته. تبغى أنقل جزء من فئة أخرى؟');
      }
    }

    final budgetGap = spent - _monthlyBudget;
    if (budgetGap > 0) {
      _assistantNotes.add('إذا استمريت بنفس المعدل، بتتجاوز الميزانية بـ ${budgetGap.toStringAsFixed(0)} ريال.');
    } else {
      final left = _monthlyBudget - spent;
      _assistantNotes.add('باقي من ميزانيتك الشهرية ${left.toStringAsFixed(0)} ريال.');
    }

    final surplus = income - spent;
    if (surplus > 0 && _autoSaveEnabled) {
      final suggest = math.max(50, surplus * 0.2);
      _assistantNotes.add('عندك فائض ${surplus.toStringAsFixed(0)} ريال. أقترح تحويل ${suggest.toStringAsFixed(0)} ريال للادخار.');
    }

    for (final g in _goals) {
      final remaining = (g.targetAmount - g.savedAmount).clamp(0, g.targetAmount);
      final needed = g.months <= 0 ? remaining : remaining / g.months;
      if (needed > g.monthlySuggested * 1.1) {
        _assistantNotes.add('لهدف "${g.title}" تحتاج ترفع الادخار الشهري إلى ${needed.toStringAsFixed(0)} ريال.');
      }
    }

    if (_assistantNotes.isEmpty) {
      _assistantNotes.add('وضعك المالي ممتاز اليوم. استمر بنفس الانضباط.');
    }
  }

  String _investmentInsight() {
    final income = _incomeThisMonth();
    final expense = _expenseThisMonth();
    if (income <= 0) return 'أدخل دخلك أولًا حتى أقدر أحلل القدرة الاستثمارية.';
    final spare = ((income - expense) / income * 100).clamp(0, 100);
    if (spare < 10) return 'قدرتك الاستثمارية الحالية منخفضة. الأفضل التركيز على تخفيض المصاريف وبناء صندوق طوارئ.';
    if (spare < 25) return 'نسبة استثمار مناسبة لك بين 10% و 15% من الدخل (معلومات عامة، بدون توصية منتج).';
    return 'وضعك جيد، تقدر تخصص 15% إلى 20% للاستثمار بشكل تدريجي مع إدارة المخاطر.';
  }

  Future<void> _sendFinanceTaskToDaily() async {
    final prefs = await SharedPreferences.getInstance();
    final feed = prefs.getStringList(_kDailyTasksAssistantFeedKey) ?? <String>[];
    feed.insert(0, 'مهمة مالية مقترحة: مراجعة الميزانية اليوم خلال 15 دقيقة.');
    await prefs.setStringList(_kDailyTasksAssistantFeedKey, feed.take(40).toList());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال مهمة مالية إلى مهام اليوم.')));
  }

  @override
  Widget build(BuildContext context) {
    final income = _incomeThisMonth();
    final expense = _expenseThisMonth();
    final savings = (income - expense).clamp(-999999, 999999);
    final byCat = _spentByCategory();
    final dailyRows = _buildDailyBudgetRows();
    final today = DateTime.now().day;
    final todayRow = dailyRows.firstWhere(
      (r) => r.date.day == today,
      orElse: () => _DailyBudgetRow(
        date: DateTime.now(),
        baseBudget: _dailyBaseBudget(year: DateTime.now().year, month: DateTime.now().month),
        carryIn: 0,
        spent: 0,
        balance: 0,
      ),
    );
    final now = DateTime.now();
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final currentSnap = _monthSnapshot(year: now.year, month: now.month);
    final previousSnap = _monthSnapshot(year: prevYear, month: prevMonth);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0F1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0F1E),
          elevation: 0,
          centerTitle: true,
          title: const Text('الإدارة المالية الذكية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                children: [
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('نظرة شهرية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _metric('الدخل', income.toStringAsFixed(0))),
                            const SizedBox(width: 8),
                            Expanded(child: _metric('المصاريف', expense.toStringAsFixed(0))),
                            const SizedBox(width: 8),
                            Expanded(child: _metric('صافي', savings.toStringAsFixed(0))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('جدول الميزانية اليومية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          'اليوم ${todayRow.date.day}/${todayRow.date.month}: المتاح ${todayRow.available.toStringAsFixed(0)} - المصروف ${todayRow.spent.toStringAsFixed(0)} = الصافي ${todayRow.balance.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _dailyBudgetController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: Colors.white),
                                decoration: _dec('ميزانية يومية ثابتة (اختياري، مثال 100)'),
                                onSubmitted: (v) {
                                  final parsed = double.tryParse(v.trim()) ?? 0;
                                  setState(() {
                                    _dailyBudgetOverride = parsed > 0 ? parsed : 0;
                                  });
                                  _saveState();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _dailyBudgetOverride = 0;
                                    _dailyBudgetController.clear();
                                  });
                                  _saveState();
                                },
                                child: const Text('تلقائي'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _drop(
                              _rolloverMode,
                              _RolloverMode.values,
                              (v) => v.label,
                              (v) {
                                setState(() => _rolloverMode = v);
                                _saveState();
                              },
                            ),
                            FilterChip(
                              label: const Text('تحويل الفائض إلى الادخار'),
                              selected: _moveSurplusToSavings,
                              onSelected: (v) {
                                setState(() => _moveSurplusToSavings = v);
                                _saveState();
                              },
                            ),
                            OutlinedButton.icon(
                              onPressed: _applySurplusToSavings,
                              icon: const Icon(Icons.savings_outlined),
                              label: const Text('ترحيل الفائض الآن'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('اليوم', style: TextStyle(color: Colors.white70))),
                              DataColumn(label: Text('التاريخ', style: TextStyle(color: Colors.white70))),
                              DataColumn(label: Text('الأساسية', style: TextStyle(color: Colors.white70))),
                              DataColumn(label: Text('مرحل', style: TextStyle(color: Colors.white70))),
                              DataColumn(label: Text('المصروف', style: TextStyle(color: Colors.white70))),
                              DataColumn(label: Text('الصافي', style: TextStyle(color: Colors.white70))),
                            ],
                            rows: dailyRows.map((r) {
                              final isToday = r.date.day == today;
                              Color valueColor(double v) => v >= 0 ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);
                              return DataRow(
                                color: isToday ? WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.08)) : null,
                                cells: [
                                  DataCell(Text(_weekdayAr(r.date.weekday), style: const TextStyle(color: Colors.white))),
                                  DataCell(Text('${r.date.day}/${r.date.month}', style: const TextStyle(color: Colors.white70))),
                                  DataCell(Text(r.baseBudget.toStringAsFixed(0), style: const TextStyle(color: Colors.white70))),
                                  DataCell(Text(r.carryIn.toStringAsFixed(0), style: TextStyle(color: valueColor(r.carryIn)))),
                                  DataCell(Text(r.spent.toStringAsFixed(0), style: const TextStyle(color: Colors.white70))),
                                  DataCell(Text(r.balance.toStringAsFixed(0), style: TextStyle(color: valueColor(r.balance), fontWeight: FontWeight.w700))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('التقارير البيانية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        _buildBarComparison(
                          current: currentSnap,
                          previous: previousSnap,
                          currentLabel: 'هذا الشهر',
                          previousLabel: 'الشهر السابق',
                        ),
                        const SizedBox(height: 14),
                        _buildPieSection(byCat),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('تتبع ذكي للدخل والمصاريف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: _dec('وصف العملية: مطاعم، راتب، فاتورة...')),
                        const SizedBox(height: 8),
                        TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: _dec('المبلغ')),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _drop(_entryKind, _EntryKind.values, (v) => v.label, (v) => setState(() => _entryKind = v)),
                            _drop(_category, _SpendCategory.values, (v) => v.label, (v) => setState(() => _category = v)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _addEntry, icon: const Icon(Icons.add), label: const Text('إضافة عملية'))),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الميزانية الذكية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('الميزانية الشهرية: ${_monthlyBudget.toStringAsFixed(0)} ريال', style: const TextStyle(color: Colors.white70)),
                        Slider(
                          value: _monthlyBudget,
                          min: 1000,
                          max: 25000,
                          divisions: 48,
                          activeColor: const Color(0xFF38BDF8),
                          onChanged: (v) {
                            setState(() => _monthlyBudget = v);
                            _refreshAssistantInsights();
                            _saveState();
                          },
                        ),
                        const SizedBox(height: 4),
                        ..._SpendCategory.values.map((c) {
                          final spent = byCat[c] ?? 0;
                          final budget = _categoryBudgets[c] ?? 1;
                          final ratio = (spent / budget).clamp(0.0, 1.0);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${c.label}: ${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 8,
                                    backgroundColor: Colors.white12,
                                    valueColor: AlwaysStoppedAnimation<Color>(ratio > 0.9 ? const Color(0xFFEF4444) : const Color(0xFF22C55E)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الأهداف المالية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TextField(controller: _goalTitleController, style: const TextStyle(color: Colors.white), decoration: _dec('اسم الهدف: سفر، سيارة...')),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: _goalTargetController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _dec('المبلغ المطلوب'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: _goalMonthsController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _dec('عدد الأشهر'))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _addGoal, child: const Text('إضافة هدف'))),
                        const SizedBox(height: 8),
                        ..._goals.map((g) {
                          final p = (g.savedAmount / g.targetAmount).clamp(0.0, 1.0);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                Text('الهدف: ${g.targetAmount.toStringAsFixed(0)} | ادخار شهري مقترح: ${g.monthlySuggested.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(value: p, backgroundColor: Colors.white12),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الادخار والاستثمار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _metric('رصيد الادخار', _savingsBalance.toStringAsFixed(0))),
                            const SizedBox(width: 8),
                            Expanded(child: _metric('صافي الشهر', savings.toStringAsFixed(0))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _autoSaveEnabled,
                          onChanged: (v) {
                            setState(() => _autoSaveEnabled = v);
                            _saveState();
                          },
                          title: const Text('تفعيل الادخار التلقائي من الفائض', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 6),
                        Text('رؤية استثمارية عامة: ${_investmentInsight()}', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('المساعد المالي الذكي + التوقعات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        ..._assistantNotes.take(7).map((n) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('• $n', style: const TextStyle(color: Colors.white70)),
                            )),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الربط مع باقي التطبيق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('إذا زاد الصرف على الترفيه، يوصي المساعد بتخفيف مهام الترفيه وربط هدف مالي جديد.', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _sendFinanceTaskToDaily,
                            icon: const Icon(Icons.link_rounded),
                            label: const Text('إرسال مهمة مالية إلى مهام اليوم'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _weekdayAr(int weekday) {
    const days = <int, String>{
      DateTime.monday: 'الاثنين',
      DateTime.tuesday: 'الثلاثاء',
      DateTime.wednesday: 'الأربعاء',
      DateTime.thursday: 'الخميس',
      DateTime.friday: 'الجمعة',
      DateTime.saturday: 'السبت',
      DateTime.sunday: 'الأحد',
    };
    return days[weekday] ?? '';
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.2),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _card({required Widget child}) {
    return HomeStyleCard(
      accentA: const Color(0xFF22C55E),
      accentB: const Color(0xFF0F172A),
      child: child,
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _drop<T>(T value, List<T> items, String Function(T) label, ValueChanged<T> onChanged) {
    return DropdownButton<T>(
      value: value,
      dropdownColor: const Color(0xFF111827),
      style: const TextStyle(color: Colors.white),
      underline: const SizedBox.shrink(),
      items: items.map((e) => DropdownMenuItem<T>(value: e, child: Text(label(e)))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _buildBarComparison({
    required Map<String, double> current,
    required Map<String, double> previous,
    required String currentLabel,
    required String previousLabel,
  }) {
    final maxValue = <double>[
      current['income'] ?? 0,
      current['expense'] ?? 0,
      current['savings']?.abs() ?? 0,
      previous['income'] ?? 0,
      previous['expense'] ?? 0,
      previous['savings']?.abs() ?? 0,
      1,
    ].reduce(math.max);

    Widget metricBars({
      required String label,
      required double currentValue,
      required double previousValue,
      required Color currentColor,
      required Color previousColor,
    }) {
      final cRatio = (currentValue.abs() / maxValue).clamp(0.0, 1.0);
      final pRatio = (previousValue.abs() / maxValue).clamp(0.0, 1.0);

      Widget oneBar(double ratio, Color color, String value) {
        return Expanded(
          child: Column(
            children: [
              SizedBox(
                height: 86,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        );
      }

      return Expanded(
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                oneBar(cRatio, currentColor, currentValue.toStringAsFixed(0)),
                const SizedBox(width: 6),
                oneBar(pRatio, previousColor, previousValue.toStringAsFixed(0)),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF38BDF8), borderRadius: BorderRadius.circular(99))),
            const SizedBox(width: 6),
            Text(currentLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(width: 12),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF64748B), borderRadius: BorderRadius.circular(99))),
            const SizedBox(width: 6),
            Text(previousLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: Row(
            children: [
              metricBars(
                label: 'الدخل',
                currentValue: current['income'] ?? 0,
                previousValue: previous['income'] ?? 0,
                currentColor: const Color(0xFF38BDF8),
                previousColor: const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              metricBars(
                label: 'المصاريف',
                currentValue: current['expense'] ?? 0,
                previousValue: previous['expense'] ?? 0,
                currentColor: const Color(0xFFEF4444),
                previousColor: const Color(0xFF7F1D1D),
              ),
              const SizedBox(width: 8),
              metricBars(
                label: 'الادخار',
                currentValue: current['savings'] ?? 0,
                previousValue: previous['savings'] ?? 0,
                currentColor: const Color(0xFF22C55E),
                previousColor: const Color(0xFF14532D),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPieSection(Map<_SpendCategory, double> byCat) {
    final positive = byCat.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = positive.take(5).toList();
    final other = positive.skip(5).fold(0.0, (a, b) => a + b.value);

    final palette = <Color>[
      const Color(0xFF38BDF8),
      const Color(0xFF22C55E),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFFA78BFA),
      const Color(0xFF64748B),
    ];

    final slices = <_PieSlice>[];
    for (var i = 0; i < top.length; i++) {
      slices.add(_PieSlice(
        label: top[i].key.label,
        value: top[i].value,
        color: palette[i % palette.length],
      ));
    }
    if (other > 0) {
      slices.add(_PieSlice(label: 'متفرقات أخرى', value: other, color: palette.last));
    }

    if (slices.isEmpty) {
      return const Text('لا توجد مصاريف كافية لرسم المخطط الدائري.', style: TextStyle(color: Colors.white70));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('توزيع المصاريف حسب الفئات', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(
                painter: _PieChartPainter(slices),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: slices
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(99))),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${s.label}: ${s.value.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _RolloverMode {
  carryForward('ترحيل الرصيد لليوم التالي'),
  resetDaily('بدون ترحيل يومي');

  const _RolloverMode(this.label);
  final String label;
}

enum _EntryKind {
  income('دخل'),
  expense('مصروف'),
  subscription('اشتراك'),
  bill('فاتورة'),
  transfer('تحويل'),
  bigPurchase('مشتريات كبيرة');

  const _EntryKind(this.label);
  final String label;
}

class _DailyBudgetRow {
  const _DailyBudgetRow({
    required this.date,
    required this.baseBudget,
    required this.carryIn,
    required this.spent,
    required this.balance,
  });

  final DateTime date;
  final double baseBudget;
  final double carryIn;
  final double spent;
  final double balance;

  double get available => baseBudget + carryIn;
}

enum _SpendCategory {
  food('مطاعم'),
  shopping('تسوق'),
  transport('نقل'),
  health('صحة'),
  bills('فواتير'),
  entertainment('ترفيه'),
  study('دراسة'),
  kids('مصروف الأبناء'),
  misc('متنوع');

  const _SpendCategory(this.label);
  final String label;
}

class _MoneyEntry {
  const _MoneyEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.kind,
    required this.category,
    required this.date,
  });

  final String id;
  final String title;
  final double amount;
  final _EntryKind kind;
  final _SpendCategory category;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'kind': kind.name,
        'category': category.name,
        'date': date.millisecondsSinceEpoch,
      };

  factory _MoneyEntry.fromJson(Map<String, dynamic> j) {
    _EntryKind parseKind(String? raw) => _EntryKind.values.firstWhere((e) => e.name == raw, orElse: () => _EntryKind.expense);
    _SpendCategory parseCat(String? raw) => _SpendCategory.values.firstWhere((e) => e.name == raw, orElse: () => _SpendCategory.misc);
    return _MoneyEntry(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      amount: (j['amount'] as num?)?.toDouble() ?? 0,
      kind: parseKind(j['kind']?.toString()),
      category: parseCat(j['category']?.toString()),
      date: DateTime.fromMillisecondsSinceEpoch((j['date'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}

class _FinanceGoal {
  const _FinanceGoal({
    required this.title,
    required this.targetAmount,
    required this.months,
    required this.savedAmount,
    required this.monthlySuggested,
  });

  final String title;
  final double targetAmount;
  final int months;
  final double savedAmount;
  final double monthlySuggested;

  Map<String, dynamic> toJson() => {
        'title': title,
        'targetAmount': targetAmount,
        'months': months,
        'savedAmount': savedAmount,
        'monthlySuggested': monthlySuggested,
      };

  factory _FinanceGoal.fromJson(Map<String, dynamic> j) {
    return _FinanceGoal(
      title: (j['title'] ?? '').toString(),
      targetAmount: (j['targetAmount'] as num?)?.toDouble() ?? 0,
      months: (j['months'] as num?)?.toInt() ?? 1,
      savedAmount: (j['savedAmount'] as num?)?.toDouble() ?? 0,
      monthlySuggested: (j['monthlySuggested'] as num?)?.toDouble() ?? 0,
    );
  }
}

class _PieSlice {
  const _PieSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter(this.slices);

  final List<_PieSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (a, b) => a + b.value);
    if (total <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    var start = -math.pi / 2;
    for (final s in slices) {
      final sweep = (s.value / total) * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.butt
        ..color = s.color;
      canvas.drawArc(rect.deflate(16), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}
