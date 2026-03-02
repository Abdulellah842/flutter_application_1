import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key});

  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen> {
  static const String _kProgressWorkoutHoursKey = 'progress_workout_hours_weekly_v1';
  static const String _kProgressExerciseDaysKey = 'progress_exercise_days_weekly_v1';
  static const String _kProgressFitnessCommitmentKey =
      'progress_fitness_commitment_v1';

  _FitnessGoal _selectedGoal = _FitnessGoal.generalFitness;
  final TextEditingController _goalDetailsController = TextEditingController();
  List<String> _generatedPlan = _defaultPlan;
  List<_ChallengeItem> _challenges = _initialChallenges;
  final Set<int> _activeReminderIds = <int>{};
  double _weeklyWorkoutHours = 5.0;
  int _exerciseDays = 3;
  int _fitnessCommitment = 84;

  static const List<_SmartReminder> _smartReminders = [
    _SmartReminder(
      id: 201,
      title: 'يوم دوام طويل',
      detail: 'أفضل وقت: 8:30 مساءً | تمرين خفيف 25 دقيقة',
      icon: Icons.nightlight_round,
      time: TimeOfDay(hour: 20, minute: 30),
    ),
    _SmartReminder(
      id: 202,
      title: 'يوم مرن / عمل من المنزل',
      detail: 'أفضل وقت: 7:00 صباحًا | كارديو 30 دقيقة',
      icon: Icons.wb_sunny,
      time: TimeOfDay(hour: 7, minute: 0),
    ),
    _SmartReminder(
      id: 203,
      title: 'قبل اجتماع مهم',
      detail: 'أفضل وقت: 4:00 عصرًا | Mobility 15 دقيقة',
      icon: Icons.event_available,
      time: TimeOfDay(hour: 16, minute: 0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    NotificationService.instance.requestPermissions();
    _loadProgressState();
  }

  Future<void> _loadProgressState() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutHours = prefs.getDouble(_kProgressWorkoutHoursKey);
    final exerciseDays = prefs.getInt(_kProgressExerciseDaysKey);
    final fitnessCommitment = prefs.getInt(_kProgressFitnessCommitmentKey);
    if (!mounted) return;
    setState(() {
      if (workoutHours != null) {
        _weeklyWorkoutHours = workoutHours.clamp(0.5, 40);
      }
      if (exerciseDays != null) {
        _exerciseDays = exerciseDays.clamp(0, 7);
      }
      if (fitnessCommitment != null) {
        _fitnessCommitment = fitnessCommitment.clamp(0, 100);
      }
    });
  }

  Future<void> _saveProgressState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
      _kProgressWorkoutHoursKey,
      _weeklyWorkoutHours.clamp(0.5, 40),
    );
    await prefs.setInt(_kProgressExerciseDaysKey, _exerciseDays.clamp(0, 7));
    await prefs.setInt(
      _kProgressFitnessCommitmentKey,
      _fitnessCommitment.clamp(0, 100),
    );
  }

  void _syncFromChallenges() {
    final done = _challenges.where((c) => c.done).length;
    final total = _challenges.isEmpty ? 1 : _challenges.length;
    _exerciseDays = done.clamp(1, 7);
    _fitnessCommitment = ((done / total) * 100).round().clamp(0, 100);
    _weeklyWorkoutHours = (_exerciseDays * 1.4).clamp(1.0, 20.0);
  }

  @override
  void dispose() {
    _goalDetailsController.dispose();
    super.dispose();
  }

  void _generatePlan() {
    final details = _goalDetailsController.text.trim();
    final basePlan = switch (_selectedGoal) {
      _FitnessGoal.weightLoss => <String>[
        'الإثنين: 35 دقيقة مشي سريع + 12 دقيقة تمارين مقاومة خفيفة',
        'الأربعاء: HIIT منخفض الشدة 20 دقيقة + إطالة 10 دقائق',
        'الجمعة: 40 دقيقة كارديو متدرج + تمارين بطن 10 دقائق',
        'السبت: نشاط حر (دراجة/مشي) 30 دقيقة',
      ],
      _FitnessGoal.muscleGain => <String>[
        'الإثنين: الجزء العلوي (صدر + ظهر) 45 دقيقة',
        'الثلاثاء: الجزء السفلي (أرجل + Glutes) 45 دقيقة',
        'الخميس: كتف + ذراع 40 دقيقة',
        'السبت: Full Body مركب 35 دقيقة',
      ],
      _FitnessGoal.flexibility => <String>[
        'الأحد: Mobility للجسم كامل 20 دقيقة',
        'الثلاثاء: يوغا مرونة وظهر 30 دقيقة',
        'الخميس: إطالة ديناميكية + توازن 25 دقيقة',
        'السبت: Recovery Stretch 20 دقيقة',
      ],
      _FitnessGoal.generalFitness => <String>[
        'الإثنين: كارديو متوسط 25 دقيقة',
        'الأربعاء: مقاومة وزن الجسم 30 دقيقة',
        'الجمعة: كارديو + Core 30 دقيقة',
        'الأحد: جلسة مرونة واستشفاء 20 دقيقة',
      ],
    };

    final customizedNote = details.isEmpty
        ? 'توصية ذكية: حافظ على يوم راحة بين الجلسات المكثفة.'
        : 'تخصيص حسب هدفك: $details';

    setState(() {
      _generatedPlan = [...basePlan, customizedNote];
      _weeklyWorkoutHours = switch (_selectedGoal) {
        _FitnessGoal.weightLoss => 5.0,
        _FitnessGoal.muscleGain => 5.5,
        _FitnessGoal.flexibility => 3.5,
        _FitnessGoal.generalFitness => 4.5,
      };
      _exerciseDays = basePlan.length.clamp(1, 7);
      _fitnessCommitment = ((_exerciseDays / 6) * 100).round().clamp(0, 100);
    });
    _saveProgressState();
  }

  Future<void> _setReminder(_SmartReminder reminder, bool enabled) async {
    if (enabled) {
      await NotificationService.instance.scheduleDailyReminder(
        id: reminder.id,
        title: 'تذكير تمرين: ${reminder.title}',
        body: reminder.detail,
        time: reminder.time,
      );
      setState(() {
        _activeReminderIds.add(reminder.id);
      });
      _showSnackBar('تم تفعيل تذكير ${reminder.title} يوميًا.');
    } else {
      await NotificationService.instance.cancelReminder(reminder.id);
      setState(() {
        _activeReminderIds.remove(reminder.id);
      });
      _showSnackBar('تم إيقاف تذكير ${reminder.title}.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleChallenge(int index, bool? value) {
    setState(() {
      _challenges = List<_ChallengeItem>.from(_challenges);
      _challenges[index] = _challenges[index].copyWith(done: value ?? false);
      _syncFromChallenges();
    });
    _saveProgressState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0F1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0F1E),
          elevation: 0,
          title: const Text(
            'الصحة والتمارين',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Text(
              'لوحة اللياقة الذكية',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'خطط مخصصة، اقتراح توقيت مناسب، وتحليل واضح لتقدمك.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: '1) خطط التمرين المخصصة',
              subtitle: 'اختر هدفك وسيتم توليد جدول أسبوعي مناسب كبداية.',
              color1: const Color(0xFF0F766E),
              color2: const Color(0xFF14B8A6),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _FitnessGoal.values.map((goal) {
                      return ChoiceChip(
                        label: Text(goal.label),
                        selected: _selectedGoal == goal,
                        selectedColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          color: _selectedGoal == goal
                              ? const Color(0xFF0F766E)
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedGoal = goal;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _goalDetailsController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'مثال: أقدر أتمرن فقط 4 أيام بعد الساعة 6 مساءً',
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generatePlan,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('توليد خطة ذكية'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F766E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._generatedPlan.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Icon(Icons.check_circle, size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(color: Colors.white, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '2) التذكيرات الذكية',
              subtitle: 'اقتراح وقت التمرين حسب سياق يوم المستخدم.',
              color1: const Color(0xFF1D4ED8),
              color2: const Color(0xFF60A5FA),
              child: Column(
                children: _smartReminders.map((reminder) {
                  return _SmartReminderTile(
                    title: reminder.title,
                    detail: reminder.detail,
                    icon: reminder.icon,
                    isEnabled: _activeReminderIds.contains(reminder.id),
                    onChanged: (value) => _setReminder(reminder, value),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '3) تحليل تقدمك الصحي',
              subtitle: 'عرض مرئي بسيط يوضح مستوى الإنجاز الأسبوعي.',
              color1: const Color(0xFF7C3AED),
              color2: const Color(0xFFA78BFA),
              child: Column(
                children: [
                  _ProgressBars(
                    values: [
                      (_fitnessCommitment * 0.006).clamp(0.15, 1.0),
                      (_fitnessCommitment * 0.007).clamp(0.15, 1.0),
                      (_fitnessCommitment * 0.0082).clamp(0.15, 1.0),
                      (_fitnessCommitment * 0.009).clamp(0.15, 1.0),
                      (_fitnessCommitment * 0.0085).clamp(0.15, 1.0),
                      (_fitnessCommitment * 0.01).clamp(0.15, 1.0),
                      (_fitnessCommitment * 0.0092).clamp(0.15, 1.0),
                    ],
                    labels: ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricChip(label: 'الجلسات', value: '$_exerciseDays/6'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricChip(label: 'الإلتزام', value: '$_fitnessCommitment%'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricChip(
                          label: 'ساعات',
                          value: '${_weeklyWorkoutHours.toStringAsFixed(1)}h',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '4) تحديات قصيرة',
              subtitle: 'لمسة تفاعلية يومية تزيد الحماس.',
              color1: const Color(0xFFF97316),
              color2: const Color(0xFFFB7185),
              child: Column(
                children: List.generate(_challenges.length, (index) {
                  final challenge = _challenges[index];
                  return CheckboxListTile(
                    value: challenge.done,
                    activeColor: Colors.white,
                    checkColor: const Color(0xFFF97316),
                    tileColor: Colors.black.withValues(alpha: 0.16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    title: Text(
                      challenge.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      challenge.subtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onChanged: (value) => _toggleChallenge(index, value),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.color1,
    required this.color2,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color color1;
  final Color color2;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SmartReminderTile extends StatelessWidget {
  const _SmartReminderTile({
    required this.title,
    required this.detail,
    required this.icon,
    required this.isEnabled,
    required this.onChanged,
  });

  final String title;
  final String detail;
  final IconData icon;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ProgressBars extends StatelessWidget {
  const _ProgressBars({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
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
                  const SizedBox(height: 6),
                  Text(
                    labels[index],
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
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

class _SmartReminder {
  const _SmartReminder({
    required this.id,
    required this.title,
    required this.detail,
    required this.icon,
    required this.time,
  });

  final int id;
  final String title;
  final String detail;
  final IconData icon;
  final TimeOfDay time;
}

enum _FitnessGoal {
  generalFitness('لياقة عامة'),
  weightLoss('إنقاص وزن'),
  muscleGain('بناء عضل'),
  flexibility('مرونة');

  const _FitnessGoal(this.label);
  final String label;
}

class _ChallengeItem {
  const _ChallengeItem({
    required this.title,
    required this.subtitle,
    required this.done,
  });

  final String title;
  final String subtitle;
  final bool done;

  _ChallengeItem copyWith({bool? done}) {
    return _ChallengeItem(
      title: title,
      subtitle: subtitle,
      done: done ?? this.done,
    );
  }
}

const List<String> _defaultPlan = [
  'اختر هدفك واضغط توليد خطة لبدء جدول مخصص.',
];

const List<_ChallengeItem> _initialChallenges = [
  _ChallengeItem(
    title: 'تحدي 7 دقائق حركة',
    subtitle: 'نفّذ أي تمارين خفيفة لمدة 7 دقائق الآن.',
    done: false,
  ),
  _ChallengeItem(
    title: 'تحدي 10 آلاف خطوة',
    subtitle: 'قسّمها على اليوم مع 3 جولات مشي قصيرة.',
    done: false,
  ),
  _ChallengeItem(
    title: 'تحدي شرب الماء',
    subtitle: 'أكمل 8 أكواب ماء قبل نهاية اليوم.',
    done: false,
  ),
];


