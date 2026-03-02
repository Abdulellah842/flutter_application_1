import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  static const String _kHabitsKey = 'habits_data_v1';
  static const String _kChallengesKey = 'habits_challenges_v1';
  static const String _kRoutineGoalKey = 'habits_routine_goal_v1';
  static const String _kDailyRoutineKey = 'habits_daily_routine_v1';
  static const String _kCoachHabitKey = 'habits_selected_coach_habit_v1';
  static const String _kCoachResponseKey = 'habits_coach_response_v1';
  static const String _kFocusMinutesKey = 'habits_focus_minutes_v1';
  static const String _kFocusMusicKey = 'habits_focus_music_v1';
  static const String _kMoodSuggestionKey = 'habits_mood_suggestion_v1';
  static const String _kProgressHabitsCompletionKey =
      'progress_habits_completion_v1';
  static const String _kProgressHabitsStreakAvgKey =
      'progress_habits_streak_avg_v1';
  static const String _kProgressHabitsChallengesDoneKey =
      'progress_habits_challenges_done_v1';
  static const String _kProgressHabitsChallengesTotalKey =
      'progress_habits_challenges_total_v1';
  static const String _kProgressHabitLearningHintsKey =
      'progress_habit_learning_hints_v1';
  final TextEditingController _habitPromptController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _moodController = TextEditingController();

  List<_HabitItem> _habits = [
    const _HabitItem(name: 'شرب الماء صباحًا', progress: 0.82, streak: 9),
    const _HabitItem(name: 'قراءة 10 دقائق', progress: 0.64, streak: 5),
    const _HabitItem(name: 'تمرين خفيف', progress: 0.37, streak: 2),
  ];

  List<String> _habitSuggestions = const [];
  _RoutineGoal _routineGoal = _RoutineGoal.sleep;
  List<String> _dailyRoutine = const ['حدّد هدفك ليتم بناء روتين يومي متكامل.'];

  final List<_HobbyItem> _hobbies = [
    const _HobbyItem(name: 'الرسم', level: _HobbyLevel.beginner, todayTip: 'ارسم شيء خلال 3 دقائق فقط.'),
    const _HobbyItem(name: 'الكتابة', level: _HobbyLevel.intermediate, todayTip: 'اكتب فقرة عن فكرة اليوم.'),
    const _HobbyItem(name: 'التصوير', level: _HobbyLevel.beginner, todayTip: 'التقط صورة بفكرة "ضوء وظل".'),
    const _HobbyItem(name: 'برمجة', level: _HobbyLevel.advanced, todayTip: 'حل مسألة صغيرة خلال 15 دقيقة.'),
  ];

  List<_ChallengeItem> _challenges = [
    const _ChallengeItem(title: '7 أيام بدون سكر', done: false),
    const _ChallengeItem(title: '10 دقائق قراءة', done: true),
    const _ChallengeItem(title: '5 دقائق تأمل', done: false),
    const _ChallengeItem(title: '3 أيام بدون سوشيال بعد 11 مساء', done: false),
  ];

  String? _selectedHabitForCoach;
  String _coachResponse = 'إذا تعثّرت في عادة، اكتب السبب وسيساعدك الموجّه بخطوات واقعية.';

  static const List<double> _weeklyTrend = [0.35, 0.42, 0.48, 0.56, 0.62, 0.7, 0.74];

  int _focusMinutes = 25;
  int _focusRemainingSeconds = 0;
  Timer? _focusTimer;
  String _focusMusic = 'Lo-fi Focus';

  String _moodSuggestion = 'اكتب مزاجك اليومي لتحصل على عادة مناسبة فورًا.';

  @override
  void initState() {
    super.initState();
    _selectedHabitForCoach = _habits.first.name;
    _loadState();
  }

  @override
  void dispose() {
    _habitPromptController.dispose();
    _reasonController.dispose();
    _moodController.dispose();
    _focusTimer?.cancel();
    super.dispose();
  }

  void _updateHabitProgress(int index, double value) {
    final item = _habits[index];
    setState(() {
      _habits[index] = item.copyWith(progress: value);
    });
    _saveState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = prefs.getString(_kHabitsKey);
    final challengesJson = prefs.getString(_kChallengesKey);
    final routineGoal = prefs.getString(_kRoutineGoalKey);
    final dailyRoutine = prefs.getStringList(_kDailyRoutineKey);
    final coachHabit = prefs.getString(_kCoachHabitKey);
    final coachResponse = prefs.getString(_kCoachResponseKey);
    final focusMinutes = prefs.getInt(_kFocusMinutesKey);
    final focusMusic = prefs.getString(_kFocusMusicKey);
    final moodSuggestion = prefs.getString(_kMoodSuggestionKey);

    if (!mounted) return;

    setState(() {
      if (habitsJson != null) {
        final decoded = (jsonDecode(habitsJson) as List<dynamic>)
            .map((e) => _HabitItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (decoded.isNotEmpty) {
          _habits = decoded;
        }
      }

      if (challengesJson != null) {
        _challenges = (jsonDecode(challengesJson) as List<dynamic>)
            .map((e) => _ChallengeItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (routineGoal != null) {
        _routineGoal = _RoutineGoal.values.firstWhere(
          (e) => e.name == routineGoal,
          orElse: () => _RoutineGoal.sleep,
        );
      }
      if (dailyRoutine != null && dailyRoutine.isNotEmpty) {
        _dailyRoutine = dailyRoutine;
      }
      if (coachResponse != null) {
        _coachResponse = coachResponse;
      }
      if (focusMinutes != null) {
        _focusMinutes = focusMinutes;
      }
      if (focusMusic != null && focusMusic.isNotEmpty) {
        _focusMusic = focusMusic;
      }
      if (moodSuggestion != null) {
        _moodSuggestion = moodSuggestion;
      }

      final validCoachHabit = coachHabit != null && _habits.any((h) => h.name == coachHabit);
      _selectedHabitForCoach = validCoachHabit ? coachHabit : _habits.first.name;
    });
    await _saveProgressMetrics(prefs);
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kHabitsKey,
      jsonEncode(_habits.map((h) => h.toJson()).toList()),
    );
    await prefs.setString(
      _kChallengesKey,
      jsonEncode(_challenges.map((c) => c.toJson()).toList()),
    );
    await prefs.setString(_kRoutineGoalKey, _routineGoal.name);
    await prefs.setStringList(_kDailyRoutineKey, _dailyRoutine);
    if (_selectedHabitForCoach != null) {
      await prefs.setString(_kCoachHabitKey, _selectedHabitForCoach!);
    }
    await prefs.setString(_kCoachResponseKey, _coachResponse);
    await prefs.setInt(_kFocusMinutesKey, _focusMinutes);
    await prefs.setString(_kFocusMusicKey, _focusMusic);
    await prefs.setString(_kMoodSuggestionKey, _moodSuggestion);
    await _saveProgressMetrics(prefs);
  }

  Future<void> _saveProgressMetrics(SharedPreferences prefs) async {
    final habitsCompletion = _habits.isEmpty
        ? 0
        : ((_habits.map((h) => h.progress).reduce((a, b) => a + b) /
                    _habits.length) *
                100)
            .round()
            .clamp(0, 100);
    final avgStreak = _habits.isEmpty
        ? 0
        : (_habits.map((h) => h.streak).reduce((a, b) => a + b) /
                _habits.length)
            .round()
            .clamp(0, 365);
    final challengesDone = _challenges.where((c) => c.done).length;
    final challengesTotal = _challenges.length;
    final learningHints = _habits
        .where(
          (h) => h.name.contains('قراءة') || h.name.contains('تعلم') || h.name.contains('دراسة'),
        )
        .length;

    await prefs.setInt(_kProgressHabitsCompletionKey, habitsCompletion);
    await prefs.setInt(_kProgressHabitsStreakAvgKey, avgStreak);
    await prefs.setInt(_kProgressHabitsChallengesDoneKey, challengesDone);
    await prefs.setInt(_kProgressHabitsChallengesTotalKey, challengesTotal);
    await prefs.setInt(_kProgressHabitLearningHintsKey, learningHints);
  }

  void _generateHabitSuggestions() {
    final prompt = _habitPromptController.text.trim();
    if (prompt.isEmpty) {
      _showSnack('اكتب طلبك أولًا (مثال: أبغى عادة تخدمني في الصباح).');
      return;
    }

    final lower = prompt.toLowerCase();
    List<String> suggestions;

    if (lower.contains('صباح') || lower.contains('morning')) {
      suggestions = const [
        'شرب كوبين ماء بعد الاستيقاظ',
        '3 دقائق تنفّس عميق',
        'مراجعة أهداف اليوم لمدة دقيقتين',
        'تمدد خفيف 5 دقائق',
        'بدء اليوم بدون جوال 20 دقيقة',
      ];
    } else if (lower.contains('نوم') || lower.contains('sleep')) {
      suggestions = const [
        'إيقاف الكافيين بعد 6 مساءً',
        'إغلاق الشاشات قبل النوم بـ 30 دقيقة',
        'قراءة هادئة 10 دقائق ليلًا',
        'كتابة تفريغ ذهني سريع',
        'تثبيت وقت نوم يومي',
      ];
    } else if (lower.contains('انتاج') || lower.contains('إنتاج') || lower.contains('product')) {
      suggestions = const [
        'تحديد أهم 3 مهام في بداية اليوم',
        'جلسة تركيز 25 دقيقة (Pomodoro)',
        'مراجعة التقدم كل 4 ساعات',
        'تقليل التنبيهات أثناء العمل',
        'إنهاء مهمة صعبة قبل الظهر',
      ];
    } else {
      suggestions = const [
        '5 دقائق قراءة يومية',
        '10 ضغطات بعد كل ساعة جلوس',
        'شرب كوب ماء كل ساعتين',
        'مراجعة عادة واحدة قبل النوم',
        'كتابة إنجاز اليوم بسطر واحد',
      ];
    }

    setState(() {
      _habitSuggestions = suggestions;
    });
  }

  void _addSuggestedHabit(String name) {
    final exists = _habits.any((h) => h.name == name);
    if (exists) {
      _showSnack('هذه العادة موجودة مسبقًا.');
      return;
    }

    setState(() {
      _habits = [..._habits, _HabitItem(name: name, progress: 0.2, streak: 0)];
      _selectedHabitForCoach ??= name;
    });
    _saveState();
  }

  void _buildRoutine() {
    final routine = switch (_routineGoal) {
      _RoutineGoal.sleep => <String>[
          '7:30 صباحًا: تعرّض للشمس 5 دقائق.',
          '2:00 ظهرًا: آخر جرعة كافيين.',
          '9:30 مساءً: تهدئة إضاءة المنزل.',
          '10:00 مساءً: قراءة خفيفة بدل السوشيال.',
          '10:30 مساءً: نوم ثابت يوميًا.',
        ],
      _RoutineGoal.productivity => <String>[
          '8:00 صباحًا: تحديد 3 مهام محورية.',
          '8:15 صباحًا: جلسة تركيز 25 دقيقة.',
          '12:00 ظهرًا: مراجعة نصف يوم 5 دقائق.',
          '4:00 عصرًا: إنهاء أصعب مهمة متبقية.',
          '9:00 مساءً: تخطيط سريع ليوم الغد.',
        ],
      _RoutineGoal.skill => <String>[
          'جلسة تعلّم 20 دقيقة يوميًا.',
          'تطبيق عملي 15 دقيقة بعد التعلّم.',
          'مراجعة الأخطاء يوميًا 5 دقائق.',
          'مشروع مصغّر مرتين أسبوعيًا.',
          'تقييم أسبوعي للتقدّم وتعديل المسار.',
        ],
    };

    setState(() {
      _dailyRoutine = routine;
    });
    _saveState();
  }
  void _toggleChallenge(int index, bool? value) {
    setState(() {
      _challenges[index] = _challenges[index].copyWith(done: value ?? false);
    });
    _saveState();
  }

  void _coachAnalyze() {
    final reason = _reasonController.text.trim();
    if (_selectedHabitForCoach == null) {
      _showSnack('اختر عادة أولًا.');
      return;
    }
    if (reason.isEmpty) {
      _showSnack('اكتب السبب أولًا.');
      return;
    }

    final tips = <String>['خلّها عادة أصغر.', 'غيّر وقت تنفيذها.', 'اربطها بعادة ثانية موجودة.'];
    if (reason.contains('وقت') || reason.contains('مشغول')) {
      tips.add('اختصرها إلى دقيقتين فقط في الأيام المزدحمة.');
    }
    if (reason.contains('نسيت')) {
      tips.add('أضف تذكيرًا بعد عادة ثابتة مثل الإفطار.');
    }
    if (reason.contains('تعب') || reason.contains('خمول')) {
      tips.add('ابدأ بنسخة خفيفة جدًا (50% من العادة).');
    }

    setState(() {
      _coachResponse = 'سؤالي لك بلطف: وش اللي خلاك ما تكمل اليوم؟\n\n'
          'اقتراحات واقعية:\n- ${tips.join('\n- ')}\n\n'
          'مستقبلًا يمكن تفعيل خيار "العقاب" بشكل آمن ومنضبط.';
    });
    _saveState();
  }

  void _startFocus() {
    _focusTimer?.cancel();
    setState(() {
      _focusRemainingSeconds = _focusMinutes * 60;
    });

    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_focusRemainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _focusRemainingSeconds = 0;
        });
        _showSnack('انتهت جلسة التركيز. تقييمك اليوم: ممتاز 👍');
        return;
      }
      setState(() {
        _focusRemainingSeconds -= 1;
      });
    });

    _showSnack('بدأ وضع التركيز. حاول إبعاد الإشعارات المشتتة يدويًا.');
  }

  void _stopFocus() {
    _focusTimer?.cancel();
    setState(() {
      _focusRemainingSeconds = 0;
    });
  }

  String _formatFocusTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _suggestByMood() {
    final mood = _moodController.text.trim();
    if (mood.isEmpty) {
      _showSnack('اكتب مزاجك أولًا.');
      return;
    }

    if (mood.contains('خمول') || mood.contains('تعب')) {
      _moodSuggestion = 'مزاج منخفض اليوم: اقترح عادة خفيفة جدًا -> مشي دقيقتين + كوب ماء.';
    } else if (mood.contains('متحمس') || mood.contains('طاقة')) {
      _moodSuggestion = 'طاقة عالية اليوم: عادة قوية -> جلسة تركيز 45 دقيقة + مراجعة أهداف الأسبوع.';
    } else if (mood.contains('توتر') || mood.contains('قلق')) {
      _moodSuggestion = 'مزاج متوتر: 4 دقائق تنفّس + كتابة 3 أفكار مقلقة ثم خطوة واحدة عملية.';
    } else {
      _moodSuggestion = 'اقتراح متوازن: 10 دقائق قراءة + 5 دقائق تخطيط + 2 دقيقة تقييم يومي.';
    }

    setState(() {});
    _saveState();
  }

  Color _statusColor(double progress) {
    if (progress >= 0.75) return const Color(0xFF16A34A);
    if (progress >= 0.45) return const Color(0xFFEAB308);
    return const Color(0xFFDC2626);
  }

  String _statusLabel(double progress) {
    if (progress >= 0.75) return 'ممتاز';
    if (progress >= 0.45) return 'متوسط';
    return 'ضعيف';
  }

  int get _totalPoints {
    final progressPoints = _habits.fold<int>(0, (acc, h) => acc + (h.progress * 100).round());
    final streakPoints = _habits.fold<int>(0, (acc, h) => acc + h.streak * 4);
    final challengesPoints = _challenges.where((c) => c.done).length * 20;
    return progressPoints + streakPoints + challengesPoints;
  }

  String get _level {
    if (_totalPoints >= 520) return 'مستوى 5';
    if (_totalPoints >= 380) return 'مستوى 4';
    if (_totalPoints >= 260) return 'مستوى 3';
    if (_totalPoints >= 140) return 'مستوى 2';
    return 'مستوى 1';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bestHabit = _habits.reduce((a, b) => a.progress >= b.progress ? a : b);
    final worstHabit = _habits.reduce((a, b) => a.progress <= b.progress ? a : b);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0F1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0F1E),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'عادات اليوم',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Text(
              'نظام عادات ذكي',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'واجهة بسيطة لكن قوية: متابعة، اقتراح، تحليل، وتحفيز.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'العادات المختارة + نسبة الإنجاز + السلسلة',
              subtitle: 'لون الحالة: أخضر ممتاز | أصفر متوسط | أحمر ضعيف',
              c1: const Color(0xFF0EA5E9),
              c2: const Color(0xFF2563EB),
              child: Column(
                children: List.generate(_habits.length, (index) {
                  final item = _habits[index];
                  final statusColor = _statusColor(item.progress);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusLabel(item.progress),
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: item.progress,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'الإنجاز: ${(item.progress * 100).round()}%',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const Spacer(),
                            Text(
                              'Streak: ${item.streak} أيام',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        Slider(
                          value: item.progress,
                          min: 0,
                          max: 1,
                          activeColor: statusColor,
                          onChanged: (v) => _updateHabitProgress(index, v),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'إنشاء عادة جديدة بطريقة ذكية',
              subtitle: 'اكتب هدفًا بسيطًا وسنقترح 5 عادات جاهزة.',
              c1: const Color(0xFF7C3AED),
              c2: const Color(0xFFA855F7),
              child: Column(
                children: [
                  TextField(
                    controller: _habitPromptController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _input('مثال: أبغى عادة تخدمني في الصباح'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateHabitSuggestions,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('اقترح لي 5 عادات'),
                      style: _solid(const Color(0xFF6D28D9)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_habitSuggestions.isEmpty)
                    const Text('لا توجد اقتراحات بعد.', style: TextStyle(color: Colors.white70)),
                  ..._habitSuggestions.map(
                    (s) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: Colors.black.withValues(alpha: 0.2),
                        title: Text(s, style: const TextStyle(color: Colors.white)),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.white),
                          onPressed: () => _addSuggestedHabit(s),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'مساعد بناء الروتين',
              subtitle: 'حدد هدفك وسيتم توليد روتين يومي كامل.',
              c1: const Color(0xFF16A34A),
              c2: const Color(0xFF22C55E),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _RoutineGoal.values.map((goal) {
                      return ChoiceChip(
                        label: Text(goal.label),
                        selected: _routineGoal == goal,
                        selectedColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        labelStyle: TextStyle(
                          color: _routineGoal == goal ? const Color(0xFF166534) : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) {
                          setState(() => _routineGoal = goal);
                          _saveState();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _buildRoutine,
                      icon: const Icon(Icons.route),
                      label: const Text('ابنِ روتيني اليومي'),
                      style: _solid(const Color(0xFF166534)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._dailyRoutine.map((r) => _Line(text: r)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'هواياتك — مساحة اكتشاف',
              subtitle: 'نشاط يومي بسيط + مستوى تقدم لكل هواية.',
              c1: const Color(0xFFEA580C),
              c2: const Color(0xFFF97316),
              child: Column(
                children: _hobbies
                    .map(
                      (h) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    h.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  h.level.label,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(h.todayTip, style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'تحديات قصيرة (Micro Challenges)',
              subtitle: 'تحفيز يومي أو أسبوعي بدون ثقل.',
              c1: const Color(0xFF0F766E),
              c2: const Color(0xFF14B8A6),
              child: Column(
                children: List.generate(_challenges.length, (index) {
                  final c = _challenges[index];
                  return CheckboxListTile(
                    value: c.done,
                    onChanged: (v) => _toggleChallenge(index, v),
                    activeColor: Colors.white,
                    checkColor: const Color(0xFF0F766E),
                    title: Text(c.title, style: const TextStyle(color: Colors.white)),
                    tileColor: Colors.black.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'مساعد الالتزام (AI Accountability Coach)',
              subtitle: 'يسألك بلطف عند التعثر ويقترح حلولًا عملية.',
              c1: const Color(0xFF1D4ED8),
              c2: const Color(0xFF3B82F6),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedHabitForCoach,
                    dropdownColor: const Color(0xFF0F172A),
                    decoration: _input('اختر عادة'),
                    items: _habits
                        .map(
                          (h) => DropdownMenuItem<String>(
                            value: h.name,
                            child: Text(h.name, style: const TextStyle(color: Colors.white)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() => _selectedHabitForCoach = v);
                      _saveState();
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _input('وش اللي خلاك ما تكمل اليوم؟'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _coachAnalyze,
                      icon: const Icon(Icons.psychology_alt_outlined),
                      label: const Text('حلّل وضعي اليوم'),
                      style: _solid(const Color(0xFF1E40AF)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TextBox(text: _coachResponse),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'تحليل أسبوعي ذكي',
              subtitle: 'أفضل عادة، أسوأ عادة، اقتراح إضافة/حذف + رسم تطور.',
              c1: const Color(0xFF7C2D12),
              c2: const Color(0xFFEA580C),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Line(text: 'أفضل عادة: ${bestHabit.name} (${(bestHabit.progress * 100).round()}%)'),
                  _Line(text: 'أسوأ عادة: ${worstHabit.name} (${(worstHabit.progress * 100).round()}%)'),
                  _Line(text: 'عادة مقترحة للإضافة: مراجعة سريعة 3 دقائق قبل النوم'),
                  _Line(
                    text: worstHabit.progress < 0.35
                        ? 'عادة مقترح حذفها: ${worstHabit.name} (غير مناسبة حاليًا)'
                        : 'لا يوجد حذف مقترح هذا الأسبوع',
                  ),
                  const SizedBox(height: 8),
                  const _MiniChart(values: _weeklyTrend),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'نظام المكافآت (Gamification)',
              subtitle: 'نقاط + شارات + مستويات + إنجازات خاصة.',
              c1: const Color(0xFF6D28D9),
              c2: const Color(0xFF9333EA),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _Badge(label: 'النقاط', value: '$_totalPoints')),
                      const SizedBox(width: 8),
                      Expanded(child: _Badge(label: 'المستوى', value: _level)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Badge(
                          label: 'شارة',
                          value: _habits.any((h) => h.streak >= 30) ? '30 يوم التزام' : 'واصل التقدم',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'وضع التركيز (Focus Mode)',
              subtitle: 'مؤقت + موسيقى تركيز + تقييم بسيط بالنهاية.',
              c1: const Color(0xFF111827),
              c2: const Color(0xFF374151),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [15, 25, 45].map((m) {
                      return ChoiceChip(
                        label: Text('$m دقيقة'),
                        selected: _focusMinutes == m,
                        selectedColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: _focusMinutes == m ? const Color(0xFF111827) : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) {
                          setState(() => _focusMinutes = m);
                          _saveState();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _focusMusic,
                    dropdownColor: const Color(0xFF0F172A),
                    decoration: _input('موسيقى التركيز'),
                    items: const [
                      DropdownMenuItem(value: 'Lo-fi Focus', child: Text('Lo-fi Focus', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Deep Piano', child: Text('Deep Piano', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Rain Ambience', child: Text('Rain Ambience', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (v) {
                      setState(() => _focusMusic = v ?? _focusMusic);
                      _saveState();
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _focusRemainingSeconds > 0 ? _formatFocusTime(_focusRemainingSeconds) : 'جاهز للبدء',
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startFocus,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('ابدأ'),
                          style: _solid(const Color(0xFF111827)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _stopFocus,
                          icon: const Icon(Icons.stop),
                          label: const Text('إيقاف'),
                          style: _outline(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'اقتراح عادة حسب المزاج اليومي',
              subtitle: 'خمول؟ يعطيك عادة خفيفة. متحمس؟ يعطيك عادة قوية.',
              c1: const Color(0xFFBE123C),
              c2: const Color(0xFFE11D48),
              child: Column(
                children: [
                  TextField(
                    controller: _moodController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _input('مثال: اليوم أحس بخمول / اليوم متحمس'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _suggestByMood,
                      icon: const Icon(Icons.bolt_outlined),
                      label: const Text('اقترح عادة الآن'),
                      style: _solid(const Color(0xFF9F1239)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TextBox(text: _moodSuggestion),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  ButtonStyle _solid(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  ButtonStyle _outline() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );
  }
}
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.c1,
    required this.c2,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color c1;
  final Color c2;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [c1, c2],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TextBox extends StatelessWidget {
  const _TextBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, height: 1.45)),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  const _MiniChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: values[index].clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${index + 1}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

enum _RoutineGoal {
  sleep('تحسين نوم'),
  productivity('زيادة إنتاجية'),
  skill('تطوير مهارة');

  const _RoutineGoal(this.label);
  final String label;
}

class _HabitItem {
  const _HabitItem({
    required this.name,
    required this.progress,
    required this.streak,
  });

  final String name;
  final double progress;
  final int streak;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'progress': progress,
      'streak': streak,
    };
  }

  factory _HabitItem.fromJson(Map<String, dynamic> json) {
    return _HabitItem(
      name: (json['name'] ?? '').toString(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
    );
  }

  _HabitItem copyWith({double? progress, int? streak}) {
    return _HabitItem(
      name: name,
      progress: progress ?? this.progress,
      streak: streak ?? this.streak,
    );
  }
}

class _ChallengeItem {
  const _ChallengeItem({required this.title, required this.done});

  final String title;
  final bool done;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'done': done,
    };
  }

  factory _ChallengeItem.fromJson(Map<String, dynamic> json) {
    return _ChallengeItem(
      title: (json['title'] ?? '').toString(),
      done: (json['done'] as bool?) ?? false,
    );
  }

  _ChallengeItem copyWith({bool? done}) {
    return _ChallengeItem(title: title, done: done ?? this.done);
  }
}

enum _HobbyLevel {
  beginner('مبتدئ'),
  intermediate('متوسط'),
  advanced('محترف');

  const _HobbyLevel(this.label);
  final String label;
}

class _HobbyItem {
  const _HobbyItem({
    required this.name,
    required this.level,
    required this.todayTip,
  });

  final String name;
  final _HobbyLevel level;
  final String todayTip;
}










