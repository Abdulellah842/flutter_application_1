import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'notification_service.dart';

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  static const String _kTasksKey = 'daily_tasks_items_v2';
  static const String _kFocusHoursKey = 'daily_tasks_focus_hours_v2';
  static const String _kAssistantFeedKey = 'daily_tasks_assistant_feed_v2';
  static const String _kProgressTasksDoneKey = 'progress_tasks_done_count_v1';
  static const String _kProgressTasksTotalKey = 'progress_tasks_total_count_v1';
  static const String _kProgressTasksCompletionKey = 'progress_tasks_completion_v1';
  static const String _kPerfectDateKey = 'daily_tasks_perfect_date_v2';
  static const String _kStreakDaysKey = 'daily_tasks_streak_days_v2';
  static const String _kRewardPointsKey = 'daily_tasks_reward_points_v2';
  static const String _kKidsUnlockSignalKey = 'kids_device_unlock_signal_v1';

  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _attachmentController = TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController(text: '0550000000');
  final TextEditingController _whatsAppController =
      TextEditingController(text: '966550000000');
  final List<String> _assistantFeed = <String>[];
  final List<String> _smartNotifications = <String>[];
  List<_TaskItem> _tasks = <_TaskItem>[];

  _TaskBucket _selectedBucket = _TaskBucket.today;
  _TaskBucket _newTaskBucket = _TaskBucket.today;
  _TaskPriority _newTaskPriority = _TaskPriority.medium;
  _TaskRepeat _newTaskRepeat = _TaskRepeat.none;
  _TaskGoal _newTaskGoal = _TaskGoal.work;
  _TaskReason _newTaskReason = _TaskReason.busy;

  TimeOfDay _startTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 19, minute: 30);

  double _focusHours = 2.5;
  bool _loading = true;
  bool _askReminder = true;
  bool _askSplit = true;
  bool _askGoalLink = true;
  bool _enablePhoneCall = false;
  bool _enableWhatsapp = false;

  int _rewardPoints = 0;
  int _streakDays = 0;
  String _lastPerfectDate = '';
  final List<String> _badges = <String>[];

  @override
  void initState() {
    super.initState();
    NotificationService.instance.requestPermissions();
    _loadState();
  }

  @override
  void dispose() {
    _taskController.dispose();
    _attachmentController.dispose();
    _phoneController.dispose();
    _whatsAppController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_kTasksKey);
    final focusHours = prefs.getDouble(_kFocusHoursKey);
    final assistantFeed = prefs.getStringList(_kAssistantFeedKey);
    final points = prefs.getInt(_kRewardPointsKey);
    final streak = prefs.getInt(_kStreakDaysKey);
    final perfectDate = prefs.getString(_kPerfectDateKey);

    if (!mounted) return;
    setState(() {
      if (tasksJson != null) {
        final decoded = (jsonDecode(tasksJson) as List<dynamic>)
            .map((e) => _TaskItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (decoded.isNotEmpty) {
          _tasks = decoded;
        }
      }
      if (_tasks.isEmpty) {
        _tasks = _seedTasks();
      }
      if (focusHours != null) {
        _focusHours = focusHours.clamp(0.5, 16).toDouble();
      }
      if (assistantFeed != null) {
        _assistantFeed
          ..clear()
          ..addAll(assistantFeed);
      }
      _rewardPoints = points ?? 0;
      _streakDays = streak ?? 0;
      _lastPerfectDate = perfectDate ?? '';
      _loading = false;
    });
    await _saveState();
  }

  List<_TaskItem> _seedTasks() {
    return <_TaskItem>[
      _TaskItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'مراجعة درس الرياضيات',
        bucket: _TaskBucket.today,
        priority: _TaskPriority.high,
        repeat: _TaskRepeat.none,
        goal: _TaskGoal.study,
        startMinute: 19 * 60,
        endMinute: 19 * 60 + 30,
        status: _TaskStatus.pending,
        attachments: const <String>['صورة: صفحة 23'],
      ),
      _TaskItem(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        title: 'تمرين 20 دقيقة',
        bucket: _TaskBucket.recurring,
        priority: _TaskPriority.medium,
        repeat: _TaskRepeat.daily,
        goal: _TaskGoal.health,
        startMinute: 18 * 60,
        endMinute: 18 * 60 + 20,
        status: _TaskStatus.pending,
        attachments: const <String>[],
      ),
      _TaskItem(
        id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
        title: 'تجهيز خطة الأسبوع',
        bucket: _TaskBucket.week,
        priority: _TaskPriority.medium,
        repeat: _TaskRepeat.weekly,
        goal: _TaskGoal.work,
        startMinute: 9 * 60,
        endMinute: 10 * 60,
        status: _TaskStatus.pending,
        attachments: const <String>['رابط: docs.google.com'],
      ),
    ];
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kTasksKey,
      jsonEncode(_tasks.map((t) => t.toJson()).toList()),
    );
    await prefs.setDouble(_kFocusHoursKey, _focusHours);
    await prefs.setStringList(_kAssistantFeedKey, _assistantFeed.take(30).toList());
    await prefs.setInt(_kRewardPointsKey, _rewardPoints);
    await prefs.setInt(_kStreakDaysKey, _streakDays);
    await prefs.setString(_kPerfectDateKey, _lastPerfectDate);
    await _saveProgressMetrics();
  }

  Future<void> _saveProgressMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    final todayTasks = _tasks.where((t) => t.bucket == _TaskBucket.today).toList();
    final done = todayTasks.where((t) => t.status == _TaskStatus.done).length;
    final total = todayTasks.length;
    final completion = total == 0 ? 0 : ((done / total) * 100).round().clamp(0, 100);

    await prefs.setInt(_kProgressTasksDoneKey, done);
    await prefs.setInt(_kProgressTasksTotalKey, total);
    await prefs.setInt(_kProgressTasksCompletionKey, completion);
    await prefs.setBool(_kKidsUnlockSignalKey, completion == 100 && total > 0);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _pushAssistant(String text) {
    setState(() {
      _assistantFeed.insert(0, text);
      if (_assistantFeed.length > 40) {
        _assistantFeed.removeRange(40, _assistantFeed.length);
      }
    });
  }

  void _pushNotification(String text) {
    setState(() {
      _smartNotifications.insert(0, text);
      if (_smartNotifications.length > 25) {
        _smartNotifications.removeRange(25, _smartNotifications.length);
      }
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  int _toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  String _formatMinutes(int minute) {
    final h = (minute ~/ 60) % 24;
    final m = minute % 60;
    final time = TimeOfDay(hour: h, minute: m);
    return time.format(context);
  }

  DateTime _atToday(int minute) {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      minute ~/ 60,
      minute % 60,
    );
  }

  int _notifId(_TaskItem task, int offset) {
    final hash = task.id.hashCode & 0x7fffffff;
    return (hash + offset) % 2000000000;
  }

  Future<void> _scheduleTaskAlerts(_TaskItem task) async {
    if (task.bucket != _TaskBucket.today) return;
    final before = _atToday(task.startMinute).subtract(const Duration(minutes: 30));
    final atStart = _atToday(task.startMinute);
    final atEnd = _atToday(task.endMinute);

    await NotificationService.instance.scheduleOneTimeReminder(
      id: _notifId(task, 11),
      title: 'تذكير قبل المهمة',
      body: 'بعد 30 دقيقة عندك مهمة: ${task.title}',
      when: before,
    );
    await NotificationService.instance.scheduleOneTimeReminder(
      id: _notifId(task, 22),
      title: 'حان وقت المهمة',
      body: 'ابدأ الآن: ${task.title}',
      when: atStart,
    );
    await NotificationService.instance.scheduleOneTimeReminder(
      id: _notifId(task, 33),
      title: 'متابعة الإنجاز',
      body: 'انتهى وقت المهمة: ${task.title}. هل أنجزتها؟',
      when: atEnd,
    );
    await NotificationService.instance.scheduleOneTimeReminder(
      id: _notifId(task, 44),
      title: 'تذكير إضافي',
      body: 'ما جاوبت على المهمة: ${task.title}. أذكرك بعد 10 دقائق.',
      when: atEnd.add(const Duration(minutes: 10)),
    );
  }

  Future<void> _startPhoneCall() async {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      _showSnack('أدخل رقم الجوال أولًا.');
      return;
    }
    final uri = Uri.parse('tel:$raw');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack('تعذر بدء الاتصال.');
    }
  }

  Future<void> _sendWhatsAppMessage(String message) async {
    final raw = _whatsAppController.text.trim();
    if (raw.isEmpty) {
      _showSnack('أدخل رقم واتساب أولًا.');
      return;
    }
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$raw?text=$encoded');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack('تعذر فتح واتساب.');
    }
  }

  void _simulateVoiceInput() {
    setState(() {
      _taskController.text = 'مراجعة تقرير المشروع مع الفريق';
    });
    _showSnack('تم إدخال المهمة صوتيًا (محاكاة).');
  }

  Future<void> _addTask() async {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;
    final start = _toMinutes(_startTime);
    final end = _toMinutes(_endTime);
    if (end <= start) {
      _showSnack('وقت النهاية يجب أن يكون بعد وقت البداية.');
      return;
    }

    final attachments = _attachmentController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final created = _TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      bucket: _newTaskBucket,
      priority: _newTaskPriority,
      repeat: _newTaskRepeat,
      goal: _newTaskGoal,
      startMinute: start,
      endMinute: end,
      status: _TaskStatus.pending,
      attachments: attachments,
    );

    final List<_TaskItem> newItems = <_TaskItem>[created];
    if (_askSplit && title.length > 18) {
      newItems.add(
        created.copyWith(
          id: '${created.id}-step',
          title: 'الخطوة 1 من: ${created.title}',
          endMinute: start + ((end - start) ~/ 2),
        ),
      );
    }

    setState(() {
      _tasks = <_TaskItem>[...newItems, ..._tasks];
      _taskController.clear();
      _attachmentController.clear();
    });

    await _scheduleTaskAlerts(created);

    if (_askReminder) {
      _pushAssistant('تبغى أحط لك تذكير قبل المهمة "${created.title}"؟ تم تفعيله تلقائيًا.');
      _pushNotification(
        'بعد 30 دقيقة عندك مهمة: ${created.title}. جاهز تبدأ؟',
      );
    }
    if (_askGoalLink) {
      _pushAssistant('تم ربط المهمة بهدفك: ${created.goal.label}.');
    }
    if (_askSplit && newItems.length > 1) {
      _pushAssistant('قسمت لك المهمة إلى خطوة بداية لتسهيل التنفيذ.');
    }

    await _saveState();
  }

  List<_TaskItem> _filteredTasks() {
    return _tasks.where((t) => t.bucket == _selectedBucket).toList();
  }

  bool _isDelayed(_TaskItem task) {
    if (task.bucket != _TaskBucket.today) return false;
    if (task.status == _TaskStatus.done) return false;
    final now = TimeOfDay.now();
    return _toMinutes(now) > task.endMinute;
  }

  Future<void> _updateTaskStatus(_TaskItem task, _TaskStatus status) async {
    if (status == _TaskStatus.notDone) {
      final reason = await _askFailureReason();
      if (reason == null) return;
      _newTaskReason = reason;
    }

    setState(() {
      _tasks = _tasks.map((t) {
        if (t.id != task.id) return t;
        return t.copyWith(status: status, reason: _newTaskReason);
      }).toList();
    });

    if (status == _TaskStatus.done) {
      _rewardPoints += task.priority.points;
      _pushAssistant('أحسنت! أنجزت "${task.title}" وحصلت على ${task.priority.points} نقطة.');
      _pushNotification('تم إنهاء مهمة "${task.title}" بنجاح.');
      await NotificationService.instance.showNow(
        id: _notifId(task, 55),
        title: 'ممتاز',
        body: 'تم إنجاز المهمة: ${task.title}',
      );
    } else if (status == _TaskStatus.partial) {
      _pushAssistant('تم تسجيل إنجاز جزئي. أقترح تقسيم "${task.title}" لخطوتين.');
    } else if (status == _TaskStatus.notDone) {
      _pushAssistant(
        'سبب عدم الإنجاز: ${_newTaskReason.label}. أقترح ${_newTaskReason.solution}',
      );
      _pushNotification(
        'المهمة "${task.title}" لم تُنجز. هل تبغاني أذكرك بعد 10 دقائق؟',
      );
      await NotificationService.instance.showNow(
        id: _notifId(task, 66),
        title: 'متابعة مهمة',
        body: 'المهمة "${task.title}" لم تُنجز بعد.',
      );
    }

    await _applyRewardsAndLinks();
    await _saveState();
  }

  Future<_TaskReason?> _askFailureReason() async {
    return showModalBottomSheet<_TaskReason>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'وش السبب؟',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ..._TaskReason.values.map(
                  (r) => ListTile(
                    title: Text(r.label, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(r.solution, style: const TextStyle(color: Colors.white70)),
                    onTap: () => Navigator.of(context).pop(r),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _applyRewardsAndLinks() async {
    final todayTasks = _tasks.where((t) => t.bucket == _TaskBucket.today).toList();
    final done = todayTasks.where((t) => t.status == _TaskStatus.done).length;
    final total = todayTasks.length;
    final completion = total == 0 ? 0 : ((done / total) * 100).round();
    final today = _todayKey();

    if (completion == 100 && total > 0 && _lastPerfectDate != today) {
      _lastPerfectDate = today;
      _streakDays += 1;
      _rewardPoints += 20;
      if (!_badges.contains('وسام اليوم المثالي')) {
        _badges.add('وسام اليوم المثالي');
      }
      if (_streakDays >= 7 && !_badges.contains('وسام 7 أيام متتالية')) {
        _badges.add('وسام 7 أيام متتالية');
      }
      _pushAssistant('ممتاز! أنجزت 100% من مهام اليوم وحصلت على وسام اليوم المثالي.');
      _pushNotification('تم فتح مكافأة يومية بسبب الإنجاز الكامل.');
    }

    if (completion >= 80) {
      _pushAssistant('تقدمك في "تابع تقدمك" ارتفع تلقائيًا بسبب نسبة الإنجاز العالية.');
    }
  }

  Future<void> _simulateSmartCycle() async {
    final tasks = _tasks
        .where((t) => t.bucket == _TaskBucket.today && t.status == _TaskStatus.pending)
        .toList();
    if (tasks.isEmpty) {
      _showSnack('لا توجد مهام اليوم المتأخرة للتنبيه عليها.');
      return;
    }
    final t = tasks.first;
    _pushNotification('بعد 30 دقيقة عندك مهمة: ${t.title}.');
    _pushNotification('حان وقت مهمة: ${t.title}.');
    _pushNotification('انتهى وقت المهمة… هل أنجزتها؟');
    _pushNotification('ما جاوبت… هل تبغاني أذكرك بعد 10 دقائق؟');
    await _scheduleTaskAlerts(t);
    if (_enablePhoneCall) {
      await _startPhoneCall();
      _pushNotification('تم بدء الاتصال الهاتفي.');
    }
    if (_enableWhatsapp) {
      await _sendWhatsAppMessage('تذكير بالمهمة: ${t.title}');
      _pushNotification('تم فتح رسالة واتساب التذكيرية.');
    }
  }

  Future<void> _showInAppCallDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: const Text('مكالمة المساعد', style: TextStyle(color: Colors.white)),
          content: const Text(
            'يا Abdulellah، باقي لك 20 دقيقة على نهاية اليوم… تبغى نبدأ المهمة مع بعض؟',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إنهاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_enablePhoneCall) {
                  _startPhoneCall();
                }
                _pushAssistant('بدأنا الآن. أول خطوة: افتح المهمة وحدد نقطة البداية خلال 3 دقائق.');
                Navigator.pop(context);
              },
              child: const Text('ابدأ مع المساعد'),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _summary() {
    final todayTasks = _tasks.where((t) => t.bucket == _TaskBucket.today).toList();
    final done = todayTasks.where((t) => t.status == _TaskStatus.done).length;
    final delayed = todayTasks.where(_isDelayed).length;
    final total = todayTasks.length;
    final completion = total == 0 ? 0 : ((done / total) * 100).round();

    final grouped = <int, int>{};
    for (final t in todayTasks.where((t) => t.status == _TaskStatus.done)) {
      grouped[t.startMinute] = (grouped[t.startMinute] ?? 0) + 1;
    }
    int best = -1;
    int worst = -1;
    if (grouped.isNotEmpty) {
      final sorted = grouped.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
      worst = sorted.first.key;
      best = sorted.last.key;
    }
    return <String, dynamic>{
      'done': done,
      'delayed': delayed,
      'total': total,
      'completion': completion,
      'best': best,
      'worst': worst,
    };
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary();
    final tasks = _filteredTasks();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0F1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0F1E),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'مهامك اليومية',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
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
                        const Text(
                          'لوحة التقدم اليومية',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _metric('المنجز', '${summary['done']}/${summary['total']}')),
                            const SizedBox(width: 8),
                            Expanded(child: _metric('المتأخر', '${summary['delayed']}')),
                            const SizedBox(width: 8),
                            Expanded(child: _metric('الإنجاز', '${summary['completion']}%')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: (summary['completion'] / 100).clamp(0.0, 1.0),
                            minHeight: 9,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          summary['best'] == -1
                              ? 'التحليل: أكمل مهامك أولًا ليظهر أفضل/أسوأ وقت للإنجاز.'
                              : 'التحليل: أفضل وقت لك ${_formatMinutes(summary['best'] as int)} وأسوأ وقت ${_formatMinutes(summary['worst'] as int)}.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إضافة مهمة بذكاء',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _taskController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('اكتب المهمة نصيًا أو استخدم الإدخال الصوتي'),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _simulateVoiceInput,
                              icon: const Icon(Icons.mic_rounded),
                              label: const Text('إدخال صوتي'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _pickTime(start: true),
                              icon: const Icon(Icons.schedule),
                              label: Text('بداية: ${_startTime.format(context)}'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _pickTime(start: false),
                              icon: const Icon(Icons.timer_outlined),
                              label: Text('نهاية: ${_endTime.format(context)}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _dropdown(
                              value: _newTaskBucket,
                              items: _TaskBucket.values,
                              labelOf: (v) => v.label,
                              onChanged: (v) => setState(() => _newTaskBucket = v),
                            ),
                            _dropdown(
                              value: _newTaskPriority,
                              items: _TaskPriority.values,
                              labelOf: (v) => v.label,
                              onChanged: (v) => setState(() => _newTaskPriority = v),
                            ),
                            _dropdown(
                              value: _newTaskRepeat,
                              items: _TaskRepeat.values,
                              labelOf: (v) => v.label,
                              onChanged: (v) => setState(() => _newTaskRepeat = v),
                            ),
                            _dropdown(
                              value: _newTaskGoal,
                              items: _TaskGoal.values,
                              labelOf: (v) => v.label,
                              onChanged: (v) => setState(() => _newTaskGoal = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _attachmentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('مرفقات (صور/ملفات/روابط) مفصولة بفاصلة'),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('تذكير قبل المهمة'),
                              selected: _askReminder,
                              onSelected: (v) => setState(() => _askReminder = v),
                            ),
                            FilterChip(
                              label: const Text('تقسيم المهمة لخطوات'),
                              selected: _askSplit,
                              onSelected: (v) => setState(() => _askSplit = v),
                            ),
                            FilterChip(
                              label: const Text('ربطها بهدف أسبوعي'),
                              selected: _askGoalLink,
                              onSelected: (v) => setState(() => _askGoalLink = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _addTask,
                            icon: const Icon(Icons.add_task),
                            label: const Text('إضافة المهمة'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'نظام التنبيهات الذكي',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _enablePhoneCall,
                          onChanged: (v) => setState(() => _enablePhoneCall = v),
                          title: const Text('اتصال على الجوال', style: TextStyle(color: Colors.white)),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _enableWhatsapp,
                          onChanged: (v) => setState(() => _enableWhatsapp = v),
                          title: const Text('رسالة واتساب', style: TextStyle(color: Colors.white)),
                        ),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('رقم الجوال للاتصال (مثال: 0550000000)'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _whatsAppController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('رقم واتساب بصيغة دولية (مثال: 9665...)'),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _simulateSmartCycle,
                              icon: const Icon(Icons.notifications_active_outlined),
                              label: const Text('تشغيل دورة تنبيه'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _showInAppCallDialog,
                              icon: const Icon(Icons.call_rounded),
                              label: const Text('اتصال مباشر داخل التطبيق'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _startPhoneCall,
                              icon: const Icon(Icons.phone_forwarded_rounded),
                              label: const Text('اتصال الآن'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _sendWhatsAppMessage('تذكير بمهمتي الحالية'),
                              icon: const Icon(Icons.chat_rounded),
                              label: const Text('واتساب الآن'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._smartNotifications.take(4).map(
                          (n) => Text('• $n', style: const TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المساعد الشخصي داخل المهام',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'يراجعك، يقترح وقت بديل، ويعطيك خطوات بداية سريعة.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                        ),
                        const SizedBox(height: 8),
                        ..._assistantFeed.take(5).map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• $m', style: const TextStyle(color: Colors.white70)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'نظام المكافآت',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _metric('النقاط', '$_rewardPoints'),
                            _metric('سلسلة الإنجاز', '$_streakDays يوم'),
                            _metric('ساعات التركيز', '${_focusHours.toStringAsFixed(1)}h'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _badges.isEmpty ? 'لا توجد أوسمة بعد.' : 'الأوسمة: ${_badges.join('، ')}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Slider(
                          value: _focusHours,
                          min: 0.5,
                          max: 12,
                          divisions: 23,
                          activeColor: const Color(0xFF38BDF8),
                          label: '${_focusHours.toStringAsFixed(1)} ساعة',
                          onChanged: (v) {
                            setState(() => _focusHours = v);
                            _saveState();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تصنيفات المهام',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _TaskBucket.values
                              .map(
                                (b) => ChoiceChip(
                                  label: Text(b.label),
                                  selected: _selectedBucket == b,
                                  selectedColor: const Color(0xFF2563EB),
                                  labelStyle: TextStyle(
                                    color: _selectedBucket == b ? Colors.white : Colors.white70,
                                  ),
                                  onSelected: (_) => setState(() => _selectedBucket = b),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        if (tasks.isEmpty)
                          const Text('لا توجد مهام في هذا القسم بعد.', style: TextStyle(color: Colors.white70)),
                        ...tasks.map(
                          (task) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatMinutes(task.startMinute)} - ${_formatMinutes(task.endMinute)} | ${task.priority.label} | ${task.goal.label} | ${task.repeat.label}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                if (task.attachments.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'مرفقات: ${task.attachments.join(' | ')}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Chip(
                                      label: Text(task.status.label),
                                      backgroundColor: task.status.color.withValues(alpha: 0.25),
                                      labelStyle: TextStyle(color: task.status.color),
                                    ),
                                    if (_isDelayed(task))
                                      const Chip(
                                        label: Text('متأخرة'),
                                        backgroundColor: Color(0x33EF4444),
                                        labelStyle: TextStyle(color: Color(0xFFFCA5A5)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _updateTaskStatus(task, _TaskStatus.done),
                                      child: const Text('تم الإنجاز'),
                                    ),
                                    OutlinedButton(
                                      onPressed: () => _updateTaskStatus(task, _TaskStatus.partial),
                                      child: const Text('جزئي'),
                                    ),
                                    OutlinedButton(
                                      onPressed: () => _updateTaskStatus(task, _TaskStatus.notDone),
                                      child: const Text('لم يتم'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButton<T>(
      value: value,
      dropdownColor: const Color(0xFF111827),
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(12),
      style: const TextStyle(color: Colors.white),
      items: items
          .map((v) => DropdownMenuItem<T>(value: v, child: Text(labelOf(v))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

enum _TaskBucket {
  today('مهام اليوم'),
  tomorrow('مهام الغد'),
  week('مهام الأسبوع'),
  longTerm('مهام طويلة المدى'),
  recurring('مهام متكررة');

  const _TaskBucket(this.label);
  final String label;
}

enum _TaskPriority {
  low('منخفضة', 4),
  medium('متوسطة', 8),
  high('عالية', 15);

  const _TaskPriority(this.label, this.points);
  final String label;
  final int points;
}

enum _TaskRepeat {
  none('مرة واحدة'),
  daily('يومي'),
  weekly('أسبوعي'),
  monthly('شهري');

  const _TaskRepeat(this.label);
  final String label;
}

enum _TaskGoal {
  health('صحة'),
  study('دراسة'),
  work('عمل'),
  habit('عادة');

  const _TaskGoal(this.label);
  final String label;
}

enum _TaskStatus {
  pending('بانتظار التنفيذ', Color(0xFF93C5FD)),
  partial('منجز جزئيًا', Color(0xFFFCD34D)),
  done('مكتمل', Color(0xFF86EFAC)),
  notDone('لم يتم', Color(0xFFFCA5A5));

  const _TaskStatus(this.label, this.color);
  final String label;
  final Color color;
}

enum _TaskReason {
  forgot('نسيان', 'نضيف تذكير قبل المهمة بـ 30 دقيقة.'),
  busy('انشغال', 'نقترح وقت بديل خلال نفس اليوم.'),
  hard('صعوبة', 'نقسمها إلى خطوات صغيرة واضحة.'),
  bored('ملل', 'نربطها بهدف أسبوعي ونضيف مكافأة.');

  const _TaskReason(this.label, this.solution);
  final String label;
  final String solution;
}

class _TaskItem {
  const _TaskItem({
    required this.id,
    required this.title,
    required this.bucket,
    required this.priority,
    required this.repeat,
    required this.goal,
    required this.startMinute,
    required this.endMinute,
    required this.status,
    required this.attachments,
    this.reason,
  });

  final String id;
  final String title;
  final _TaskBucket bucket;
  final _TaskPriority priority;
  final _TaskRepeat repeat;
  final _TaskGoal goal;
  final int startMinute;
  final int endMinute;
  final _TaskStatus status;
  final List<String> attachments;
  final _TaskReason? reason;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'bucket': bucket.name,
      'priority': priority.name,
      'repeat': repeat.name,
      'goal': goal.name,
      'startMinute': startMinute,
      'endMinute': endMinute,
      'status': status.name,
      'attachments': attachments,
      'reason': reason?.name,
    };
  }

  factory _TaskItem.fromJson(Map<String, dynamic> json) {
    _TaskBucket parseBucket(String? raw) => _TaskBucket.values.firstWhere(
          (v) => v.name == raw,
          orElse: () => _TaskBucket.today,
        );
    _TaskPriority parsePriority(String? raw) => _TaskPriority.values.firstWhere(
          (v) => v.name == raw,
          orElse: () => _TaskPriority.medium,
        );
    _TaskRepeat parseRepeat(String? raw) => _TaskRepeat.values.firstWhere(
          (v) => v.name == raw,
          orElse: () => _TaskRepeat.none,
        );
    _TaskGoal parseGoal(String? raw) => _TaskGoal.values.firstWhere(
          (v) => v.name == raw,
          orElse: () => _TaskGoal.work,
        );
    _TaskStatus parseStatus(String? raw) => _TaskStatus.values.firstWhere(
          (v) => v.name == raw,
          orElse: () => _TaskStatus.pending,
        );
    _TaskReason? parseReason(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      return _TaskReason.values.firstWhere(
        (v) => v.name == raw,
        orElse: () => _TaskReason.busy,
      );
    }

    return _TaskItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      bucket: parseBucket(json['bucket']?.toString()),
      priority: parsePriority(json['priority']?.toString()),
      repeat: parseRepeat(json['repeat']?.toString()),
      goal: parseGoal(json['goal']?.toString()),
      startMinute: (json['startMinute'] as num?)?.round() ?? (9 * 60),
      endMinute: (json['endMinute'] as num?)?.round() ?? (9 * 60 + 30),
      status: parseStatus(json['status']?.toString()),
      attachments: (json['attachments'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      reason: parseReason(json['reason']?.toString()),
    );
  }

  _TaskItem copyWith({
    String? id,
    String? title,
    int? startMinute,
    int? endMinute,
    _TaskStatus? status,
    _TaskReason? reason,
  }) {
    return _TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      bucket: bucket,
      priority: priority,
      repeat: repeat,
      goal: goal,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      status: status ?? this.status,
      attachments: attachments,
      reason: reason ?? this.reason,
    );
  }
}
