import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/home_style_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const String _kHabitsKey = 'habits_data_v1';
  static const String _kChallengesKey = 'habits_challenges_v1';
  static const String _kCommitCurrentKey = 'progress_commitment_current_v1';
  static const String _kCommitPreviousKey = 'progress_commitment_previous_v1';
  static const String _kProgressPagesKey = 'progress_read_pages_weekly_v1';
  static const String _kProgressLearningHoursKey = 'progress_learning_hours_weekly_v1';
  static const String _kProgressReadingStreakKey = 'progress_read_streak_days_v1';
  static const String _kProgressWorkoutHoursKey = 'progress_workout_hours_weekly_v1';
  static const String _kProgressExerciseDaysKey = 'progress_exercise_days_weekly_v1';
  static const String _kProgressFitnessCommitmentKey =
      'progress_fitness_commitment_v1';
  static const String _kProgressHabitsCompletionKey =
      'progress_habits_completion_v1';
  static const String _kProgressHabitsStreakAvgKey =
      'progress_habits_streak_avg_v1';
  static const String _kProgressHabitsChallengesDoneKey =
      'progress_habits_challenges_done_v1';
  static const String _kProgressHabitsChallengesTotalKey =
      'progress_habits_challenges_total_v1';
  static const String _kProgressTasksDoneKey = 'progress_tasks_done_count_v1';
  static const String _kProgressTasksTotalKey = 'progress_tasks_total_count_v1';
  static const String _kProgressTasksCompletionKey =
      'progress_tasks_completion_v1';
  static const String _kTasksFocusHoursKey = 'daily_tasks_focus_hours_v1';

  int _period = 1; // 0 يومي - 1 أسبوعي - 2 شهري
  String _reason = 'ضغط عمل';
  bool _loading = true;

  int _weeklyHabits = 74;
  double _weeklyHours = 12.4;
  int _weeklyPages = 146;
  int _weeklyCommitment = 84;
  int _weeklyDelta = 8;
  int _averageStreak = 6;
  int _exerciseDays = 3;
  int _learningDone = 10;
  int _learningTotal = 12;

  static const _periods = ['يومي', 'أسبوعي', 'شهري'];
  static const _goals = [
    {'h': 'أسبوعي', 't': '3 تمارين + 50 صفحة', 'p': 0.78, 'r': 'متبقي تمرين و 11 صفحة'},
    {'h': 'شهري', 't': 'إنهاء كتاب + تحسين النوم', 'p': 0.63, 'r': 'متبقي 120 صفحة'},
    {'h': 'سنوي', 't': 'تعلّم لغة + خسارة وزن', 'p': 0.42, 'r': 'متبقي 7 مستويات + 8 كجم'},
  ];
  static const _achievements = [
    'أكملت 7 أيام متواصلة',
    'أول 100 صفحة قراءة',
    'أول 10 ساعات تمرين',
    'أول شهر التزام',
  ];

  static const _solutions = {
    'ضغط عمل': ['خلّ العادة أصغر.', 'غيّر وقتها لوقت ثابت بعد الدوام.', 'ابدأ بعادة واحدة فقط.'],
    'نوم قليل': ['قدّم النوم 20 دقيقة يومياً.', 'امنع الكافيين مساءً.', 'خفف العادة المجهدة ليلاً.'],
    'نسيان': ['اربطها بعادة ثانية.', 'فعّل تذكير ثابت.', 'ضع مؤشر بصري واضح.'],
    'ملل': ['غيّر صيغة العادة.', 'بدّل المكان أو المدة.', 'أضف مكافأة بسيطة.'],
  };

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final habitsJson = prefs.getString(_kHabitsKey);
      final challengesJson = prefs.getString(_kChallengesKey);
      final directPages = prefs.getInt(_kProgressPagesKey);
      final directLearningHours = prefs.getDouble(_kProgressLearningHoursKey);
      final directReadingStreak = prefs.getInt(_kProgressReadingStreakKey);
      final directWorkoutHours = prefs.getDouble(_kProgressWorkoutHoursKey);
      final directExerciseDays = prefs.getInt(_kProgressExerciseDaysKey);
      final directFitnessCommitment = prefs.getInt(_kProgressFitnessCommitmentKey);
      final directHabitsCompletion = prefs.getInt(_kProgressHabitsCompletionKey);
      final directHabitsStreak = prefs.getInt(_kProgressHabitsStreakAvgKey);
      final directChallengesDone = prefs.getInt(_kProgressHabitsChallengesDoneKey);
      final directChallengesTotal = prefs.getInt(_kProgressHabitsChallengesTotalKey);
      final directTasksDone = prefs.getInt(_kProgressTasksDoneKey);
      final directTasksTotal = prefs.getInt(_kProgressTasksTotalKey);
      final directTasksCompletion = prefs.getInt(_kProgressTasksCompletionKey);
      final tasksFocusHours = prefs.getDouble(_kTasksFocusHoursKey);

      final habits = habitsJson == null
          ? const <_HabitSnapshot>[]
          : (jsonDecode(habitsJson) as List<dynamic>)
                .map((e) => _HabitSnapshot.fromJson(e as Map<String, dynamic>))
                .toList();

      final challenges = challengesJson == null
          ? const <_ChallengeSnapshot>[]
          : (jsonDecode(challengesJson) as List<dynamic>)
                .map((e) => _ChallengeSnapshot.fromJson(e as Map<String, dynamic>))
                .toList();

      final computedHabitCompletion = habits.isEmpty
          ? _weeklyHabits
          : ((habits.map((h) => h.progress).reduce((a, b) => a + b) / habits.length) * 100)
              .round()
              .clamp(0, 100);
      final habitCompletion = (directHabitsCompletion ?? computedHabitCompletion).clamp(0, 100);

      final computedAvgStreak = habits.isEmpty
          ? _averageStreak
          : (habits.map((h) => h.streak).reduce((a, b) => a + b) / habits.length).round();
      final avgStreak = (directHabitsStreak ?? computedAvgStreak).clamp(0, 999);

      final challengeRate = (directChallengesDone != null && directChallengesTotal != null && directChallengesTotal > 0)
          ? (directChallengesDone / directChallengesTotal)
          : challenges.isEmpty
          ? 0.6
          : challenges.where((c) => c.done).length / challenges.length;
      final tasksCompletionRate = (directTasksCompletion != null)
          ? (directTasksCompletion / 100).clamp(0.0, 1.0)
          : (directTasksDone != null && directTasksTotal != null && directTasksTotal > 0)
              ? (directTasksDone / directTasksTotal).clamp(0.0, 1.0)
              : 0.65;

      final commitmentFromHabits = (habitCompletion * 0.5 +
              challengeRate * 100 * 0.2 +
              tasksCompletionRate * 100 * 0.2 +
              ((avgStreak / 14) * 100).clamp(0, 100) * 0.1)
          .round()
          .clamp(0, 100);

      final exerciseHabits = habits
          .where((h) => _containsAny(h.name, ['تمرين', 'رياض', 'مشي', 'جري', 'لياقة']))
          .toList();
      final readingHabits = habits
          .where((h) => _containsAny(h.name, ['قراءة', 'كتاب', 'تعلم', 'تعلّم', 'دراسة']))
          .toList();

      final estimatedHours = exerciseHabits.isEmpty
          ? (4 + habitCompletion / 25).clamp(2, 16).toDouble()
          : exerciseHabits
              .map((h) => (h.progress * 2.8) + (h.streak.clamp(0, 7) * 0.4))
              .fold<double>(0, (a, b) => a + b)
              .clamp(2, 18)
              .toDouble();

      final estimatedPages = readingHabits.isEmpty
          ? (habitCompletion * 1.4).round().clamp(15, 260)
          : readingHabits
              .map((h) => (h.progress * 42 + h.streak * 3.5).round())
              .fold<int>(0, (a, b) => a + b)
              .clamp(15, 320);

      final estimatedExerciseDays =
          exerciseHabits.where((h) => h.progress >= 0.45).length.clamp(1, 7);
      final learningTotal = readingHabits.isEmpty ? 12 : (readingHabits.length * 4).clamp(4, 20);
      final learningDone = readingHabits.isEmpty
          ? (learningTotal * (habitCompletion / 100)).round().clamp(0, learningTotal)
          : (readingHabits
                  .map((h) => (h.progress * 4).round().clamp(0, 4))
                  .fold<int>(0, (a, b) => a + b))
              .clamp(0, learningTotal);

      final weeklyHours = (directLearningHours ?? 0) +
          (directWorkoutHours ?? 0) +
          ((tasksFocusHours ?? 0) * 5);
      final normalizedHours = weeklyHours > 0 ? weeklyHours : estimatedHours;
      final weeklyPages = directPages ?? estimatedPages;
      final exerciseDays = directExerciseDays ?? estimatedExerciseDays;
      final avgStreakForProgress = directReadingStreak ?? avgStreak;

      final commitment = directFitnessCommitment != null
          ? ((commitmentFromHabits * 0.7) + (directFitnessCommitment * 0.3))
              .round()
              .clamp(0, 100)
          : commitmentFromHabits;

      final previousCurrent = prefs.getInt(_kCommitCurrentKey);
      final previousFallback =
          prefs.getInt(_kCommitPreviousKey) ?? (commitment - 7).clamp(0, 100);
      final baseline = previousCurrent ?? previousFallback;
      final delta = (commitment - baseline).clamp(-100, 100);

      await prefs.setInt(_kCommitPreviousKey, baseline);
      await prefs.setInt(_kCommitCurrentKey, commitment);

      if (!mounted) return;
      setState(() {
        _weeklyHabits = habitCompletion;
        _weeklyHours = normalizedHours;
        _weeklyPages = weeklyPages;
        _weeklyCommitment = commitment;
        _weeklyDelta = delta;
        _averageStreak = avgStreakForProgress.clamp(0, 999);
        _exerciseDays = exerciseDays;
        _learningTotal = learningTotal;
        _learningDone = learningDone;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool _containsAny(String text, List<String> words) {
    final t = text.toLowerCase();
    return words.any((w) => t.contains(w.toLowerCase()));
  }

  Map<String, dynamic> _summaryForPeriod(int p) {
    if (p == 0) {
      return {
        'habits': (_weeklyHabits * 0.9).round().clamp(0, 100),
        'hours': (_weeklyHours / 7).toStringAsFixed(1),
        'pages': (_weeklyPages / 7).round(),
        'commit': (_weeklyCommitment * 0.92).round().clamp(0, 100),
        'delta': (_weeklyDelta / 2).round(),
      };
    }
    if (p == 2) {
      return {
        'habits': (_weeklyHabits * 0.96).round().clamp(0, 100),
        'hours': (_weeklyHours * 4).toStringAsFixed(1),
        'pages': _weeklyPages * 4,
        'commit': (_weeklyCommitment * 0.97).round().clamp(0, 100),
        'delta': (_weeklyDelta * 2).clamp(-100, 100),
      };
    }
    return {
      'habits': _weeklyHabits,
      'hours': _weeklyHours.toStringAsFixed(1),
      'pages': _weeklyPages,
      'commit': _weeklyCommitment,
      'delta': _weeklyDelta,
    };
  }

  List<String> _buildInsights(int habits, int commit, int pages) {
    final List<String> items = [];
    items.add('مستوى الالتزام الحالي $commit% بناءً على بيانات عاداتك الفعلية.');
    if (habits >= 75) {
      items.add('التزامك بالعادات الصباحية ممتاز. استمر على نفس توقيت البداية.');
    } else {
      items.add('الالتزام أقل من المطلوب. جرّب تصغير العادة بدل إيقافها.');
    }
    if (_weeklyDelta >= 0) {
      items.add('أداؤك أفضل من الفترة السابقة بمقدار ${_weeklyDelta.abs()}%.');
    } else {
      items.add('هناك تراجع ${_weeklyDelta.abs()}% عن الفترة السابقة، عدّل وقت التنفيذ.');
    }
    if (pages >= 100) {
      items.add('القراءة مرتفعة هذا الأسبوع. مناسب ترفع هدف الصفحات تدريجياً.');
    } else {
      items.add('رفع القراءة 10-15 دقيقة يومياً سيحسّن منحنى التقدم.');
    }
    return items;
  }

  List<Map<String, dynamic>> _buildDomains(int habits, int commit, int pages) {
    final healthTrainRatio = (_exerciseDays / 4).clamp(0.0, 1.0);
    final stepsRatio = (_weeklyHours / 14).clamp(0.0, 1.0);
    final sleepRatio = ((commit * 0.85) / 100).clamp(0.0, 1.0);
    final learnTimeRatio = (_weeklyHours / 16).clamp(0.0, 1.0);
    final lessonsRatio = (_learningDone / _learningTotal).clamp(0.0, 1.0);
    final streakRatio = (_averageStreak / 20).clamp(0.0, 1.0);
    final hobbyTimeRatio = ((_weeklyHours * 0.35) / 6).clamp(0.0, 1.0);
    final hobbyProgressRatio = ((commit * 0.78) / 100).clamp(0.0, 1.0);

    return [
      {
        'n': 'الصحة',
        'c': const Color(0xFF14B8A6),
        'm': ['الخطوات ${(_weeklyHours * 620).round()}/10000', 'النوم ${(sleepRatio * 8).toStringAsFixed(1)}h/8h', 'أيام التمرين $_exerciseDays/4'],
        'v': [stepsRatio, sleepRatio, healthTrainRatio],
        'a': 'التحليل: نشاطك البدني مرتبط مباشرة بارتفاع الالتزام العام.',
      },
      {
        'n': 'التعلم',
        'c': const Color(0xFF3B82F6),
        'm': ['وقت الدراسة ${_weeklyHours.toStringAsFixed(1)}h/16h', 'الدروس $_learningDone/$_learningTotal'],
        'v': [learnTimeRatio, lessonsRatio],
        'a': 'التحليل: زيادة جلسات قصيرة يومية ترفع معدل إكمال الدروس.',
      },
      {
        'n': 'العادات',
        'c': const Color(0xFF22C55E),
        'm': ['سلسلة الأيام $_averageStreak', 'نسبة الالتزام $habits%'],
        'v': [streakRatio, habits / 100],
        'a': 'التحليل: ثبات وقت العادة أهم من طولها في الحفاظ على الاستمرارية.',
      },
      {
        'n': 'الهوايات',
        'c': const Color(0xFFF59E0B),
        'm': ['وقت الممارسة ${(hobbyTimeRatio * 6).toStringAsFixed(1)}h/6h', 'مستوى التقدم ${(hobbyProgressRatio * 100).round()}%'],
        'v': [hobbyTimeRatio, hobbyProgressRatio],
        'a': 'التحليل: التقدم يتحسن عندما توزّع الممارسة على أيام أكثر.',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = _summaryForPeriod(_period);
    final habits = s['habits'] as int;
    final hours = s['hours'].toString();
    final pages = s['pages'] as int;
    final commit = s['commit'] as int;
    final delta = s['delta'] as int;
    final up = delta >= 0;
    final energy = (habits * .35 + commit * .35 + ((double.parse(hours) / 14) * 100).clamp(0, 100) * .2 + ((pages / 200) * 100).clamp(0, 100) * .1)
        .round()
        .clamp(1, 100);
    final domains = _buildDomains(habits, commit, pages);
    final insights = _buildInsights(habits, commit, pages);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF051523),
        appBar: AppBar(
          backgroundColor: const Color(0xFF051523),
          elevation: 0,
          centerTitle: true,
          title: const Text('تابع تقدمك', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              onPressed: _loadProgressData,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'تحديث البيانات',
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B2235), Color(0xFF051523)]),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _card(child: Row(children: [
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('مؤشر الطاقة اليومية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('مبني على النوم، العادات، النشاط، ووقت الشاشة.', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                      ])),
                      CircleAvatar(radius: 34, backgroundColor: Colors.white10, child: Text('$energy', style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w900, fontSize: 23))),
                    ])),
                    const SizedBox(height: 12),
                    _card(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: List.generate(
                          _periods.length,
                          (i) => Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _period = i),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(color: _period == i ? const Color(0xFF1D4E70) : Colors.transparent, borderRadius: BorderRadius.circular(9)),
                                child: Text(_periods[i], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _title('نظرة شاملة على التقدم'),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: _metric('نسبة إنجاز العادات', '$habits%')), const SizedBox(width: 8), Expanded(child: _metric('ساعات تمرين/تعلم', hours))]),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: _metric('الصفحات المقروءة', '$pages')), const SizedBox(width: 8), Expanded(child: _metric('مستوى الالتزام', '$commit%'))]),
                    const SizedBox(height: 8),
                    _card(child: Row(children: [Icon(up ? Icons.arrow_upward : Icons.arrow_downward, color: up ? const Color(0xFF22C55E) : const Color(0xFFEF4444)), const SizedBox(width: 6), Expanded(child: Text(up ? 'أسبوعك أفضل من الفترة السابقة بـ ${delta.abs()}%' : 'أسبوعك أقل من الفترة السابقة بـ ${delta.abs()}%', style: TextStyle(color: up ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontWeight: FontWeight.w700)))])),
                    const SizedBox(height: 14),
                    _title('رسوم بيانية ذكية'),
                    const SizedBox(height: 8),
                    ...domains.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _card(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(d['n'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              ...List.generate((d['m'] as List).length, (i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 7),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text((d['m'] as List)[i].toString(), style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                                      const SizedBox(height: 4),
                                      ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: (d['v'] as List<double>)[i], minHeight: 8, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(d['c'] as Color))),
                                    ]),
                                  )),
                              Text(d['a'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                            ]),
                          ),
                        )),
                    _title('تحليلات ذكية (AI Insights)'),
                    const SizedBox(height: 8),
                    _card(
                      gradient: const [Color(0xFF1E3A8A), Color(0xFF0F3B7A)],
                      child: Column(
                        children: insights
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.auto_awesome, color: Colors.white, size: 16), const SizedBox(width: 6), Expanded(child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 13)))]),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _title('أهداف قصيرة وطويلة المدى'),
                    const SizedBox(height: 8),
                    ..._goals.map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _card(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF1D4ED8), borderRadius: BorderRadius.circular(99)), child: Text(g['h'] as String, style: const TextStyle(color: Colors.white, fontSize: 12))), const SizedBox(width: 8), Expanded(child: Text(g['t'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), Text('${((g['p'] as double) * 100).round()}%', style: const TextStyle(color: Colors.white70))]),
                            const SizedBox(height: 8),
                            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: g['p'] as double, minHeight: 8, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation(Color(0xFF22C55E)))),
                            const SizedBox(height: 6),
                            Text('المتبقي: ${g['r']}', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                            const SizedBox(height: 2),
                            const Text('اقتراح: اربط هدفك بوقت ثابت يومي.', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12.5)),
                          ])),
                        )),
                    _title('نظام الإنجازات'),
                    const SizedBox(height: 8),
                    _card(child: Wrap(spacing: 8, runSpacing: 8, children: _achievements.map((e) => Chip(backgroundColor: const Color(0xFF133048), side: const BorderSide(color: Colors.white24), avatar: const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 18), label: Text(e, style: const TextStyle(color: Colors.white)))).toList())),
                    const SizedBox(height: 14),
                    _title('مقارنة بين الفترات'),
                    const SizedBox(height: 8),
                    _card(child: Column(children: [const _CmpRow('هذا الأسبوع مقابل السابق', 'يعتمد على آخر مزامنة فعلية', '', true), _CmpRow('هذا الشهر مقابل الماضي', '${(_weeklyCommitment * 0.97).round()}% مقابل ${(_weeklyCommitment * 0.94).round()}%', '${((_weeklyCommitment * 0.97).round() - (_weeklyCommitment * 0.94).round()) > 0 ? '+' : ''}${((_weeklyCommitment * 0.97).round() - (_weeklyCommitment * 0.94).round())}%', ((_weeklyCommitment * 0.97).round() - (_weeklyCommitment * 0.94).round()) >= 0), _CmpRow('الصباح مقابل المساء', '${(_weeklyHabits * 1.04).round().clamp(0, 100)}% مقابل ${(_weeklyHabits * 0.85).round().clamp(0, 100)}%', '+${((_weeklyHabits * 1.04).round().clamp(0, 100) - (_weeklyHabits * 0.85).round().clamp(0, 100)).abs()}%', true)])),
                    const SizedBox(height: 14),
                    _title('تحليل أسباب التراجع'),
                    const SizedBox(height: 8),
                    _card(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('وش سبب التراجع؟', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: ['ضغط عمل', 'نوم قليل', 'نسيان', 'ملل'].map((r) => ChoiceChip(label: Text(r), selected: _reason == r, selectedColor: const Color(0xFF1D4ED8), backgroundColor: const Color(0xFF133048), labelStyle: const TextStyle(color: Colors.white), onSelected: (_) => setState(() => _reason = r))).toList()),
                        const SizedBox(height: 8),
                        ...(_solutions[_reason] ?? []).map((v) => Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lightbulb, color: Color(0xFFF59E0B), size: 16), const SizedBox(width: 6), Expanded(child: Text(v, style: const TextStyle(color: Colors.white70, fontSize: 12.5)))]),
                            )),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    _title('ربط التقدم بباقي الأقسام'),
                    const SizedBox(height: 8),
                    _card(child: const Column(children: [_LinkRow('إذا قل نومه', 'يقترح تعديل وقت التمرين.'), _LinkRow('إذا زاد وقت الشاشة', 'يقترح عادة تهدئة.'), _LinkRow('إذا زاد وقت القراءة', 'يقترح كتاب جديد.'), _LinkRow('إذا تحسن المزاج', 'يقترح عادة أقوى.')])),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _title(String t) => Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17));

  Widget _metric(String label, String value) => _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      );

  Widget _card({required Widget child, List<Color>? gradient, EdgeInsetsGeometry padding = const EdgeInsets.all(12)}) {
    return HomeStyleCard(
      padding: padding,
      accentA: gradient?.first ?? const Color(0xFF0EA5E9),
      accentB: gradient?.last ?? const Color(0xFF1E293B),
      child: child,
    );
  }
}

class _HabitSnapshot {
  const _HabitSnapshot({required this.name, required this.progress, required this.streak});

  final String name;
  final double progress;
  final int streak;

  factory _HabitSnapshot.fromJson(Map<String, dynamic> json) {
    return _HabitSnapshot(
      name: (json['name'] ?? '').toString(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
    );
  }
}

class _ChallengeSnapshot {
  const _ChallengeSnapshot({required this.done});

  final bool done;

  factory _ChallengeSnapshot.fromJson(Map<String, dynamic> json) {
    return _ChallengeSnapshot(done: (json['done'] as bool?) ?? false);
  }
}

class _CmpRow extends StatelessWidget {
  const _CmpRow(this.label, this.values, this.delta, this.up);
  final String label;
  final String values;
  final String delta;
  final bool up;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), if (values.isNotEmpty) Text(values, style: const TextStyle(color: Colors.white70, fontSize: 12.5))])),
          if (delta.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: up ? const Color(0x3322C55E) : const Color(0x33EF4444), borderRadius: BorderRadius.circular(99)),
              child: Text(delta, style: TextStyle(color: up ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontWeight: FontWeight.w800)),
            ),
        ]),
      );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow(this.a, this.b);
  final String a;
  final String b;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.link, color: Color(0xFF93C5FD), size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text('$a: $b', style: const TextStyle(color: Colors.white70, fontSize: 12.5))),
        ]),
      );
}
