import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'llm_api_service.dart';
import 'notification_service.dart';

class PersonalAssistantScreen extends StatefulWidget {
  const PersonalAssistantScreen({super.key});

  @override
  State<PersonalAssistantScreen> createState() => _PersonalAssistantScreenState();
}

class _PersonalAssistantScreenState extends State<PersonalAssistantScreen> {
  static const String _kHabitsKey = 'habits_data_v1';
  static const String _kTasksKey = 'daily_tasks_items_v2';
  static const String _kProgressHabitsCompletionKey = 'progress_habits_completion_v1';
  static const String _kProgressTasksCompletionKey = 'progress_tasks_completion_v1';
  static const String _kProgressCommitmentCurrentKey = 'progress_commitment_current_v1';
  static const String _kProgressLearningHoursKey = 'progress_learning_hours_weekly_v1';
  static const String _kProgressWorkoutHoursKey = 'progress_workout_hours_weekly_v1';
  static const String _kProgressTasksDoneKey = 'progress_tasks_done_count_v1';
  static const String _kProgressTasksTotalKey = 'progress_tasks_total_count_v1';
  static const String _kKidsUnlockSignalKey = 'kids_device_unlock_signal_v1';
  static const String _kAssistantMemoryKey = 'assistant_memory_notes_v1';
  static const String _kVoiceRateKey = 'assistant_voice_rate_v1';

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(text: '0550000000');
  final TextEditingController _childPhoneController = TextEditingController(text: '0551111111');
  final FlutterTts _tts = FlutterTts();
  final LlmApiService _llmApi = const LlmApiService();

  final List<_ChatMessage> _messages = <_ChatMessage>[];
  final List<String> _autoActions = <String>[];
  final List<String> _predictions = <String>[];
  final List<String> _motivationFeed = <String>[];
  final List<String> _memoryNotes = <String>[];

  bool _loading = true;
  bool _voiceMode = true;
  bool _speaking = false;
  bool _waitingResponse = false;
  bool _kidsDeviceUnlocked = false;
  String _lastReplySource = 'local';
  double _voiceRate = 0.82;

  List<Map<String, dynamic>> _habits = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _tasks = <Map<String, dynamic>>[];

  int _habitsCompletion = 0;
  int _tasksCompletion = 0;
  int _commitment = 0;
  int _tasksDone = 0;
  int _tasksTotal = 0;
  double _learningHours = 0;
  double _workoutHours = 0;

  final double _sleepHours = 6.1;
  final double _phoneUsageHours = 4.8;
  String _moodState = 'ãÓÊŞÑ';

  @override
  void initState() {
    super.initState();
    _initAssistant();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _phoneController.dispose();
    _childPhoneController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initAssistant() async {
    await _tts.setLanguage('ar-SA');
    await _tts.setSpeechRate(_voiceRate);
    await _tts.setPitch(1.0);
    _tts.setStartHandler(() {
      if (!mounted) return;
      setState(() => _speaking = true);
    });
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() => _speaking = false);
    });
    _tts.setErrorHandler((_) {
      if (!mounted) return;
      setState(() => _speaking = false);
    });
    await NotificationService.instance.requestPermissions();
    await _loadContextData();
  }

  Future<void> _loadContextData() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = prefs.getString(_kHabitsKey);
    final tasksJson = prefs.getString(_kTasksKey);

    if (habitsJson != null) {
      try {
        _habits = (jsonDecode(habitsJson) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .toList();
      } catch (_) {
        _habits = <Map<String, dynamic>>[];
      }
    }

    if (tasksJson != null) {
      try {
        _tasks = (jsonDecode(tasksJson) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .toList();
      } catch (_) {
        _tasks = <Map<String, dynamic>>[];
      }
    }

    _habitsCompletion = prefs.getInt(_kProgressHabitsCompletionKey) ?? 0;
    _tasksCompletion = prefs.getInt(_kProgressTasksCompletionKey) ?? 0;
    _commitment = prefs.getInt(_kProgressCommitmentCurrentKey) ?? 0;
    _tasksDone = prefs.getInt(_kProgressTasksDoneKey) ?? 0;
    _tasksTotal = prefs.getInt(_kProgressTasksTotalKey) ?? 0;
    _learningHours = prefs.getDouble(_kProgressLearningHoursKey) ?? 0;
    _workoutHours = prefs.getDouble(_kProgressWorkoutHoursKey) ?? 0;
    _kidsDeviceUnlocked = prefs.getBool(_kKidsUnlockSignalKey) ?? false;

    final memory = prefs.getStringList(_kAssistantMemoryKey);
    final savedVoiceRate = prefs.getDouble(_kVoiceRateKey);
    if (memory != null) {
      _memoryNotes
        ..clear()
        ..addAll(memory);
    }
    if (savedVoiceRate != null) {
      _voiceRate = savedVoiceRate.clamp(0.45, 1.0);
      await _tts.setSpeechRate(_voiceRate);
    }

    _messages.add(
      _ChatMessage(
        text:
            'ÃäÇ ãÑßÒ ÇáÊÍßã ÇáĞßí. ÃÚÑİ ãåÇãß¡ ÚÇÏÇÊß¡ ÇáÊÒÇãß¡ ææÖÚ ÇáÃÈäÇÁ. ÇßÊÈ ÃãÑğÇ ÇáÂä Ãæ ÇÓÊÎÏã ÇáÃæÇãÑ ÇáİæÑíÉ.',
        isUser: false,
      ),
    );

    _rebuildPredictions();
    _rebuildMotivation();

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _saveMemory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kAssistantMemoryKey, _memoryNotes.take(20).toList());
  }

  Future<void> _saveVoiceRate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kVoiceRateKey, _voiceRate);
  }

  Future<void> _speak(String text) async {
    if (!_voiceMode) return;
    await _tts.speak(text);
  }

  void _rememberUserStyle(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('ãÎÊÕÑ')) {
      _memoryNotes.insert(0, 'íİÖøá ÃÓáæÈ ãÎÊÕÑ ææÇÖÍ.');
    }
    if (lower.contains('ÊİÕíá') || lower.contains('ÔÑÍ')) {
      _memoryNotes.insert(0, 'íİÖøá ÔÑÍğÇ ÊİÕíáíğÇ ÚäÏ ÇáÍÇÌÉ.');
    }
    if (lower.contains('ÇÌÊãÇÚ')) {
      _memoryNotes.insert(0, 'áÏíå ÇÌÊãÇÚÇÊ ãÊßÑÑÉ æíÍÊÇÌ ÊÍÖíÑ ãÓÈŞ.');
    }
    if (_memoryNotes.length > 25) {
      _memoryNotes.removeRange(25, _memoryNotes.length);
    }
    _saveMemory();
  }

  Future<void> _handleSend(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty) return;

    _rememberUserStyle(prompt);

    setState(() {
      _messages.add(_ChatMessage(text: prompt, isUser: true));
      _inputController.clear();
      _waitingResponse = true;
    });

    String reply;
    try {
      reply = await _buildReply(prompt);
    } catch (_) {
      _lastReplySource = 'local';
      reply = 'æÇÌåÊ ãÔßáÉ ãÄŞÊÉ İí ÇáÑÏ. ÍÇæá ãÑÉ ËÇäíÉ ÈÚÏ áÍÙÇÊ.';
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _waitingResponse = false;
    });
    _speak(reply);
  }

  Map<String, dynamic> _lifeContext() {
    return <String, dynamic>{
      'commitment_percent': _commitment,
      'tasks_completion_percent': _tasksCompletion,
      'habits_completion_percent': _habitsCompletion,
      'tasks_done': _tasksDone,
      'tasks_total': _tasksTotal,
      'learning_hours_weekly': _learningHours,
      'workout_hours_weekly': _workoutHours,
      'sleep_hours': _sleepHours,
      'phone_usage_hours': _phoneUsageHours,
      'kids_device_unlocked': _kidsDeviceUnlocked,
      'mood': _moodState,
      'pressure_score': _pressureScore(),
      'habits_count': _habits.length,
      'tasks_count': _tasks.length,
      'memory_notes': _memoryNotes.take(8).toList(),
      'predictions': _predictions.take(5).toList(),
    };
  }

  List<Map<String, String>> _historyForApi() {
    final start = _messages.length > 14 ? _messages.length - 14 : 0;
    return _messages
        .sublist(start)
        .map(
          (m) => <String, String>{
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.text,
          },
        )
        .toList();
  }

  Future<String> _buildReply(String prompt) async {
    final lower = prompt.toLowerCase();

    if (lower.contains('ãßÇáãÉ') || lower.contains('ÇÊÕá')) {
      await _callUser();
      _lastReplySource = 'local';
      return 'Êã ÈÏÁ ãÍÇæáÉ ÇáÇÊÕÇá ÇáÂä. ÃŞÏÑ ÃíÖğÇ ÃÊÕá Úáì ÇáØİá æŞÊ ÇáÏÑÇÓÉ.';
    }

    if (lower.contains('ÅÚÇÏÉ ÊÑÊíÈ') || lower.contains('ÑÊÈ íæãí')) {
      final action = _runAutoActions();
      _lastReplySource = 'local';
      return 'Êã ÊäİíĞ ÅÚÇÏÉ ÊÑÊíÈ Çáíæã ÊáŞÇÆíğÇ:\n$action';
    }

    final cloud = await _llmApi.generateReply(
      prompt: prompt,
      lifeContext: _lifeContext(),
      history: _historyForApi(),
    );
    if (cloud != null && cloud.trim().isNotEmpty) {
      _lastReplySource = 'cloud';
      return cloud.trim();
    }

    if (lower.contains('ÇÌÊãÇÚ') && (lower.contains('ÍÖøÑ') || lower.contains('ÍÖÑäí'))) {
      final checklist = _meetingPrepChecklist();
      await NotificationService.instance.showNow(
        id: 901001,
        title: 'ÊÍÖíÑ ÇÌÊãÇÚ',
        body: 'ÌåÒÊ áß ŞÇÆãÉ ŞÈá ÇáÇÌÊãÇÚ ÎáÇá ÓÇÚÉ.',
      );
      _lastReplySource = 'local';
      return 'ÊãÇã íÇ Abdulellah¡ ÌåÒÊ áß ŞÇÆãÉ ŞÈá ÇáÇÌÊãÇÚ:\n$checklist';
    }
    if (lower.contains('ÎØÉ íæã')) {
      _lastReplySource = 'local';
      return _buildDayPlan();
    }
    if (lower.contains('ÎØÉ ÃÓÈæÚ')) {
      _lastReplySource = 'local';
      return _buildWeekPlan();
    }
    if (lower.contains('ÎØÉ ÔåÑ')) {
      _lastReplySource = 'local';
      return _buildMonthPlan();
    }
    if (lower.contains('ÃØİÇá') || lower.contains('Øİá')) {
      _lastReplySource = 'local';
      return _kidsStatusReply();
    }
    if (lower.contains('ÊäÈÄ') || lower.contains('ÊÊæŞÚ')) {
      _rebuildPredictions();
      _lastReplySource = 'local';
      return 'ÊæŞÚÇÊí ÇáÍÇáíÉ:\n- ${_predictions.join('\n- ')}';
    }
    if (lower.contains('ÊÍİíÒ') || lower.contains('äÕíÍÉ')) {
      _rebuildMotivation();
      _lastReplySource = 'local';
      return 'ÑÓÇáÉ Çáíæã: ${_motivationFeed.first}';
    }

    if (_llmApi.isConfigured) {
      _lastReplySource = 'local';
      return 'ÇáÎÇÏã ÇáĞßí ãÔÛæá ÇáÂä. ÃÚÏ ÅÑÓÇá äİÓ ÇáÑÓÇáÉ ÈÚÏ ËÇäíÊíä.';
    }

    _lastReplySource = 'local';
    return _contextAwareGeneralReply();
  }

  String _contextAwareGeneralReply() {
    final style = _memoryNotes.isEmpty ? 'ÃÓáæÈ ãÊæÇÒä' : _memoryNotes.first;
    final highPressure = _pressureScore() >= 70;
    return 'ŞÑÃÊ æÖÚß ÇáÍÇáí: ÇáÊÒÇã ${_commitment.clamp(0, 100)}%¡ '
        'ãåÇã ${_tasksCompletion.clamp(0, 100)}%¡ æÚÇÏÇÊ ${_habitsCompletion.clamp(0, 100)}%. '
        'ÓÃÑÏ Úáíß ÈäÇÁğ Úáì $style. '
        '${highPressure ? 'ÚäÏß ÖÛØ ãÑÊİÚ¡ İÇáÃİÖá ÊŞáíá ÇáãåÇã ÇáÃÓÇÓíÉ Çáíæã.' : 'æÖÚß ãÓÊŞÑ æíãßä ÑİÚ åÏİ ÈÓíØ Çáíæã.'}';
  }

  String _meetingPrepChecklist() {
    return '1) ÑÇÌÚ åÏİ ÇáÇÌÊãÇÚ ÎáÇá 5 ÏŞÇÆŞ.\n'
        '2) ÌåÒ 3 äŞÇØ ÑÆíÓíÉ.\n'
        '3) ÇİÊÍ ÇáãáİÇÊ/ÇáÑæÇÈØ ÇáãØáæÈÉ ŞÈá ÇáãæÚÏ.\n'
        '4) ÍÏÏ ÓÄÇáíä ÍÇÓãíä ááäŞÇÔ.\n'
        '5) ŞÈá ÇáÇÌÊãÇÚ ÈÜ10 ÏŞÇÆŞ: ãáÎÕ ÓÑíÚ æÕæÊ åÇÏÆ.';
  }

  String _kidsStatusReply() {
    return _kidsDeviceUnlocked
        ? 'æÖÚ ÇáÃÈäÇÁ ÇáÍÇáí: ÇáÌåÇÒ ãİÊæÍ ÈÚÏ ÅäÌÇÒ ÇáãåÇã. ÇÓÊãÑ ÈÇáãÊÇÈÚÉ ÇáíæãíÉ.'
        : 'æÖÚ ÇáÃÈäÇÁ ÇáÍÇáí: ÇáÌåÇÒ ãŞİæá/ãÍÏæÏ ÍÊì ÇßÊãÇá ÇáÏÑÇÓÉ. ÃŞÊÑÍ ÊİÚíá ÌáÓÉ ÔÑÍ ÅÖÇİíÉ.';
  }

  int _pressureScore() {
    final taskLoad = (_tasksTotal == 0 ? 0 : ((_tasksTotal - _tasksDone) / _tasksTotal) * 100);
    final sleepPenalty = ((_sleepHours < 7) ? (7 - _sleepHours) * 14 : 0);
    final phonePenalty = (_phoneUsageHours > 5) ? (_phoneUsageHours - 5) * 8 : 0;
    return (taskLoad * 0.5 + sleepPenalty + phonePenalty).round().clamp(0, 100);
  }

  String _buildDayPlan() {
    final pressure = _pressureScore();
    final focus = pressure >= 70 ? 'ÎİíİÉ' : 'ÚãíŞÉ';
    return 'ÎØÉ Çáíæã (ãÈäíÉ Úáì ÈíÇäÇÊß):\n'
        '1) ãåãÉ $focus Ãæáì ÕÈÇÍğÇ (35 ÏŞíŞÉ).\n'
        '2) ãÊÇÈÚÉ ãåÇã Çáíæã ÇáÍÇáíÉ: $_tasksDone/$_tasksTotal.\n'
        '3) ãÑÇÌÚÉ åÏİ ÕÍí + ÚÇÏÉ ŞÕíÑÉ ŞÈá ÇáãÛÑÈ.\n'
        '4) ÅäåÇÁ Çáíæã ŞÈá 11:00 ã áÑİÚ ÌæÏÉ Çáäæã.';
  }

  String _buildWeekPlan() {
    return 'ÎØÉ ÇáÃÓÈæÚ:\n'
        '- ÊËÈíÊ 3 ÃæáæíÇÊ Úãá ÑÆíÓíÉ.\n'
        '- ÑİÚ ÇáÊÒÇã ÇáãåÇã ãä $_tasksCompletion% Åáì ${math.min(100, _tasksCompletion + 12)}%.\n'
        '- ÌáÓÉ ÏÚã ÏÑÇÓí ááÃÈäÇÁ ãÑÊíä.\n'
        '- íæã Îİíİ áÊÎİíİ ÇáÖÛØ æÇÓÊÚÇÏÉ ÇáÊÑßíÒ.';
  }

  String _buildMonthPlan() {
    return 'ÎØÉ ÇáÔåÑ:\n'
        '- åÏİ ÅäÊÇÌíÉ: ÑİÚ ÇáÇáÊÒÇã ÇáÚÇã ãä $_commitment% Åáì ${math.min(100, _commitment + 10)}%.\n'
        '- åÏİ ÕÍí: ÑİÚ ãÊæÓØ Çáäæã Åáì 7+ ÓÇÚÇÊ.\n'
        '- åÏİ ÚÇÆáí: ãÊÇÈÚÉ ÃÓÈæÚíÉ áÃÏÇÁ ÇáÃÈäÇÁ ãÚ ÊŞÑíÑ ãÎÊÕÑ.';
  }

  String _runAutoActions() {
    _autoActions.clear();

    if (_tasksCompletion < 45) {
      _autoActions.add('Êã ÊŞáíá Íãá Çáíæã Åáì 3 ãåÇã ÃÓÇÓíÉ İŞØ.');
    }
    if (!_kidsDeviceUnlocked) {
      _autoActions.add('ÊÃßíÏ ÅÈŞÇÁ ÌåÇÒ ÇáØİá ÈæÖÚ ÇáÏÑÇÓÉ ÍÊì ÅäåÇÁ ÇáÏÑÓ.');
    }
    if (_sleepHours < 6.5) {
      _autoActions.add('ÇŞÊÑÇÍ æŞÊ äæã ãÈßÑ ÇááíáÉ + ÊĞßíÑ ÊáŞÇÆí ŞÈá Çáäæã.');
    }
    if (_pressureScore() >= 70) {
      _autoActions.add('ÊİÚíá æÖÚ ÇáÖÛØ: ÊÃÌíá ÇáãåÇã ÛíÑ ÇáÚÇÌáÉ ááÛÏ.');
    }
    if (_tasksCompletion > 80) {
      _autoActions.add('ÇŞÊÑÇÍ ÚÇÏÉ ÌÏíÏÉ ŞÕíÑÉ áÃä ÚäÏß æŞÊ ãÊÇÍ.');
    }

    if (_autoActions.isEmpty) {
      _autoActions.add('áÇ ÍÇÌÉ áÅÌÑÇÁÇÊ ÊáŞÇÆíÉ ÇáÂä¡ æÖÚß ããÊÇÒ.');
    }
    return '- ${_autoActions.join('\n- ')}';
  }

  void _rebuildPredictions() {
    _predictions
      ..clear()
      ..addAll([
        if (_tasksCompletion < 55) 'ãÑÌÍ ÊÊÃÎÑ İí ãåãÉ Çáíæã ÇáãÓÇÆíÉ ÈÏæä ÊĞßíÑ ÅÖÇİí.',
        if (!_kidsDeviceUnlocked) 'ÇÈäß íÍÊÇÌ ãÑÇÌÚÉ ŞÈá İÊÍ ÇáÌåÇÒ.',
        if (_sleepHours < 6.5) 'ÊÍÊÇÌ ÑÇÍÉ ãÈßÑÉ ÇááíáÉ áÊÌäÈ åÈæØ ÇáÊÑßíÒ ÛÏğÇ.',
        if (_pressureScore() > 70) 'ÇáÃİÖá ÌÏæá ÃÎİ ÎáÇá 24 ÓÇÚÉ ÇáŞÇÏãÉ.',
        if (_phoneUsageHours > 6) 'íõİÖøá ÊäÈíå ÊŞáíá ÇÓÊÎÏÇã ÇáÌæÇá ŞÈá Çáäæã.',
      ]);
    if (_predictions.isEmpty) {
      _predictions.add('áÇ ÊæÌÏ ãÎÇØÑ æÇÖÍÉ ÇáÂä¡ ÇÓÊãÑ ÈäİÓ ÇáÅíŞÇÚ.');
    }
  }

  void _rebuildMotivation() {
    _motivationFeed
      ..clear()
      ..addAll([
        'ÃäÊ ŞÑíÈ ãä åÏİß ÇáÃÓÈæÚí¡ ÎØæÉ ÕÛíÑÉ ÇáÂä ÊİÑŞ.',
        'ÃİÖá ÅäÌÇÒÇÊß ÊÙåÑ İí ÇáãÓÇÁ¡ ÇÓÊËãÑåÇ ÈãåãÉ ãÑßÒÉ.',
        'ßá ãåãÉ ÊäÌÒåÇ Çáíæã ÊÑİÚ ãÄÔÑ ÊŞÏãß æÊÎİİ ÖÛØ ÇáÛÏ.',
      ]);
    _moodState = _pressureScore() >= 70 ? 'ãÌåÏ' : 'ãÓÊŞÑ';
  }

  Future<void> _callUser() async {
    final number = _phoneController.text.trim();
    if (number.isEmpty) {
      _showSnack('ÃÏÎá ÑŞã ÇáÌæÇá ÃæáğÇ.');
      return;
    }
    final uri = Uri.parse('tel:$number');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack('ÊÚĞÑ ÈÏÁ ÇáÇÊÕÇá.');
    }
  }

  Future<void> _callChild() async {
    final number = _childPhoneController.text.trim();
    if (number.isEmpty) {
      _showSnack('ÃÏÎá ÑŞã ÇáØİá ÃæáğÇ.');
      return;
    }
    final uri = Uri.parse('tel:$number');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack('ÊÚĞÑ ÈÏÁ ÇáÇÊÕÇá ÈÇáØİá.');
    }
  }

  void _simulateVoiceCommand() {
    _handleSend('íÇ ãÓÇÚÏ¡ ÚäÏí ÇÌÊãÇÚ ÈÚÏ ÓÇÚÉ ÍÖÑäí');
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }

  Widget _lifeChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text('$title: $value', style: const TextStyle(color: Colors.white70)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pressure = _pressureScore();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0F1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0F1E),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'ÇáãÓÇÚÏ ÇáÔÎÕí ÇáãÈÇÔÑ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                children: [
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ÍÇáÉ ÍíÇÊß ÇáÂä',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                _llmApi.isConfigured ? 'LLM API: ãÊÕá' : 'LLM API: ÛíÑ ãÖÈæØ',
                              ),
                              backgroundColor: _llmApi.isConfigured
                                  ? const Color(0x3322C55E)
                                  : const Color(0x33EF4444),
                              labelStyle: TextStyle(
                                color: _llmApi.isConfigured
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFFCA5A5),
                              ),
                            ),
                            Chip(
                              label: Text(
                                _lastReplySource == 'cloud'
                                    ? 'ãÕÏÑ ÇáÑÏ: AI API'
                                    : 'ãÕÏÑ ÇáÑÏ: ãÍáí',
                              ),
                              backgroundColor: _lastReplySource == 'cloud'
                                  ? const Color(0x3322C55E)
                                  : const Color(0x334B5563),
                              labelStyle: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _lifeChip('ÇáÇáÊÒÇã', '$_commitment%'),
                            _lifeChip('ÇáãåÇã', '$_tasksDone/$_tasksTotal'),
                            _lifeChip('ÇáÚÇÏÇÊ', '$_habitsCompletion%'),
                            _lifeChip('ÚÏÏ ÇáÚÇÏÇÊ', '${_habits.length}'),
                            _lifeChip('ÚÏÏ ÇáãåÇã', '${_tasks.length}'),
                            _lifeChip(
                              'ÊÚáã+ÊãÑíä',
                              '${(_learningHours + _workoutHours).toStringAsFixed(1)}h',
                            ),
                            _lifeChip('Çáäæã', '${_sleepHours.toStringAsFixed(1)}h'),
                            _lifeChip('ÇÓÊÎÏÇã ÇáÌæÇá', '${_phoneUsageHours.toStringAsFixed(1)}h'),
                            _lifeChip('ÇáÃÈäÇÁ', _kidsDeviceUnlocked ? 'ÇáÌåÇÒ ãİÊæÍ' : 'ÇáÌåÇÒ ãŞİæá'),
                            _lifeChip('ÇáãÒÇÌ', _moodState),
                            _lifeChip('ÇáÖÛØ', '$pressure%'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ÃæÇãÑ İæÑíÉ',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _quickAction('ÎØÉ íæã'),
                            _quickAction('ÎØÉ ÃÓÈæÚ'),
                            _quickAction('ÎØÉ ÔåÑ'),
                            _quickAction('ÑÊÈ íæãí'),
                            _quickAction('ÊäÈÄÇÊ'),
                            _quickAction('ÊÍİíÒ Çáíæã'),
                            _quickAction('æÖÚ ÇáÃÈäÇÁ'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'ÇáãÓÇÚÏ ÇáÕæÊí',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                              ),
                            ),
                            Switch(
                              value: _voiceMode,
                              onChanged: (v) => setState(() => _voiceMode = v),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _simulateVoiceCommand,
                              icon: const Icon(Icons.mic_rounded),
                              label: const Text('ÒÑ ÇáÊÍÏË'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _speak('ÃäÇ ÌÇåÒ¡ Şá áí ãÇĞÇ ÊÑíÏ ÇáÂä.'),
                              icon: const Icon(Icons.volume_up_rounded),
                              label: Text(_speaking ? 'ÌÇÑí ÇáäØŞ...' : 'ÑÏ ÕæÊí'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ÓÑÚÉ ÇáÕæÊ: ${_voiceRate.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Slider(
                          value: _voiceRate,
                          min: 0.45,
                          max: 1.0,
                          divisions: 11,
                          activeColor: const Color(0xFF38BDF8),
                          onChanged: (v) async {
                            setState(() => _voiceRate = v);
                            await _tts.setSpeechRate(v);
                            await _saveVoiceRate();
                          },
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ÇáãßÇáãÇÊ ÇáĞßíÉ',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'ÑŞãß ááÇÊÕÇá',
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _childPhoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'ÑŞã ÇáØİá ááãÊÇÈÚÉ ÇáÏÑÇÓíÉ',
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _callUser,
                              icon: const Icon(Icons.call_rounded),
                              label: const Text('ÇÊÕÇá Èí ÇáÂä'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _callChild,
                              icon: const Icon(Icons.school_rounded),
                              label: const Text('ÇÊÕÇá ÈÇáØİá æŞÊ ÇáÏÑÇÓÉ'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ÇáãåÇã ÇáÊáŞÇÆíÉ + ÇáÊäÈÄÇÊ',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final report = _runAutoActions();
                              _handleSend('äİĞ ÇáÅÌÑÇÁÇÊ ÇáÊáŞÇÆíÉ');
                              _showSnack('Êã ÊäİíĞ: ${report.split('\n').first.replaceAll('-', '').trim()}');
                            },
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('ÊÔÛíá Auto-Actions ÇáÂä'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._predictions.take(4).map(
                          (p) => Text('• $p', style: const TextStyle(color: Colors.white70)),
                        ),
                        if (_autoActions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('ÅÌÑÇÁÇÊ ãäİĞÉ:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ..._autoActions.take(4).map(
                            (a) => Text('- $a', style: const TextStyle(color: Colors.white70)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ÇáãÓÇÚÏ ÇáÚÇØİí + ÇáÅÏÇÑí + ÇáÑÈØ',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text('äÕíÍÉ Çáíæã: ${_motivationFeed.first}', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text('ÎØÉ íæã: ${_buildDayPlan().split('\n').first}', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text('ÎØÉ ÃÓÈæÚ: ${_buildWeekPlan().split('\n').first}', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        const Text('ãÑßÒ ÇáÑÈØ ÇáßÇãá:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text(
                          'ãåÇã Çáíæã • ãÑÇŞÈÉ ÇáÃÈäÇÁ • ÇáÃåÏÇİ • ÇáÚÇÏÇÊ • Çáäæã • ÇáæŞÊ • ÇáÏÑÇÓÉ • ÇáÌåÇÒ • ÇáÊŞÇÑíÑ',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ÇáãÍÇÏËÉ ÇáĞßíÉ (AI Chat Brain)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 260,
                          child: ListView.builder(
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final item = _messages[index];
                              return Align(
                                alignment: item.isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  constraints: const BoxConstraints(maxWidth: 330),
                                  decoration: BoxDecoration(
                                    color: item.isUser
                                        ? const Color(0xFF2563EB)
                                        : Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(item.text, style: const TextStyle(color: Colors.white)),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_waitingResponse)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('ÇáãÓÇÚÏ íİßÑ...', style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _inputController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'ÇßÊÈ ÃãÑß ÇáÂä...',
                                  hintStyle: const TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: Colors.black.withValues(alpha: 0.2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onSubmitted: _handleSend,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _handleSend(_inputController.text),
                              child: const Icon(Icons.send_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _quickAction(String text) {
    return ActionChip(
      label: Text(text),
      labelStyle: const TextStyle(color: Colors.white),
      backgroundColor: const Color(0xFF1F2937),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
      onPressed: () => _handleSend(text),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

