import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'books_screen.dart';
import 'daily_tasks_screen.dart';
import 'finance_screen.dart';
import 'fitness_screen.dart';
import 'habits_screen.dart';
import 'kids_monitoring_screen.dart';
import 'personal_assistant_screen.dart';
import 'progress_screen.dart';
import 'auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const String _spaceImagePath = 'assets/images/flower.jpg';
  static const String _calmImagePath = 'assets/images/sky.jpg';
  static const String _warmImagePath = 'assets/images/warm.jpg';
  static const String _nightImagePath = 'assets/images/dark.jpg';

  static const List<_BackgroundMode> _modes = [
    _BackgroundMode(
      name: 'هادئ',
      kind: _BackgroundKind.calm,
      pageBackground: Color(0xFFF3F8FB),
      headerBackground: Color(0xFF2F5D80),
      headerBorder: Color(0x666EA2CD),
      headerShadow: Color(0x1A1E3A55),
      headerSubtitle: Color(0xFFE7F2FB),
      switchBg: Color(0x334F88B3),
      switchText: Colors.white,
      blobA: Color(0x665EB0E6),
      blobB: Color(0x6658D2C6),
      blobC: Color(0x665DA0F2),
      duration: Duration(seconds: 24),
    ),
    _BackgroundMode(
      name: 'دافئ',
      kind: _BackgroundKind.warm,
      pageBackground: Color(0xFFFCF4E8),
      headerBackground: Color(0xFF905631),
      headerBorder: Color(0x66D7A57C),
      headerShadow: Color(0x1A402411),
      headerSubtitle: Color(0xFFFFEEDB),
      switchBg: Color(0x33E0B08D),
      switchText: Colors.white,
      blobA: Color(0x66F2AE72),
      blobB: Color(0x66F2C572),
      blobC: Color(0x66E58A74),
      duration: Duration(seconds: 18),
    ),
    _BackgroundMode(
      name: 'ليلي',
      kind: _BackgroundKind.night,
      pageBackground: Color(0xFFEAF0FC),
      headerBackground: Color(0xFF2A395A),
      headerBorder: Color(0x667A92C9),
      headerShadow: Color(0x1A151E35),
      headerSubtitle: Color(0xFFDDE8FF),
      switchBg: Color(0x334E689B),
      switchText: Colors.white,
      blobA: Color(0x664A6FB8),
      blobB: Color(0x664C5C99),
      blobC: Color(0x664F7AA0),
      duration: Duration(seconds: 40),
    ),
    _BackgroundMode(
      name: 'فضاء',
      kind: _BackgroundKind.space,
      pageBackground: Color(0xFF07090E),
      headerBackground: Color(0xFF111827),
      headerBorder: Color(0x665E6B84),
      headerShadow: Color(0x33000000),
      headerSubtitle: Color(0xFFDCE6FF),
      switchBg: Color(0x33415A8B),
      switchText: Colors.white,
      blobA: Color(0x33FFFFFF),
      blobB: Color(0x22000000),
      blobC: Color(0x00000000),
      duration: Duration(seconds: 48),
    ),
  ];

  late final AnimationController _controller;
  int _currentModeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _modes[_currentModeIndex].duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextMode() {
    final nextIndex = (_currentModeIndex + 1) % _modes.length;
    _setMode(nextIndex);
  }

  void _setMode(int index) {
    setState(() {
      _currentModeIndex = index;
      _controller
        ..duration = _modes[_currentModeIndex].duration
        ..reset()
        ..repeat();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = _modes[_currentModeIndex];

    return Scaffold(
      backgroundColor: mode.pageBackground,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(child: _buildBackgroundLayer(mode)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.only(
                      start: 20,
                      end: 20,
                      top: 16,
                      bottom: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: mode.pageBackground.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'ساعة الالتزام الشخصي',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'كل عاداتك، كتبك، وخرابيطك الذكية في لوحة وحدة مرتبة.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: mode.headerSubtitle,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _nextMode,
                                  style: TextButton.styleFrom(
                                    backgroundColor: mode.switchBg,
                                    foregroundColor: mode.switchText,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.motion_photos_auto,
                                    size: 18,
                                  ),
                                  label: Text('تبديل الوضع (${mode.name})'),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () => AuthService.instance.signOut(),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.logout_rounded, size: 18),
                                    label: const Text('تسجيل الخروج'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: List.generate(
                                    _modes.length,
                                    (index) => ChoiceChip(
                                      label: Text(_modes[index].name),
                                      selected: _currentModeIndex == index,
                                      selectedColor: mode.switchBg,
                                      labelStyle: TextStyle(
                                        color: _currentModeIndex == index
                                            ? mode.switchText
                                            : Colors.black87,
                                      ),
                                      onSelected: (_) => _setMode(index),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.topRight,
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.start,
                              runAlignment: WrapAlignment.start,
                              textDirection: TextDirection.rtl,
                              children: [
                                SizedBox(
                                  width: 170,
                                  height: 140,
                                  child: _HomeCard(
                                    title: 'الصحة والتمارين',
                                    subtitle: 'تتبع نشاطك وتحسين لياقتك',
                                    icon: Icons.fitness_center,
                                    backgroundImage: const AssetImage(
                                      'assets/images/Fitness.jpg',
                                    ),
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).push(_buildFitnessRoute());
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 170,
                                  height: 140,
                                  child: _HomeCard(
                                    title: 'الكتب والتعلّم',
                                    subtitle: 'رتّب مكتبتك الذهنية',
                                    icon: Icons.menu_book_rounded,
                                    backgroundImage: const AssetImage(
                                      'assets/images/Book_coffee.jpg',
                                    ),
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).push(_buildBooksRoute());
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 170,
                                  height: 140,
                                  child: _HomeCard(
                                    title: 'عادات اليوم',
                                    subtitle: 'تشييك سريع على التزامك',
                                    icon: Icons.check_circle_outline,
                                    backgroundImage: const AssetImage(
                                      'assets/images/goals.png',
                                    ),
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).push(_buildHabitsRoute());
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 170,
                                  height: 140,
                                  child: _HomeCard(
                                    title: 'تابع تقدمك',
                                    subtitle: 'وين كنت ووين وصلت',
                                    icon: Icons.center_focus_strong,
                                    backgroundImage: const AssetImage(
                                      'assets/images/growth chart.png',
                                    ),
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).push(_buildProgressRoute());
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 170,
                                  height: 140,
                                  child: _HomeCard(
                                    title: 'مراقبة الأبناء',
                                    subtitle: 'إشراف وتنظيم دراسة الأبناء',
                                    icon: Icons.mood,
                                    backgroundImage: const AssetImage(
                                      'assets/images/parents.png',
                                    ),
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).push(_buildKidsMonitoringRoute());
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 170,
                                  height: 140,
                                  child: _HomeCard(
                                    title: 'مهامك اليومية',
                                    subtitle: 'خطط يومك بين البيت والعمل',
                                    icon: Icons.today_rounded,
                                    backgroundImage: const AssetImage(
                                      'assets/images/brain.jpg',
                                    ),
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).push(_buildDailyTasksRoute());
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 170,
                                  height: 140,
                                  child: _HomeCard(
                                    title: 'المساعد المباشر',
                                    subtitle: 'خطة يومية، عادة، وتقرير أسبوعي',
                                    icon: Icons.support_agent_rounded,
                                    backgroundImage: const AssetImage(
                                      'assets/images/assistant.png',
                                    ),
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).push(_buildPersonalAssistantRoute());
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 170,
                                  height: 140,
                                  child: _HomeCard(
                                    title: 'الإدارة المالية',
                                    subtitle: 'راقب الراتب والمصروفات والتوزيع',
                                    icon: Icons.account_balance_wallet_rounded,
                                    backgroundImage: const AssetImage(
                                      'assets/images/images.jpg',
                                    ),
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).push(_buildFinanceRoute());
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Route<void> _buildFitnessRoute() {
    return _buildQuickExpandRoute(const FitnessScreen());
  }

  Route<void> _buildBooksRoute() {
    return _buildQuickExpandRoute(const BooksScreen());
  }

  Route<void> _buildHabitsRoute() {
    return _buildQuickExpandRoute(const HabitsScreen());
  }

  Route<void> _buildProgressRoute() {
    return _buildQuickExpandRoute(const ProgressScreen());
  }

  Route<void> _buildKidsMonitoringRoute() {
    return _buildQuickExpandRoute(const KidsMonitoringScreen());
  }

  Route<void> _buildDailyTasksRoute() {
    return _buildQuickExpandRoute(const DailyTasksScreen());
  }

  Route<void> _buildFinanceRoute() {
    return _buildQuickExpandRoute(const FinanceScreen());
  }

  Route<void> _buildPersonalAssistantRoute() {
    return _buildQuickExpandRoute(const PersonalAssistantScreen());
  }

  Route<void> _buildQuickExpandRoute(Widget page) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final fade = Tween<double>(begin: 0.15, end: 1.0).animate(curve);
        final scale = Tween<double>(begin: 0.88, end: 1.0).animate(curve);

        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  Widget _buildBackgroundLayer(_BackgroundMode mode) {
    if (mode.kind == _BackgroundKind.space ||
        mode.kind == _BackgroundKind.calm ||
        mode.kind == _BackgroundKind.warm ||
        mode.kind == _BackgroundKind.night) {
      final imagePath = switch (mode.kind) {
        _BackgroundKind.calm => _calmImagePath,
        _BackgroundKind.warm => _warmImagePath,
        _BackgroundKind.night => _nightImagePath,
        _BackgroundKind.space => _spaceImagePath,
      };
      final imageFit = BoxFit.cover;
      final imageScale = mode.kind == _BackgroundKind.calm ? 1.06 : 1.0;
      return Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(
            scale: imageScale,
            child: Image.asset(
              imagePath,
              fit: imageFit,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _AnimatedBackgroundPainter(
                        mode: mode,
                        progress: _controller.value,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x4D000000),
                  Color(0x73000000),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _AnimatedBackgroundPainter(
            mode: mode,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

enum _BackgroundKind { calm, warm, night, space }

class _BackgroundMode {
  final String name;
  final _BackgroundKind kind;
  final Color pageBackground;
  final Color headerBackground;
  final Color headerBorder;
  final Color headerShadow;
  final Color headerSubtitle;
  final Color switchBg;
  final Color switchText;
  final Color blobA;
  final Color blobB;
  final Color blobC;
  final Duration duration;

  const _BackgroundMode({
    required this.name,
    required this.kind,
    required this.pageBackground,
    required this.headerBackground,
    required this.headerBorder,
    required this.headerShadow,
    required this.headerSubtitle,
    required this.switchBg,
    required this.switchText,
    required this.blobA,
    required this.blobB,
    required this.blobC,
    required this.duration,
  });
}

class _AnimatedBackgroundPainter extends CustomPainter {
  final _BackgroundMode mode;
  final double progress;

  const _AnimatedBackgroundPainter({
    required this.mode,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * math.pi;

    if (mode.kind == _BackgroundKind.space) {
      _paintSpaceMode(canvas, size, t);
      return;
    }

    final basePaint = Paint()..color = mode.pageBackground;
    canvas.drawRect(Offset.zero & size, basePaint);

    final blobPaintA = Paint()..color = mode.blobA;
    final blobPaintB = Paint()..color = mode.blobB;
    final blobPaintC = Paint()..color = mode.blobC;

    final speed = switch (mode.kind) {
      _BackgroundKind.calm => 0.9,
      _BackgroundKind.warm => 1.4,
      _BackgroundKind.night => 0.55,
      _BackgroundKind.space => 0.5,
    };

    final amp = switch (mode.kind) {
      _BackgroundKind.calm => 20.0,
      _BackgroundKind.warm => 30.0,
      _BackgroundKind.night => 14.0,
      _BackgroundKind.space => 12.0,
    };

    final centerA = Offset(
      size.width * 0.2 + math.sin(t * speed) * amp,
      size.height * 0.25 + math.cos(t * speed * 0.8) * amp,
    );
    final centerB = Offset(
      size.width * 0.8 + math.cos(t * speed * 0.9) * amp,
      size.height * 0.45 + math.sin(t * speed * 0.7) * amp,
    );
    final centerC = Offset(
      size.width * 0.45 + math.sin(t * speed * 1.1) * amp,
      size.height * 0.82 + math.cos(t * speed * 0.6) * amp,
    );

    canvas.drawCircle(centerA, size.width * 0.38, blobPaintA);
    canvas.drawCircle(centerB, size.width * 0.34, blobPaintB);
    canvas.drawCircle(centerC, size.width * 0.42, blobPaintC);

    if (mode.kind == _BackgroundKind.warm) {
      final warmGlow = Paint()
        ..shader =
            RadialGradient(
              colors: const [Color(0x55FFD6A0), Color(0x00FFD6A0)],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.15, size.height * 0.1),
                radius: size.width * 0.7,
              ),
            );
      canvas.drawRect(Offset.zero & size, warmGlow);
    }

    if (mode.kind == _BackgroundKind.night) {
      final starPaint = Paint()..color = const Color(0x55FFFFFF);
      for (var i = 0; i < 14; i++) {
        final x = (size.width / 14) * i + math.sin(t * 0.2 + i) * 6;
        final y =
            (size.height / 7) * ((i % 5) + 1) - math.cos(t * 0.25 + i) * 4;
        canvas.drawCircle(Offset(x, y), i.isEven ? 1.6 : 1.2, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.mode != mode;
  }

  void _paintSpaceMode(Canvas canvas, Size size, double t) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF04070F), Color(0xFF090F1E), Color(0xFF050811)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final nebulaA = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.6),
        radius: 1.2,
        colors: [const Color(0xFF6A7DFF).withValues(alpha: 0.12), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, nebulaA);

    final nebulaB = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.75, 0.15),
        radius: 1.0,
        colors: [const Color(0xFF4EC3D6).withValues(alpha: 0.1), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, nebulaB);

    final moonCenter = Offset(
      size.width * 0.76 + math.sin(t * 0.08) * 12,
      size.height * 0.27 + math.cos(t * 0.07) * 8,
    );
    final moonRadius = math.min(size.width, size.height) * 0.24;

    final moonAura = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFB6C6E3).withValues(alpha: 0.24),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: moonCenter, radius: moonRadius * 2.6),
          );
    canvas.drawCircle(moonCenter, moonRadius * 2.6, moonAura);

    final moonPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.35),
        radius: 1.0,
        colors: const [Color(0xFFE8EEF8), Color(0xFFB6C0D3), Color(0xFF8B95AD)],
      ).createShader(Rect.fromCircle(center: moonCenter, radius: moonRadius));
    canvas.drawCircle(moonCenter, moonRadius, moonPaint);

    final craterPaint = Paint()
      ..color = const Color(0xFF7A839B).withValues(alpha: 0.28);
    final craterHighlight = Paint()..color = Colors.white.withValues(alpha: 0.08);
    final craters = <Offset>[
      const Offset(-0.34, -0.18),
      const Offset(0.08, -0.26),
      const Offset(0.26, 0.04),
      const Offset(-0.12, 0.18),
      const Offset(0.18, 0.28),
    ];
    final craterSizes = <double>[0.12, 0.08, 0.1, 0.09, 0.07];
    for (var i = 0; i < craters.length; i++) {
      final c = Offset(
        moonCenter.dx + craters[i].dx * moonRadius,
        moonCenter.dy + craters[i].dy * moonRadius,
      );
      canvas.drawCircle(c, moonRadius * craterSizes[i], craterPaint);
      canvas.drawCircle(
        Offset(c.dx - moonRadius * 0.015, c.dy - moonRadius * 0.015),
        moonRadius * craterSizes[i] * 0.6,
        craterHighlight,
      );
    }

    final starPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 90; i++) {
      final seed = i * 13.0;
      final x = (seed * 47.3) % size.width;
      final y = (seed * 29.7) % size.height;
      final twinkle = 0.25 + 0.75 * ((math.sin(t * 0.45 + i) + 1) * 0.5);
      starPaint.color = Colors.white.withValues(alpha: 0.08 + twinkle * 0.55);
      final r = (i % 9 == 0) ? 1.5 : 0.8;
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }

    final driftingDust = Paint()
      ..color = const Color(0xFFD2DEFF).withValues(alpha: 0.15);
    for (var i = 0; i < 26; i++) {
      final x =
          ((i * 71) + progress * 52 + math.sin(t * 0.16 + i) * 12) %
              (size.width + 40) -
          20;
      final y =
          ((i * 57) + progress * 34 + math.cos(t * 0.14 + i) * 10) %
              (size.height + 30) -
          15;
      canvas.drawCircle(Offset(x, y), i.isEven ? 0.9 : 0.6, driftingDust);
    }
  }
}

/// كرت رئيسي في الهوم
class _HomeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ImageProvider? backgroundImage;
  final VoidCallback onTap;

  const _HomeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.backgroundImage,
    required this.onTap,
  });

  @override
  State<_HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<_HomeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = Colors.blue;
    final borderRadius = BorderRadius.circular(24);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        scale: _isHovered ? 1.035 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: _isHovered ? 0.42 : 0.2),
              width: _isHovered ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.32 : 0.2),
                blurRadius: _isHovered ? 20 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _isHovered ? 8 : 6,
                sigmaY: _isHovered ? 8 : 6,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: borderRadius,
                  onTap: widget.onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: _isHovered ? 0.18 : 0.12),
                      gradient: widget.backgroundImage == null
                          ? LinearGradient(
                              colors: [
                                baseColor.withValues(alpha: _isHovered ? 0.28 : 0.2),
                                baseColor.withValues(alpha: _isHovered ? 0.18 : 0.12),
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            )
                          : null,
                      image: widget.backgroundImage != null
                          ? DecorationImage(
                              image: widget.backgroundImage!,
                              fit: BoxFit.cover,
                              opacity: _isHovered ? 0.46 : 0.32,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: 
                                  _isHovered ? 0.25 : 0.35,
                                ),
                                BlendMode.darken,
                              ),
                            )
                          : null,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 26),
                        const Spacer(),
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

