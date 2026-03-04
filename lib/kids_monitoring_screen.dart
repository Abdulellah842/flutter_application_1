import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'widgets/home_style_card.dart';

class KidsMonitoringScreen extends StatefulWidget {
  const KidsMonitoringScreen({super.key});

  @override
  State<KidsMonitoringScreen> createState() => _KidsMonitoringScreenState();
}

class _KidsMonitoringScreenState extends State<KidsMonitoringScreen> {
  final List<_ChildProfile> _children = <_ChildProfile>[
    _ChildProfile(name: 'سالم', age: 9),
    _ChildProfile(name: 'ليان', age: 12),
  ];

  final TextEditingController _lessonTitleController = TextEditingController();
  final TextEditingController _lessonNotesController = TextEditingController();
  final TextEditingController _allowedAppsController = TextEditingController(
    text: 'تطبيق الدراسة فقط',
  );

  int _selectedChildIndex = 0;
  int _tabIndex = 0;

  _Subject _selectedSubject = _Subject.math;
  int _studyMinutes = 35;
  int _gamesMinutes = 45;
  TimeOfDay _sleepTime = const TimeOfDay(hour: 21, minute: 30);

  bool _blockUnsafeSites = true;
  bool _blockInappropriateContent = true;
  bool _screenTimeMonitoring = true;
  bool _alertOnBlockedAttempts = true;
  bool _sharedStudyMode = false;

  final List<String> _notifications = <String>[];

  @override
  void initState() {
    super.initState();
    _seedNotifications();
  }

  @override
  void dispose() {
    _lessonTitleController.dispose();
    _lessonNotesController.dispose();
    _allowedAppsController.dispose();
    super.dispose();
  }

  _ChildProfile get _child => _children[_selectedChildIndex];

  void _seedNotifications() {
    _notifications.addAll(const <String>[
      'تنبيه: سالم أنهى درس العلوم.',
      'تنبيه: ليان فشلت في الكويز الأخير.',
      'تنبيه: تم فتح جهاز سالم بعد نجاح الكويز.',
    ]);
  }

  void _pushNotification(String message) {
    setState(() {
      _notifications.insert(0, 'تنبيه: $message');
      if (_notifications.length > 18) {
        _notifications.removeRange(18, _notifications.length);
      }
    });
  }

  void _lockDevice() {
    setState(() {
      _child.deviceState = _DeviceState.locked;
    });
    _pushNotification('${_child.name} الجهاز مقفول بواسطة ولي الأمر.');
  }

  void _unlockDevice() {
    setState(() {
      _child.deviceState = _DeviceState.unlocked;
    });
    _pushNotification('${_child.name} الجهاز مفتوح.');
  }

  void _setStudyOnlyMode() {
    setState(() {
      _child.deviceState = _DeviceState.studyOnly;
      _child.inStudyWindow = true;
    });
    _pushNotification(
      '${_child.name} دخل وضع الدراسة (منع كل شيء عدا تطبيق الدراسة).',
    );
  }

  void _uploadLesson() {
    final title = _lessonTitleController.text.trim();
    if (title.isEmpty) {
      _showSnack('اكتب عنوان الدرس أولًا.');
      return;
    }

    setState(() {
      _child.lastLesson = _LessonPlan(
        title: title,
        subject: _selectedSubject,
        notes: _lessonNotesController.text.trim().isEmpty
            ? 'صورة مرفوعة من الكتاب.'
            : _lessonNotesController.text.trim(),
        studyMinutes: _studyMinutes,
      );
      _child.inStudyWindow = true;
      _child.deviceState = _DeviceState.studyOnly;
      _child.lastAssistantExplanation = '';
      _child.lastQuizResult = null;
      _lessonTitleController.clear();
      _lessonNotesController.clear();
    });

    _pushNotification('تم رفع درس "${_child.lastLesson!.title}" لـ ${_child.name}.');
  }

  void _generateAssistantExplanation() {
    final lesson = _child.lastLesson;
    if (lesson == null) {
      _showSnack('ارفع درسًا أولًا قبل طلب الشرح.');
      return;
    }

    final level = _detectLevel(_child.age, _child.recentAccuracy);
    final explanation = _buildExplanation(lesson, level, simplified: false);

    setState(() {
      _child.lastAssistantExplanation = explanation;
      _child.lastQuiz = _buildQuizForLesson(lesson, level, easier: false);
    });

    _pushNotification('${_child.name} بدأ شرح درس ${lesson.subject.label}.');
  }

  void _childAskForSimplerExplanation() {
    final lesson = _child.lastLesson;
    if (lesson == null) return;
    final level = _detectLevel(_child.age, _child.recentAccuracy);

    setState(() {
      _child.lastAssistantExplanation = _buildExplanation(
        lesson,
        level,
        simplified: true,
      );
      _child.lastQuiz = _buildQuizForLesson(lesson, level, easier: true);
    });

    _pushNotification('${_child.name} طلب إعادة شرح مبسط.');
  }

  void _setQuizAnswer(int index, String value) {
    final quiz = _child.lastQuiz;
    if (quiz == null) return;
    setState(() {
      quiz.answers[index] = value.trim();
    });
  }

  void _submitQuiz() {
    final quiz = _child.lastQuiz;
    if (quiz == null) {
      _showSnack('لا يوجد كويز متاح الآن.');
      return;
    }

    final answeredCount = quiz.answers.where((a) => a.trim().isNotEmpty).length;
    if (answeredCount < quiz.questions.length) {
      _showSnack('أكمل إجابة جميع أسئلة الكويز.');
      return;
    }

    var correct = 0;
    for (var i = 0; i < quiz.questions.length; i++) {
      final expected = quiz.questions[i].correct.trim().toLowerCase();
      final answer = quiz.answers[i].trim().toLowerCase();
      if (expected == answer) {
        correct++;
      }
    }

    final total = quiz.questions.length;
    final ratio = total == 0 ? 0 : correct / total;
    final passed = ratio >= 0.7;
    final usedMinutes = math.max(
      8,
      (_child.lastLesson?.studyMinutes ?? 30) - (passed ? 3 : -5),
    );
    final focus = math.max(0.2, math.min(1.0, ratio + 0.12));

    setState(() {
      _child.totalQuizzes += 1;
      _child.totalCorrectAnswers += correct;
      _child.totalAnswers += total;
      _child.recentAccuracy = ((_child.recentAccuracy * 2) + ratio) / 3;
      _child.lastQuizResult = _QuizResult(
        score: correct,
        total: total,
        passed: passed,
        tookMinutes: usedMinutes,
        focusScore: focus,
      );
      _child.studyProgress = (_child.studyProgress + (passed ? 12 : 4))
          .clamp(0, 100);

      if (passed) {
        _child.deviceState = _DeviceState.unlocked;
        _child.inStudyWindow = false;
        _child.successiveFailures = 0;
        _child.weeklyWins += 1;
        _child.extraPlayMinutes += _child.weeklyWins >= 5 ? 15 : 5;
        if (_child.weeklyWins >= 5 &&
            !_child.badges.contains('وسام أسبوع الالتزام')) {
          _child.badges.add('وسام أسبوع الالتزام');
        }
      } else {
        _child.successiveFailures += 1;
        _child.deviceState = _DeviceState.studyOnly;
        _child.inStudyWindow = true;
      }
    });

    if (passed) {
      _pushNotification(
        '${_child.name} نجح في الكويز ($correct/$total) وتم فتح الجهاز.',
      );
    } else {
      _pushNotification(
        '${_child.name} فشل في الكويز ($correct/$total) والجهاز بقي مقفول/محدود.',
      );
      _assignRecoveryPlan();
    }
  }

  void _assignRecoveryPlan() {
    final lesson = _child.lastLesson;
    if (lesson == null) return;
    final level = _detectLevel(_child.age, _child.recentAccuracy);

    setState(() {
      _child.lastAssistantExplanation =
          'خطة تبسيط: نعيد الفكرة بأمثلة أقل وتعريفات أوضح ثم كويز أسهل.';
      _child.lastQuiz = _buildQuizForLesson(lesson, level, easier: true);
      _child.simplificationPlan = _child.successiveFailures >= 2
          ? 'تقليل المحتوى إلى 10 دقائق يوميًا + سؤالين فقط في البداية.'
          : 'إعادة شرح مختصر ثم كويز أسهل.';
    });
  }

  void _simulateBlockedAttempt() {
    if (!_alertOnBlockedAttempts) return;
    _pushNotification('${_child.name} حاول فتح محتوى ممنوع وتم منعه.');
  }

  String _buildExplanation(
    _LessonPlan lesson,
    _AdaptiveLevel level, {
    required bool simplified,
  }) {
    final simple = switch (level) {
      _AdaptiveLevel.beginner =>
        'شرح بسيط ولطيف يناسب العمر الصغير مع أمثلة من الحياة اليومية.',
      _AdaptiveLevel.standard =>
        'شرح متوازن مع أمثلة مباشرة وأسئلة تحقق أثناء الشرح.',
      _AdaptiveLevel.advanced =>
        'شرح أعمق مع ربط المفهوم بأسئلة تفكير وتحليل.',
    };

    final extra = simplified
        ? 'نسخة مبسطة: نجزئ الدرس إلى 3 نقاط قصيرة، وبعد كل نقطة سؤال سريع.'
        : 'خطة الشرح: مقدمة قصيرة، مثالين، ثم سؤال فهم قبل الانتقال.';

    return 'درس ${lesson.subject.label}: ${lesson.title}.\n'
        '$simple\n'
        '$extra\n'
        'مثال: ${lesson.notes.isEmpty ? 'مثال من الكتاب المرفوع.' : lesson.notes}';
  }

  _AdaptiveLevel _detectLevel(int age, double accuracy) {
    if (age <= 8 || accuracy < 0.45) return _AdaptiveLevel.beginner;
    if (age >= 13 && accuracy >= 0.75) return _AdaptiveLevel.advanced;
    return _AdaptiveLevel.standard;
  }

  _QuizSet _buildQuizForLesson(
    _LessonPlan lesson,
    _AdaptiveLevel level, {
    required bool easier,
  }) {
    final count = easier ? 3 : 5;
    final shortLabel = lesson.subject.shortLabel;

    final q = <_QuizQuestion>[
      _QuizQuestion(
        text: 'اختيار: ما الفكرة الأساسية في درس "$shortLabel"؟',
        type: _QuizType.mcq,
        options: const <String>['المفهوم الرئيسي', 'قصة جانبية', 'عنوان الدفتر'],
        correct: 'المفهوم الرئيسي',
      ),
      const _QuizQuestion(
        text: 'صح/خطأ: الأمثلة تساعد على فهم الدرس.',
        type: _QuizType.trueFalse,
        options: <String>['صح', 'خطأ'],
        correct: 'صح',
      ),
      _QuizQuestion(
        text: 'سؤال قصير: اكتب كلمة تلخص الدرس.',
        type: _QuizType.short,
        options: const <String>[],
        correct: easier ? 'فهم' : 'المفهوم',
      ),
      const _QuizQuestion(
        text: 'اختيار: متى نراجع الدرس إذا أخطأنا؟',
        type: _QuizType.mcq,
        options: <String>['فورًا', 'بعد أسبوع', 'لا نراجع'],
        correct: 'فورًا',
      ),
      const _QuizQuestion(
        text: 'صح/خطأ: يمكن طلب إعادة الشرح عند عدم الفهم.',
        type: _QuizType.trueFalse,
        options: <String>['صح', 'خطأ'],
        correct: 'صح',
      ),
    ];

    if (level == _AdaptiveLevel.beginner && !easier) {
      q[2] = const _QuizQuestion(
        text: 'سؤال قصير: اكتب "فهمت" إذا كنت جاهز.',
        type: _QuizType.short,
        options: <String>[],
        correct: 'فهمت',
      );
    }

    return _QuizSet(
      questions: q.take(count).toList(),
      answers: List<String>.filled(count, ''),
      easierVersion: easier,
    );
  }

  Widget _buildParentDashboard(ThemeData theme) {
    return ListView(
      key: const ValueKey<String>('parent'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      children: [
        _sectionTitle(theme, 'لوحة تحكم الأهل'),
        const SizedBox(height: 8),
        _buildChildSelector(theme),
        const SizedBox(height: 12),
        _buildChildStatusCard(theme),
        const SizedBox(height: 12),
        _buildDeviceControlCard(theme),
        const SizedBox(height: 12),
        _buildLessonSetupCard(theme),
        const SizedBox(height: 12),
        _buildProtectionCard(theme),
        const SizedBox(height: 12),
        _buildReportsCard(theme),
        const SizedBox(height: 12),
        _buildNotificationsCard(theme),
      ],
    );
  }

  Widget _buildChildView(ThemeData theme) {
    final lesson = _child.lastLesson;

    return ListView(
      key: const ValueKey<String>('child'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      children: [
        _sectionTitle(theme, 'تطبيق الطفل'),
        const SizedBox(height: 8),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحبًا ${_child.name}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                lesson == null
                    ? 'بانتظار ولي الأمر لرفع الدرس.'
                    : 'الدرس الحالي: ${lesson.title} (${lesson.subject.label})',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chipState('حالة الجهاز', _child.deviceState.label),
                  _chipState(
                    'وقت الدراسة',
                    '${lesson?.studyMinutes ?? _studyMinutes} دقيقة',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'شرح المساعد الدراسي',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _child.lastAssistantExplanation.isEmpty
                    ? 'لم يبدأ الشرح بعد. اطلب من ولي الأمر بدء الشرح.'
                    : _child.lastAssistantExplanation,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _generateAssistantExplanation,
                    icon: const Icon(Icons.record_voice_over_rounded),
                    label: const Text('ابدأ الشرح'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _childAskForSimplerExplanation,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('ما فهمت - أعد الشرح'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildQuizCard(theme),
      ],
    );
  }

  Widget _buildChildSelector(ThemeData theme) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختيار الطفل',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(_children.length, (i) {
              final active = _selectedChildIndex == i;
              return ChoiceChip(
                label: Text('${_children[i].name} (${_children[i].age} سنة)'),
                selected: active,
                selectedColor: const Color(0xFF1D4ED8),
                labelStyle: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                onSelected: (_) => setState(() => _selectedChildIndex = i),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildChildStatusCard(ThemeData theme) {
    final lastQuiz = _child.lastQuizResult;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حالة ${_child.name}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricBox('الجهاز', _child.deviceState.label),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricBox('التقدم الدراسي', '${_child.studyProgress}%'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  'آخر درس',
                  _child.lastLesson?.title ?? 'لا يوجد',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricBox(
                  'آخر كويز',
                  lastQuiz == null ? 'لا يوجد' : '${lastQuiz.score}/${lastQuiz.total}',
                ),
              ),
            ],
          ),
          if (_sharedStudyMode) ...[
            const SizedBox(height: 10),
            Text(
              'الدراسة المشتركة: بث شاشة الطفل مفعل للمتابعة المباشرة.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade200,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceControlCard(ThemeData theme) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التحكم بالجهاز',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(onPressed: _lockDevice, child: const Text('قفل الجهاز')),
              ElevatedButton(onPressed: _unlockDevice, child: const Text('فتح الجهاز')),
              ElevatedButton(
                onPressed: _setStudyOnlyMode,
                child: const Text('وضع وقت الدراسة'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            style: const TextStyle(color: Colors.white),
            controller: _allowedAppsController,
            decoration: _inputDecoration('التطبيقات المسموحة فقط'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Text(
            'وقت الألعاب: $_gamesMinutes دقيقة',
            style: const TextStyle(color: Colors.white70),
          ),
          Slider(
            value: _gamesMinutes.toDouble(),
            min: 10,
            max: 180,
            divisions: 17,
            label: '$_gamesMinutes',
            activeColor: const Color(0xFF22C55E),
            onChanged: (v) => setState(() => _gamesMinutes = v.round()),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'وقت النوم: ${_sleepTime.format(context)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _sleepTime,
                  );
                  if (picked == null) return;
                  setState(() => _sleepTime = picked);
                },
                child: const Text('تعديل'),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _sharedStudyMode,
            onChanged: (v) => setState(() => _sharedStudyMode = v),
            title: const Text(
              'تفعيل الدراسة المشتركة (بث شاشة الطفل)',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonSetupCard(ThemeData theme) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'رفع الدرس وتحديده',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _lessonTitleController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('عنوان الدرس'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<_Subject>(
            initialValue: _selectedSubject,
            dropdownColor: const Color(0xFF111827),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('المادة'),
            items: _Subject.values
                .map(
                  (s) => DropdownMenuItem<_Subject>(
                    value: s,
                    child: Text(s.label),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedSubject = v);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _lessonNotesController,
            style: const TextStyle(color: Colors.white),
            minLines: 2,
            maxLines: 3,
            decoration: _inputDecoration('وصف الصورة/النص المرفوع من الكتاب'),
          ),
          const SizedBox(height: 8),
          Text(
            'وقت الدراسة: $_studyMinutes دقيقة',
            style: const TextStyle(color: Colors.white70),
          ),
          Slider(
            value: _studyMinutes.toDouble(),
            min: 15,
            max: 120,
            divisions: 21,
            activeColor: const Color(0xFF3B82F6),
            onChanged: (v) => setState(() => _studyMinutes = v.round()),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _uploadLesson,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('رفع الدرس'),
              ),
              ElevatedButton.icon(
                onPressed: _generateAssistantExplanation,
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('اطلب شرح المساعد للطفل'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionCard(ThemeData theme) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حماية الطفل',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _blockUnsafeSites,
            onChanged: (v) => setState(() => _blockUnsafeSites = v),
            title: const Text(
              'منع المواقع الخطرة',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _blockInappropriateContent,
            onChanged: (v) => setState(() => _blockInappropriateContent = v),
            title: const Text(
              'منع المحتوى غير المناسب',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _screenTimeMonitoring,
            onChanged: (v) => setState(() => _screenTimeMonitoring = v),
            title: const Text(
              'مراقبة وقت الشاشة',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _alertOnBlockedAttempts,
            onChanged: (v) => setState(() => _alertOnBlockedAttempts = v),
            title: const Text(
              'تنبيه عند محاولة فتح محتوى ممنوع',
              style: TextStyle(color: Colors.white),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _simulateBlockedAttempt,
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('محاكاة محاولة ممنوعة'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsCard(ThemeData theme) {
    final quiz = _child.lastQuizResult;
    final accuracy = _child.totalAnswers == 0
        ? 0
        : ((_child.totalCorrectAnswers / _child.totalAnswers) * 100).round();

    final needsReview = quiz == null ? 'غير واضح' : (quiz.passed ? 'لا' : 'نعم');
    final focusLevel = quiz == null
        ? '-'
        : quiz.focusScore >= 0.75
            ? 'مركز'
            : quiz.focusScore >= 0.5
                ? 'متوسط التركيز'
                : 'مشتت';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التقارير الذكية للأهل',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تقرير آخر درس:',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quiz == null
                ? 'لا يوجد اختبار منتهي بعد.'
                : 'الفهم: ${quiz.passed ? 'ممتاز' : 'يحتاج دعم'} | الوقت: ${quiz.tookMinutes} دقيقة | الإجابات الصحيحة: ${quiz.score}/${quiz.total} | يحتاج مراجعة: $needsReview | التركيز: $focusLevel',
            style: const TextStyle(color: Colors.white70),
          ),
          const Divider(color: Colors.white24, height: 24),
          Text(
            'تقرير أسبوعي مختصر:',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'المواد التي تحتاج دعم: ${_weakSubjects(accuracy)}\n'
            'المواد المبدع فيها: ${_strongSubjects(accuracy)}\n'
            'اقتراحات: ${_tipsForParent(accuracy)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const Divider(color: Colors.white24, height: 24),
          Text(
            'نظام المكافآت:',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'عدد النجاحات الأسبوعية: ${_child.weeklyWins}\n'
            'وقت لعب إضافي: ${_child.extraPlayMinutes} دقيقة\n'
            'الأوسمة: ${_child.badges.isEmpty ? 'لا يوجد' : _child.badges.join('، ')}\n'
            'خطة التبسيط: ${_child.simplificationPlan.isEmpty ? 'غير مطلوبة حاليًا' : _child.simplificationPlan}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard(ThemeData theme) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإشعارات الفورية',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_notifications.isEmpty)
            const Text(
              'لا توجد إشعارات حالية.',
              style: TextStyle(color: Colors.white70),
            ),
          ..._notifications.take(6).map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $n', style: const TextStyle(color: Colors.white70)),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(ThemeData theme) {
    final quiz = _child.lastQuiz;
    if (quiz == null) {
      return _card(
        child: Text(
          'بعد الشرح سيظهر الكويز الذكي هنا (3-5 أسئلة من نفس الدرس).',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quiz.easierVersion ? 'الكويز الذكي (نسخة أسهل)' : 'الكويز الذكي',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...List<Widget>.generate(quiz.questions.length, (i) {
            final q = quiz.questions[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}) ${q.text}', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 6),
                  if (q.type == _QuizType.short)
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('إجابة قصيرة'),
                      onChanged: (v) => _setQuizAnswer(i, v),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: q.options
                          .map(
                            (o) => ChoiceChip(
                              label: Text(o),
                              selected: quiz.answers[i] == o,
                              selectedColor: const Color(0xFF1D4ED8),
                              backgroundColor: Colors.white.withValues(alpha: 0.06),
                              labelStyle: TextStyle(
                                color: quiz.answers[i] == o
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                              onSelected: (_) => _setQuizAnswer(i, o),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitQuiz,
              icon: const Icon(Icons.task_alt_rounded),
              label: const Text('إنهاء الكويز'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return HomeStyleCard(
      padding: const EdgeInsets.all(12),
      accentA: const Color(0xFF3B82F6),
      accentB: const Color(0xFF1E293B),
      child: child,
    );
  }

  Widget _metricBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _chipState(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text('$title: $value', style: const TextStyle(color: Colors.white70)),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  String _weakSubjects(int accuracy) {
    if (accuracy >= 75) return 'لا يوجد ضعف واضح حاليًا';
    if (_selectedSubject == _Subject.math) return 'الرياضيات';
    if (_selectedSubject == _Subject.science) return 'العلوم';
    return '${_selectedSubject.label} (يحتاج مراجعة إضافية)';
  }

  String _strongSubjects(int accuracy) {
    if (accuracy >= 80) return 'ممتاز في ${_selectedSubject.label}';
    if (accuracy >= 60) return 'يتقدم جيدًا في القرآن واللغة العربية';
    return 'الجانب العملي والأنشطة القصيرة';
  }

  String _tipsForParent(int accuracy) {
    if (accuracy >= 80) {
      return 'رفع مستوى الأسئلة تدريجيًا + مكافأة أسبوعية ثابتة.';
    }
    if (accuracy >= 60) {
      return 'جلسات 20 دقيقة + مراجعة سريعة قبل الكويز.';
    }
    return 'تقسيم الدرس إلى نقاط قصيرة + كويز أسهل + متابعة يومية.';
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
          centerTitle: true,
          title: const Text(
            'مراقبة الأبناء',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('لوحة الأهل'),
                      selected: _tabIndex == 0,
                      selectedColor: const Color(0xFF1D4ED8),
                      labelStyle: TextStyle(
                        color: _tabIndex == 0 ? Colors.white : Colors.white70,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      onSelected: (_) => setState(() => _tabIndex = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('تطبيق الطفل'),
                      selected: _tabIndex == 1,
                      selectedColor: const Color(0xFF1D4ED8),
                      labelStyle: TextStyle(
                        color: _tabIndex == 1 ? Colors.white : Colors.white70,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      onSelected: (_) => setState(() => _tabIndex = 1),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _tabIndex == 0
                    ? _buildParentDashboard(theme)
                    : _buildChildView(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DeviceState { locked, unlocked, studyOnly }

extension on _DeviceState {
  String get label {
    switch (this) {
      case _DeviceState.locked:
        return 'مقفول';
      case _DeviceState.unlocked:
        return 'مفتوح';
      case _DeviceState.studyOnly:
        return 'محدود للدراسة';
    }
  }
}

enum _Subject {
  math('رياضيات', 'رياضيات'),
  science('علوم', 'علوم'),
  quran('قرآن', 'قرآن'),
  arabic('لغة عربية', 'عربي'),
  english('لغة إنجليزية', 'English');

  const _Subject(this.label, this.shortLabel);
  final String label;
  final String shortLabel;
}

enum _AdaptiveLevel { beginner, standard, advanced }

enum _QuizType { mcq, trueFalse, short }

class _LessonPlan {
  const _LessonPlan({
    required this.title,
    required this.subject,
    required this.notes,
    required this.studyMinutes,
  });

  final String title;
  final _Subject subject;
  final String notes;
  final int studyMinutes;
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.text,
    required this.type,
    required this.options,
    required this.correct,
  });

  final String text;
  final _QuizType type;
  final List<String> options;
  final String correct;
}

class _QuizSet {
  const _QuizSet({
    required this.questions,
    required this.answers,
    required this.easierVersion,
  });

  final List<_QuizQuestion> questions;
  final List<String> answers;
  final bool easierVersion;
}

class _QuizResult {
  const _QuizResult({
    required this.score,
    required this.total,
    required this.passed,
    required this.tookMinutes,
    required this.focusScore,
  });

  final int score;
  final int total;
  final bool passed;
  final int tookMinutes;
  final double focusScore;
}

class _ChildProfile {
  _ChildProfile({
    required this.name,
    required this.age,
    List<String>? badges,
  }) : badges = badges ?? <String>[];

  final String name;
  final int age;

  _DeviceState deviceState = _DeviceState.locked;
  bool inStudyWindow = false;

  _LessonPlan? lastLesson;
  String lastAssistantExplanation = '';
  _QuizSet? lastQuiz;
  _QuizResult? lastQuizResult;

  int studyProgress = 0;
  double recentAccuracy = 0.55;

  int weeklyWins = 0;
  int extraPlayMinutes = 0;
  int successiveFailures = 0;

  int totalQuizzes = 0;
  int totalCorrectAnswers = 0;
  int totalAnswers = 0;

  String simplificationPlan = '';
  final List<String> badges;
}



