import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';

class SettingsScreen extends StatefulWidget {
  final double maxHours;
  final double regenMinutes;

  const SettingsScreen({
    super.key,
    required this.maxHours,
    required this.regenMinutes,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int maxMinutes;
  late int regenMinutes;

  late TextEditingController maxHController;
  late TextEditingController maxMController;
  late TextEditingController regenHController;
  late TextEditingController regenMController;

  @override
  void initState() {
    super.initState();

    maxMinutes = (widget.maxHours * 60).round().clamp(5, 720);
    regenMinutes = widget.regenMinutes.round().clamp(5, 720);

    maxHController = TextEditingController(text: (maxMinutes ~/ 60).toString());
    maxMController = TextEditingController(
      text: (maxMinutes % 60).toString().padLeft(2, '0'),
    );

    regenHController = TextEditingController(
      text: (regenMinutes ~/ 60).toString(),
    );
    regenMController = TextEditingController(
      text: (regenMinutes % 60).toString().padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    maxHController.dispose();
    maxMController.dispose();
    regenHController.dispose();
    regenMController.dispose();
    super.dispose();
  }

  void _goBack() {
    Navigator.pop(context, {
      'maxHours': maxMinutes / 60.0,
      'regenMinutes': regenMinutes.toDouble(),
    });
  }

  // ================= INPUT WIDGETS =================

  Widget _numberBox(TextEditingController controller, VoidCallback onCommit) {
    return SizedBox(
      width: 64, // slightly wider to avoid clipping
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(color: white, fontSize: 16),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: white),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: white, width: 2),
          ),
        ),

        // ✅ keyboard "done"
        onEditingComplete: onCommit,

        // ✅ tap outside (mobile fix)
        onTapOutside: (_) {
          onCommit();
        },
      ),
    );
  }

  Widget _timeInputPair({
    required TextEditingController hController,
    required TextEditingController mController,
    required Function(int) onChanged,
  }) {
    void commit() {
      final h = int.tryParse(hController.text) ?? 0;
      final mRaw = int.tryParse(mController.text) ?? 0;
      final m = mRaw.clamp(0, 59);

      final total = (h * 60 + m).clamp(5, 720);

      hController.text = (total ~/ 60).toString();
      mController.text = (total % 60).toString().padLeft(2, '0');

      onChanged(total);
      FocusScope.of(context).unfocus();
    }

    return Row(
      children: [
        _numberBox(hController, commit),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(":", style: TextStyle(color: white, fontSize: 18)),
        ),
        _numberBox(mController, commit),
      ],
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: darkBlue,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: blue,
        appBar: AppBar(
          toolbarHeight: 80,
          backgroundColor: darkBlue,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            iconSize: 42,
            icon: const Icon(Icons.arrow_back, color: white),
            onPressed: _goBack,
          ),
          title: const Text(
            "Settings",
            style: TextStyle(color: white, fontSize: 42),
          ),
        ),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // ================= MAX TIME =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Max Time",
                        style: TextStyle(color: white, fontSize: 18),
                      ),
                      _timeInputPair(
                        hController: maxHController,
                        mController: maxMController,
                        onChanged: (v) {
                          setState(() {
                            maxMinutes = v;
                          });
                        },
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: darkBlue,
                      inactiveTrackColor: barGrey,
                      thumbColor: white,
                      overlayColor: darkBlue.withOpacity(0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      min: 0,
                      max: 24,
                      divisions: 24,
                      value: (maxMinutes / 30).round().toDouble(),
                      onChanged: (v) {
                        setState(() {
                          maxMinutes = (v.round() * 30).clamp(5, 720);
                          maxHController.text = (maxMinutes ~/ 60).toString();
                          maxMController.text = (maxMinutes % 60)
                              .toString()
                              .padLeft(2, '0');
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ================= REGEN TIME =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Regen Time",
                        style: TextStyle(color: white, fontSize: 18),
                      ),
                      _timeInputPair(
                        hController: regenHController,
                        mController: regenMController,
                        onChanged: (v) {
                          setState(() {
                            regenMinutes = v;
                          });
                        },
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: darkBlue,
                      inactiveTrackColor: barGrey,
                      thumbColor: white,
                      overlayColor: darkBlue.withOpacity(0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      min: 0,
                      max: 24,
                      divisions: 24,
                      value: (regenMinutes / 30).round().toDouble(),
                      onChanged: (v) {
                        setState(() {
                          regenMinutes = (v.round() * 30).clamp(5, 720);
                          regenHController.text = (regenMinutes ~/ 60)
                              .toString();
                          regenMController.text = (regenMinutes % 60)
                              .toString()
                              .padLeft(2, '0');
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
