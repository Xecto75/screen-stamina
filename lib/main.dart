import 'dart:async';
import 'package:flutter/material.dart';
import 'theme/colors.dart';
import 'screens/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

enum StaminaZone { high, mid, low }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(textTheme: GoogleFonts.fugazOneTextTheme()),
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  // ================= TIMER VALUES =================
  double maxSeconds = 7200; // 2h
  double regenSeconds = 1800; // 30m
  double currentSeconds = 7200;

  bool isActive = false;

  StaminaZone _currentZone = StaminaZone.high;

  bool _zeroTriggered = false;
  bool _flashWhite = false;

  Timer? loop;
  final double fps = 30;
  DateTime lastUpdate = DateTime.now();

  // ================= LIFECYCLE =================
  Future<void> _triggerZeroFeedback() async {
    HapticFeedback.heavyImpact();

    for (int i = 0; i < 3; i++) {
      setState(() => _flashWhite = true);
      await Future.delayed(const Duration(milliseconds: 100));

      setState(() => _flashWhite = false);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLoop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    loop?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyBackgroundDelta();
    }
    lastUpdate = DateTime.now();
  }

  void _checkHapticThreshold() {
    final p = progress;
    StaminaZone newZone;

    if (p >= 0.6666) {
      newZone = StaminaZone.high;
    } else if (p >= 0.3333) {
      newZone = StaminaZone.mid;
    } else {
      newZone = StaminaZone.low;
    }

    if (newZone != _currentZone) {
      HapticFeedback.mediumImpact();
      _currentZone = newZone;
    }
  }

  // ================= TIMER LOGIC =================
  void _applyBackgroundDelta() {
    final now = DateTime.now();
    final elapsed = now.difference(lastUpdate).inSeconds.toDouble();
    if (elapsed <= 0) return;

    if (isActive) {
      currentSeconds -= elapsed;
    } else {
      currentSeconds += (maxSeconds / regenSeconds) * elapsed;
    }

    currentSeconds = currentSeconds.clamp(0, maxSeconds);
    setState(() {});
  }

  void _startLoop() {
    loop = Timer.periodic(Duration(milliseconds: (1000 ~/ fps)), (_) {
      final now = DateTime.now();
      final elapsed = now.difference(lastUpdate).inSeconds.toDouble();
      final dt = 1 / fps;

      if (elapsed >= 2) {
        _applyBackgroundDelta();
        lastUpdate = now;
        return;
      }

      if (isActive) {
        currentSeconds -= dt;
      } else {
        currentSeconds += (maxSeconds / regenSeconds) * dt;
      }

      currentSeconds = currentSeconds.clamp(0, maxSeconds);
      if (currentSeconds <= 0 && !_zeroTriggered) {
        _zeroTriggered = true;
        _triggerZeroFeedback();
      }

      if (currentSeconds > 0) {
        _zeroTriggered = false;
      }

      lastUpdate = now;
      _checkHapticThreshold();

      setState(() {});
    });
  }

  // ================= HELPERS =================
  double get progress => currentSeconds / maxSeconds;

  Color get progressColor {
    if (progress >= 0.6666) return green;
    if (progress >= 0.3333) return yellow;
    return red;
  }

  Color get bodyColor => isActive ? red : blue;
  Color get headerColor => isActive ? darkRed : darkBlue;
  Color get buttonColor => isActive ? green : red;

  String format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}";
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: headerColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: bodyColor,

            appBar: AppBar(
              toolbarHeight: 80,
              backgroundColor: headerColor,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                "Screen Stamina",
                style: TextStyle(color: white, fontSize: 25),
              ),
              actions: [
                IconButton(
                  iconSize: 48,
                  padding: const EdgeInsets.all(12),
                  splashRadius: 34,
                  icon: const Icon(Icons.settings, color: white),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          maxHours: maxSeconds / 3600,
                          regenMinutes: regenSeconds / 60,
                        ),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        maxSeconds = result['maxHours'] * 3600;
                        regenSeconds = result['regenMinutes'] * 60;
                        currentSeconds = maxSeconds;
                      });
                    }
                  },
                ),
              ],
            ),

            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Spacer(),

                        Text(
                          format(Duration(seconds: currentSeconds.floor())),
                          style: const TextStyle(
                            color: white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const Spacer(),

                        // Progress bar
                        Container(
                          width: 320,
                          height: 40,
                          decoration: BoxDecoration(
                            color: barGrey,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: white, width: 3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 320 * progress,
                                decoration: BoxDecoration(
                                  color: progressColor,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Circular button
                        SizedBox(
                          width: 170,
                          height: 140,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              shape: const CircleBorder(),
                              elevation: 0,
                            ),
                            onPressed: () {
                              setState(() {
                                isActive = !isActive;
                              });
                            },
                            child: Text(
                              isActive ? "Pause" : "Resume",
                              style: const TextStyle(
                                color: white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔥 FLASH OVERLAY — NOW COVERS HEADER + BODY
          if (_flashWhite)
            Positioned.fill(
              child: IgnorePointer(child: Container(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
