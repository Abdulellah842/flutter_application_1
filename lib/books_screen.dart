import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  static const String _kProgressPagesKey = 'progress_read_pages_weekly_v1';
  static const String _kProgressLearningHoursKey = 'progress_learning_hours_weekly_v1';
  static const String _kProgressReadingStreakKey = 'progress_read_streak_days_v1';

  final TextEditingController _sourceTextController = TextEditingController();
  final TextEditingController _deepExplainController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController(text: '6');
  final FlutterTts _tts = FlutterTts();
  final ImagePicker _imagePicker = ImagePicker();

  String _pickedSource = 'لم يتم اختيار ملف بعد';
  String _instantSummary =
      'ارفع PDF أو صوّر صفحة، ثم اضغط "لخّص الآن" للحصول على ملخص فوري.';
  bool _isReadingSummary = false;
  _LearningGoal _selectedGoal = _LearningGoal.language;
  List<String> _weeklyPlan = const [
    'اختر الهدف والوقت المتاح ليتم توليد خطة أسبوعية مخصصة.',
  ];
  int _dailyPages = 18;
  int _streakDays = 6;
  String _deepExplanation =
      'اكتب فقرة غير واضحة، وسأشرحها لك بأسلوب مبسط مع مثال وتشبيه.';
  String _quizResult = 'أجب على 5 أسئلة لتحصل على تقييم فهمك.';

  static const List<_BookProgress> _bookProgress = [
    _BookProgress(title: 'العادات الذرية', progress: 0.72),
    _BookProgress(title: 'Deep Work', progress: 0.44),
    _BookProgress(title: 'فن اللامبالاة', progress: 0.88),
  ];

  static const List<double> _monthlyReadingBars = [
    0.25,
    0.3,
    0.42,
    0.35,
    0.48,
    0.55,
    0.6,
    0.74,
    0.78,
    0.69,
    0.86,
    0.92,
  ];

  final List<_QuizQuestion> _quiz = const [
    _QuizQuestion(
      question: 'ما الفكرة المركزية في الكتاب؟',
      correctOption: 1,
      options: ['تفاصيل ثانوية', 'فكرة واحدة متكررة بطرق مختلفة', 'قصة المؤلف فقط'],
    ),
    _QuizQuestion(
      question: 'أي سلوك يقترحه الكاتب كبداية عملية؟',
      correctOption: 2,
      options: ['تغيير كل شيء مباشرة', 'لا يوجد تطبيق', 'تغيير صغير ثابت يوميًا'],
    ),
    _QuizQuestion(
      question: 'لماذا ركّز الكاتب على الأمثلة الواقعية؟',
      correctOption: 0,
      options: ['لتسهيل نقل الفكرة للتطبيق', 'لزيادة حجم الكتاب', 'لأنه لا يملك نظرية'],
    ),
    _QuizQuestion(
      question: 'ما الخطأ الشائع الذي حذّر منه؟',
      correctOption: 2,
      options: ['النوم الجيد', 'تنظيم الوقت', 'الاعتماد على الحماس فقط'],
    ),
    _QuizQuestion(
      question: 'أفضل طريقة للاستفادة بعد إنهاء الكتاب؟',
      correctOption: 1,
      options: ['البدء بكتاب جديد فورًا', 'كتابة نقاط قابلة للتطبيق أسبوعيًا', 'إعادة الغلاف'],
    ),
  ];

  late final List<int?> _answers = List<int?>.filled(5, null);

  static const List<_MicroCard> _microCards = [
    _MicroCard(type: 'معلومة', text: 'القراءة 20 دقيقة يوميًا تعني ~12 كتابًا سنويًا.'),
    _MicroCard(type: 'مفهوم', text: 'التكرار المتباعد يرفع الاحتفاظ بالمعلومة لفترة أطول.'),
    _MicroCard(type: 'قاعدة', text: '1 فكرة + 1 تطبيق عملي بعد كل جلسة قراءة.'),
    _MicroCard(type: 'اقتباس', text: '"نحن ما نكرره يوميًا" - أرسطو (منسوبًا).'),
    _MicroCard(type: 'فكرة', text: 'اختصر كل فصل في 3 أسطر، ثم راجعه نهاية الأسبوع.'),
  ];

  @override
  void initState() {
    super.initState();
    _setupTts();
    _loadProgressState();
  }

  Future<void> _loadProgressState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPages = prefs.getInt(_kProgressPagesKey);
    final savedHours = prefs.getDouble(_kProgressLearningHoursKey);
    final savedStreak = prefs.getInt(_kProgressReadingStreakKey);
    if (!mounted) return;
    setState(() {
      if (savedPages != null) {
        _dailyPages = (savedPages / 7).round().clamp(1, 999);
      }
      if (savedHours != null) {
        _hoursController.text = savedHours.round().toString();
      }
      if (savedStreak != null) {
        _streakDays = savedStreak.clamp(0, 999);
      }
    });
  }

  Future<void> _saveProgressState() async {
    final prefs = await SharedPreferences.getInstance();
    final weeklyPages = (_dailyPages * 7).clamp(1, 9999).toInt();
    final weeklyLearningHours =
        (int.tryParse(_hoursController.text.trim()) ?? 6).toDouble().clamp(1, 80).toDouble();
    await prefs.setInt(_kProgressPagesKey, weeklyPages);
    await prefs.setDouble(_kProgressLearningHoursKey, weeklyLearningHours);
    await prefs.setInt(_kProgressReadingStreakKey, _streakDays.clamp(0, 999).toInt());
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('ar');
    await _tts.setSpeechRate(0.47);
    await _tts.setPitch(1.0);
    _tts.setStartHandler(() {
      if (!mounted) return;
      setState(() => _isReadingSummary = true);
    });
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() => _isReadingSummary = false);
    });
    _tts.setCancelHandler(() {
      if (!mounted) return;
      setState(() => _isReadingSummary = false);
    });
    _tts.setErrorHandler((_) {
      if (!mounted) return;
      setState(() => _isReadingSummary = false);
    });
  }

  @override
  void dispose() {
    _sourceTextController.dispose();
    _deepExplainController.dispose();
    _notesController.dispose();
    _hoursController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 78,
    );
    if (image == null) return;

    setState(() => _pickedSource = 'صورة: ${image.name}');
    _showSnack('تم التقاط الصورة بنجاح.');
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    setState(() => _pickedSource = 'PDF: ${file.name}');
    _showSnack('تم رفع ملف PDF بنجاح.');
  }

  void _generateInstantSummary() {
    final input = _sourceTextController.text.trim();
    final seedText = input.isEmpty
        ? 'المحتوى المرفوع يركّز على فكرة رئيسية مع تطبيقات عملية قابلة للتنفيذ.'
        : input;
    final short = seedText.length > 280 ? '${seedText.substring(0, 280)}...' : seedText;

    setState(() {
      _instantSummary = 'ملخص فوري من $_pickedSource:\n\n'
          '1) الفكرة الأساسية: ${_extractFocus(short)}\n'
          '2) أهم النقاط:\n'
          '- ${_buildBullet(short, 0)}\n'
          '- ${_buildBullet(short, 1)}\n'
          '- ${_buildBullet(short, 2)}\n'
          '3) تطبيق سريع: اكتب خطوة عملية واحدة تنفذها اليوم.';
    });
  }

  String _extractFocus(String text) {
    if (text.contains('لغة')) return 'تعلم تدريجي مبني على الممارسة اليومية.';
    if (text.contains('مهارة')) return 'تطوير المهارة يكون عبر تكرار مقصود وتغذية راجعة.';
    if (text.contains('عادة')) return 'التحسن الصغير المستمر يصنع فارقًا كبيرًا.';
    return 'تبسيط الفكرة الكبيرة إلى خطوات يومية قابلة للتنفيذ.';
  }

  String _buildBullet(String text, int index) {
    final chunks = text
        .split(RegExp(r'[\.!؟\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (chunks.isEmpty) return 'نقطة مركزة قابلة للتطبيق.';
    return chunks[index % chunks.length];
  }

  Future<void> _toggleReadSummary() async {
    if (_isReadingSummary) {
      await _tts.stop();
      return;
    }
    await _tts.speak(_instantSummary);
  }

  void _generateWeeklyPlan() {
    final hours = int.tryParse(_hoursController.text.trim()) ?? 6;
    final perDay = (hours * 60 / 7).round();

    final plan = switch (_selectedGoal) {
      _LearningGoal.language => <String>[
          'الأحد: مفردات + استماع ($perDay دقيقة).',
          'الاثنين: قراءة نص قصير + تلخيص صوتي.',
          'الثلاثاء: محادثة عملية + مراجعة كلمات.',
          'الأربعاء: قواعد أساسية + تمارين تطبيقية.',
          'الخميس: مشاهدة محتوى تعليمي باللغة الهدف.',
          'الجمعة: اختبار مصغر + تصحيح الأخطاء.',
          'السبت: مراجعة أسبوعية للنقاط الضعيفة.',
        ],
      _LearningGoal.skill => <String>[
          'اليوم 1-2: تعلم المفهوم ثم تطبيق سريع.',
          'اليوم 3: مشروع مصغر 30-45 دقيقة.',
          'اليوم 4: تحليل الأخطاء و3 تحسينات.',
          'اليوم 5: تدريب مركز على نقطة ضعف.',
          'اليوم 6: محاكاة تحدٍ واقعي.',
          'اليوم 7: مراجعة وخطة الأسبوع القادم.',
        ],
      _LearningGoal.tenBooks => <String>[
          'الهدف الأسبوعي: 70-90 صفحة على 5 أيام.',
          'جلسات قصيرة: 20-30 دقيقة بعد المهام الرئيسية.',
          'يوم مراجعة: استخراج 5 أفكار قابلة للتطبيق.',
          'نهاية الأسبوع: اختبار فهم + ملاحظات.',
          'خطة شهرية: إنهاء 1 كتاب كل 4-5 أسابيع.',
        ],
    };

    setState(() {
      _weeklyPlan = [
        'الهدف: ${_selectedGoal.label} | وقتك الأسبوعي: $hours ساعة',
        ...plan,
      ];
    });
    _saveProgressState();
  }

  void _explainDeeply() {
    final text = _deepExplainController.text.trim();
    if (text.isEmpty) {
      _showSnack('اكتب فقرة أولاً.');
      return;
    }

    setState(() {
      _deepExplanation = 'شرح مبسط:\n'
          '${_simpleExplain(text)}\n\n'
          'مثال واقعي:\n'
          '${_realExample(text)}\n\n'
          'تشبيه يساعد الفهم:\n'
          '${_analogy(text)}';
    });
  }

  String _simpleExplain(String text) {
    return 'المقطع يشرح فكرة تُبنى تدريجيًا، والمعنى العملي هو تقسيمها لخطوات صغيرة بدل محاولة إتقانها دفعة واحدة.';
  }

  String _realExample(String text) {
    return 'بدل قراءة فصل كامل ثم التوقف، طبّق فكرة واحدة مباشرة اليوم وراجع نتيجتها غدًا.';
  }

  String _analogy(String text) {
    return 'تعلم الفكرة مثل بناء عضلة: تمرين قصير يومي أفضل من تمرين قاسٍ مرة واحدة.';
  }
  void _evaluateQuiz() {
    final answered = _answers.whereType<int>().length;
    if (answered < _quiz.length) {
      _showSnack('أكمل كل الأسئلة الخمسة أولاً.');
      return;
    }

    var score = 0;
    for (var i = 0; i < _quiz.length; i++) {
      if (_answers[i] == _quiz[i].correctOption) score++;
    }

    final result = switch (score) {
      >= 4 => 'فهم ممتاز ($score/5)\nاستمر بنفس الأسلوب.',
      2 || 3 => 'جيد لكن يحتاج مراجعة ($score/5).',
      _ => 'يحتاج مراجعة ($score/5).',
    };

    setState(() {
      _quizResult = '$result\n\nنقاط قد تكون نُسيت:\n'
          '- الفكرة الأساسية\n'
          '- المثال التطبيقي\n'
          '- خطوة التنفيذ اليومية';
    });
  }

  String _summarizeNotes(String text) {
    if (text.trim().isEmpty) return 'اكتب ملاحظاتك أولاً ليتم تنظيمها.';
    return 'ملخص الملاحظات المنظّم:\n\n'
        'أفكار مهمة:\n'
        '- ${_buildBullet(text, 0)}\n'
        '- ${_buildBullet(text, 1)}\n\n'
        'اقتباسات:\n'
        '- "${_buildBullet(text, 2)}"\n\n'
        'نقاط قابلة للتطبيق:\n'
        '- تنفيذ 20 دقيقة يوميًا.\n'
        '- مراجعة أسبوعية لما تم تعلمه.';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF090D1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF090D1A),
          elevation: 0,
          title: const Text(
            'الكتب والتعلّم',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Text(
              'لوحة التعلّم الذكي',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ملخصات فورية، خطة شخصية، تتبع قراءة، واختبارات قصيرة.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            _FeatureCard(
              title: 'ملخصات فورية بالذكاء الاصطناعي',
              subtitle: 'تصوير صفحة أو رفع PDF ثم توليد ملخص فوري + ملخص صوتي.',
              c1: const Color(0xFF0F766E),
              c2: const Color(0xFF22C55E),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('تصوير صفحة'),
                          style: _outlineStyle(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickPdf,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('رفع PDF'),
                          style: _outlineStyle(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'المصدر الحالي: $_pickedSource',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sourceTextController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('اختياري: الصق نصًا من الصفحة لتحسين الملخص.'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _generateInstantSummary,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('لخّص الآن'),
                          style: _solidStyle(const Color(0xFF0F766E)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleReadSummary,
                          icon: Icon(_isReadingSummary ? Icons.stop : Icons.volume_up),
                          label: Text(_isReadingSummary ? 'إيقاف الصوت' : 'ملخص صوتي'),
                          style: _solidStyle(const Color(0xFF14532D)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _TextPanel(text: _instantSummary),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              title: 'خطة تعلّم شخصية',
              subtitle: 'لغة، تطوير مهارة، أو هدف 10 كتب بالسنة.',
              c1: const Color(0xFF1D4ED8),
              c2: const Color(0xFF0EA5E9),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _LearningGoal.values.map((goal) {
                      return ChoiceChip(
                        label: Text(goal.label),
                        selected: _selectedGoal == goal,
                        selectedColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: _selectedGoal == goal
                              ? const Color(0xFF1D4ED8)
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => setState(() => _selectedGoal = goal),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('كم ساعة متاح لك أسبوعيًا؟'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateWeeklyPlan,
                      icon: const Icon(Icons.route_outlined),
                      label: const Text('بناء خطة أسبوعية ذكية'),
                      style: _solidStyle(const Color(0xFF1E3A8A)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._weeklyPlan.map((item) => _BulletLine(text: item)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              title: 'نظام تتبع القراءة',
              subtitle: 'عداد صفحات، تقدم الكتب، رسم شهري، وسلسلة القراءة.',
              c1: const Color(0xFF7C3AED),
              c2: const Color(0xFFA855F7),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricBadge(label: 'الصفحات اليوم', value: '$_dailyPages صفحة'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricBadge(label: 'سلسلة القراءة', value: '$_streakDays أيام'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _dailyPages += 5);
                            _saveProgressState();
                          },
                          style: _outlineStyle(),
                          child: const Text('+5 صفحات'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _streakDays += 1);
                            _saveProgressState();
                          },
                          style: _outlineStyle(),
                          child: const Text('تحديث السلسلة'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._bookProgress.map(
                    (book) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book.title, style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: book.progress,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8),
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${(book.progress * 100).round()}%',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'تطور القراءة خلال الشهر',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const _BarChart(values: _monthlyReadingBars),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              title: 'مساعد الفهم العميق',
              subtitle: 'اشرح أي فقرة + مثال واقعي + تشبيه مبسّط.',
              c1: const Color(0xFFF97316),
              c2: const Color(0xFFEF4444),
              child: Column(
                children: [
                  TextField(
                    controller: _deepExplainController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('اكتب الفقرة التي لم تفهمها...'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _explainDeeply,
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text('اشرحها لي ببساطة'),
                      style: _solidStyle(const Color(0xFF9A3412)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TextPanel(text: _deepExplanation),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              title: 'اختبارات قصيرة بعد كل كتاب',
              subtitle: '5 أسئلة ذكية + تقييم مستوى الفهم + نقاط تحتاج مراجعة.',
              c1: const Color(0xFF0EA5A4),
              c2: const Color(0xFF14B8A6),
              child: Column(
                children: [
                  ...List.generate(_quiz.length, (index) {
                    final q = _quiz[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}) ${q.question}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          ...List.generate(q.options.length, (optionIndex) {
                            final selected = _answers[index] == optionIndex;
                            return InkWell(
                              onTap: () => setState(() => _answers[index] = optionIndex),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white.withValues(alpha: 0.24)
                                      : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selected
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        q.options[optionIndex],
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _evaluateQuiz,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('تقييم الفهم'),
                      style: _solidStyle(const Color(0xFF115E59)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TextPanel(text: _quizResult),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              title: 'نظام تعلم 5 دقائق',
              subtitle: 'بطاقات يومية حتى لو ما قرأت اليوم.',
              c1: const Color(0xFF2563EB),
              c2: const Color(0xFF7C3AED),
              child: Column(
                children: _microCards
                    .map(
                      (card) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                card.type,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(card.text, style: const TextStyle(color: Colors.white70)),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              title: 'مجتمع القرّاء',
              subtitle: 'قوائم مشتركة، تحديات شهرية، وأفضل الاقتباسات.',
              c1: const Color(0xFF9333EA),
              c2: const Color(0xFFEC4899),
              child: const Column(
                children: [
                  _CommunityTile(
                    title: 'تحدي الشهر',
                    subtitle: 'اقرأ 300 صفحة خلال هذا الشهر.',
                    icon: Icons.emoji_events_outlined,
                  ),
                  _CommunityTile(
                    title: 'قائمة قراءة مشتركة',
                    subtitle: '7 أعضاء يقرؤون: العادات الذرية + التفكير السريع والبطيء.',
                    icon: Icons.groups_2_outlined,
                  ),
                  _CommunityTile(
                    title: 'اقتباس متداول',
                    subtitle: '"المعرفة التي لا تُطبق تتحول إلى عبء".',
                    icon: Icons.format_quote,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              title: 'مساعد كتابة الملاحظات',
              subtitle: 'تصنيف أفكارك واستخراج ملخص ملاحظات جميل.',
              c1: const Color(0xFF15803D),
              c2: const Color(0xFF65A30D),
              child: Column(
                children: [
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('اكتب ملاحظاتك أثناء القراءة...'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final summary = _summarizeNotes(_notesController.text);
                        showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: const Color(0xFF111827),
                          isScrollControlled: true,
                          builder: (context) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'ملخص ملاحظاتك',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      summary,
                                      style: const TextStyle(color: Colors.white70, height: 1.45),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('تنظيم الملاحظات تلقائيًا'),
                      style: _solidStyle(const Color(0xFF166534)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              title: 'تعلّم متعدد الوسائط',
              subtitle: 'كتب + بودكاست + فيديوهات قصيرة + مقالات + Micro Courses.',
              c1: const Color(0xFFEA580C),
              c2: const Color(0xFFF59E0B),
              child: const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(label: 'بودكاست', icon: Icons.podcasts_outlined),
                  _Pill(label: 'مقاطع تعليمية', icon: Icons.ondemand_video_outlined),
                  _Pill(label: 'مقالات مختارة', icon: Icons.article_outlined),
                  _Pill(label: 'Micro Courses', icon: Icons.school_outlined),
                  _Pill(label: 'ملخصات كتب', icon: Icons.menu_book_outlined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _outlineStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  ButtonStyle _solidStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  InputDecoration _inputDecoration(String hint) {
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
}
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
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

class _TextPanel extends StatelessWidget {
  const _TextPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, height: 1.4)),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

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

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.label, required this.value});

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

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
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
                  Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
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

class _CommunityTile extends StatelessWidget {
  const _CommunityTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

enum _LearningGoal {
  language('تعلم لغة'),
  skill('تطوير مهارة'),
  tenBooks('قراءة 10 كتب بالسنة');

  const _LearningGoal(this.label);
  final String label;
}

class _BookProgress {
  const _BookProgress({required this.title, required this.progress});

  final String title;
  final double progress;
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctOption,
  });

  final String question;
  final List<String> options;
  final int correctOption;
}

class _MicroCard {
  const _MicroCard({required this.type, required this.text});

  final String type;
  final String text;
}


